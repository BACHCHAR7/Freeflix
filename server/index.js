import express from 'express';
import cors from 'cors';
import { createReadStream, statSync, readdirSync, existsSync, mkdirSync, writeFileSync, rmSync, readFileSync } from 'fs';
import { join, extname, basename, dirname as pathDirname } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { execSync, spawn } from 'child_process';
import { createHash } from 'crypto';
import mime from 'mime-types';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;
const VIDEOS_PATH = join(__dirname, '..', 'Videos', 'Categories');
const THUMBNAILS_CACHE = join(__dirname, '..', '.thumbnails');

app.use(cors());
app.use(express.json());

const VIDEO_EXTENSIONS = ['.mp4', '.mov', '.mkv', '.avi', '.webm', '.m4v'];
const BROWSER_NATIVE_FORMATS = ['.mp4', '.webm', '.m4v'];

const activeTranscodes = new Map();

function getVideoInfo(videoPath) {
    try {
        const result = execSync(
            `ffprobe -v quiet -print_format json -show_format -show_streams "${videoPath}"`,
            { encoding: 'utf8', timeout: 10000 }
        );
        return JSON.parse(result);
    } catch {
        return null;
    }
}

function needsTranscoding(videoPath) {
    const ext = extname(videoPath).toLowerCase();
    if (BROWSER_NATIVE_FORMATS.includes(ext)) {
        const info = getVideoInfo(videoPath);
        if (!info) return true;
        const videoStream = info.streams?.find(s => s.codec_type === 'video');
        const audioStream = info.streams?.find(s => s.codec_type === 'audio');
        const videoCodec = videoStream?.codec_name;
        const audioCodec = audioStream?.codec_name;
        const compatibleVideo = ['h264', 'vp8', 'vp9', 'av1'].includes(videoCodec);
        const compatibleAudio = ['aac', 'mp3', 'opus', 'vorbis'].includes(audioCodec) || !audioStream;
        return !(compatibleVideo && compatibleAudio);
    }
    return true;
}

function scanDirectory(dirPath, relativePath = '') {
    const items = [];

    if (!existsSync(dirPath)) return items;

    const entries = readdirSync(dirPath, { withFileTypes: true });

    for (const entry of entries) {
        if (entry.name.startsWith('.')) continue;

        const fullPath = join(dirPath, entry.name);
        const itemRelativePath = relativePath ? `${relativePath}/${entry.name}` : entry.name;

        if (entry.isDirectory()) {
            items.push({
                type: 'category',
                name: entry.name,
                path: itemRelativePath,
                children: scanDirectory(fullPath, itemRelativePath)
            });
        } else if (VIDEO_EXTENSIONS.includes(extname(entry.name).toLowerCase())) {
            const stats = statSync(fullPath);
            items.push({
                type: 'video',
                name: basename(entry.name, extname(entry.name)),
                filename: entry.name,
                path: itemRelativePath,
                size: stats.size,
                modified: stats.mtime
            });
        }
    }

    return items;
}

function buildLibrary(items) {
    const library = [];

    for (const category of items) {
        if (category.type !== 'category') continue;

        const categoryData = {
            name: category.name,
            path: category.path,
            genres: []
        };

        for (const genre of category.children) {
            if (genre.type === 'category') {
                const videos = collectVideos(genre.children);
                if (videos.length > 0) {
                    categoryData.genres.push({
                        name: genre.name,
                        path: genre.path,
                        videos: videos
                    });
                }
            } else if (genre.type === 'video') {
                let uncategorized = categoryData.genres.find(g => g.name === 'Autres');
                if (!uncategorized) {
                    uncategorized = { name: 'Autres', path: category.path, videos: [] };
                    categoryData.genres.push(uncategorized);
                }
                uncategorized.videos.push(genre);
            }
        }

        if (categoryData.genres.length > 0) {
            library.push(categoryData);
        }
    }

    return library;
}

function collectVideos(items) {
    const videos = [];
    for (const item of items) {
        if (item.type === 'video') {
            videos.push(item);
        } else if (item.type === 'category') {
            videos.push(...collectVideos(item.children));
        }
    }
    return videos;
}

// API: Get library organized by category > genre > videos
app.get('/api/categories', (req, res) => {
    const structure = scanDirectory(VIDEOS_PATH);
    const library = buildLibrary(structure);
    res.json(library);
});

// API: Get full library structure
app.get('/api/library', (req, res) => {
    const structure = scanDirectory(VIDEOS_PATH);
    res.json(structure);
});

// Thumbnail endpoint - custom image or extracted from video
app.get('/api/thumbnail/:videoPath(*)', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);
    const videoDir = pathDirname(videoPath);
    const videoName = basename(videoPath, extname(videoPath));

    const customPng = join(videoDir, `${videoName}.png`);
    const customJpg = join(videoDir, `${videoName}.jpg`);
    const customJpeg = join(videoDir, `${videoName}.jpeg`);
    const customWebp = join(videoDir, `${videoName}.webp`);

    if (existsSync(customPng)) {
        return res.sendFile(customPng);
    }
    if (existsSync(customJpg)) {
        return res.sendFile(customJpg);
    }
    if (existsSync(customJpeg)) {
        return res.sendFile(customJpeg);
    }
    if (existsSync(customWebp)) {
        return res.sendFile(customWebp);
    }

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    if (!existsSync(THUMBNAILS_CACHE)) {
        mkdirSync(THUMBNAILS_CACHE, { recursive: true });
    }

    const cacheKey = req.params.videoPath.replace(/[\/\\]/g, '_').replace(/\.[^.]+$/, '.jpg');
    const cachedPath = join(THUMBNAILS_CACHE, cacheKey);

    if (existsSync(cachedPath)) {
        return res.sendFile(cachedPath);
    }

    try {
        execSync(`ffmpeg -i "${videoPath}" -ss 00:00:05 -vframes 1 -vf "scale=480:-1" -y "${cachedPath}" 2>/dev/null`, {
            timeout: 30000
        });

        if (existsSync(cachedPath)) {
            return res.sendFile(cachedPath);
        }
    } catch (err) {
        try {
            execSync(`ffmpeg -i "${videoPath}" -ss 00:00:01 -vframes 1 -vf "scale=480:-1" -y "${cachedPath}" 2>/dev/null`, {
                timeout: 30000
            });
            if (existsSync(cachedPath)) {
                return res.sendFile(cachedPath);
            }
        } catch (e) {
            // ffmpeg failed
        }
    }

    res.status(404).json({ error: 'Could not generate thumbnail' });
});

// Video streaming with range support and optimized chunking for large files
const CHUNK_SIZE = 25 * 1024 * 1024;
const HIGH_WATER_MARK = 1024 * 1024;

// Transcoding endpoint - converts any format to browser-compatible stream
app.get('/api/transcode/:videoPath(*)', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const startTime = parseFloat(req.query.start) || 0;
    const quality = req.query.quality || 'high';
    const clientId = `${req.ip}-${Date.now()}`;

    const info = getVideoInfo(videoPath);
    const videoStream = info?.streams?.find(s => s.codec_type === 'video');
    const audioStream = info?.streams?.find(s => s.codec_type === 'audio');
    const sourceCodec = videoStream?.codec_name;
    const audioCodec = audioStream?.codec_name;

    const canCopyVideo = ['h264'].includes(sourceCodec);
    const canCopyAudio = ['aac', 'mp3'].includes(audioCodec);

    const qualityPresets = {
        low: { crf: 28, maxrate: '1500k', bufsize: '3000k', scale: 480 },
        medium: { crf: 24, maxrate: '4000k', bufsize: '8000k', scale: 720 },
        high: { crf: 22, maxrate: '8000k', bufsize: '16000k', scale: -2 },
        original: { crf: 20, maxrate: '12000k', bufsize: '24000k', scale: -2 }
    };

    const preset = qualityPresets[quality] || qualityPresets.high;

    const scaleFilter = preset.scale > 0
        ? `scale=-2:${preset.scale}`
        : null;

    let ffmpegArgs = [
        '-hide_banner',
        '-loglevel', 'error',
        '-ss', startTime.toString(),
        '-i', videoPath,
        '-map', '0:v:0',
        '-map', '0:a:0?'
    ];

    if (canCopyVideo && !scaleFilter) {
        ffmpegArgs.push('-c:v', 'copy');
    } else {
        ffmpegArgs.push(
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-tune', 'zerolatency',
            '-crf', preset.crf.toString(),
            '-maxrate', preset.maxrate,
            '-bufsize', preset.bufsize,
            '-profile:v', 'baseline',
            '-level', '4.0',
            '-g', '30',
            '-keyint_min', '30',
            '-sc_threshold', '0',
            '-threads', '0',
            '-pix_fmt', 'yuv420p'
        );
        if (scaleFilter) {
            ffmpegArgs.push('-vf', scaleFilter);
        }
    }

    if (canCopyAudio) {
        ffmpegArgs.push('-c:a', 'copy');
    } else {
        ffmpegArgs.push(
            '-c:a', 'aac',
            '-b:a', '128k',
            '-ac', '2',
            '-ar', '44100'
        );
    }

    ffmpegArgs.push(
        '-movflags', 'frag_keyframe+empty_moov+default_base_moof',
        '-frag_duration', '1000000',
        '-f', 'mp4',
        'pipe:1'
    );

    res.setHeader('Content-Type', 'video/mp4');
    res.setHeader('Cache-Control', 'no-cache, no-store');
    res.setHeader('Transfer-Encoding', 'chunked');
    res.setHeader('X-Content-Type-Options', 'nosniff');

    const ffmpeg = spawn('ffmpeg', ffmpegArgs, {
        stdio: ['ignore', 'pipe', 'pipe']
    });
    activeTranscodes.set(clientId, ffmpeg);

    ffmpeg.stdout.pipe(res);

    ffmpeg.stderr.on('data', (data) => {
        console.error('ffmpeg:', data.toString().trim());
    });

    ffmpeg.on('error', (err) => {
        console.error('ffmpeg spawn error:', err);
        activeTranscodes.delete(clientId);
        if (!res.headersSent) {
            res.status(500).end();
        }
    });

    ffmpeg.on('close', (code) => {
        activeTranscodes.delete(clientId);
    });

    res.on('close', () => {
        if (!ffmpeg.killed) {
            ffmpeg.kill('SIGKILL');
        }
        activeTranscodes.delete(clientId);
    });
});

// HLS streaming with cached segments for smooth playback

const HLS_CACHE = join(__dirname, '..', '.hls');
const hlsSessions = new Map();
const HLS_SEGMENT_DURATION = 6;
const HLS_CLEANUP_DELAY = 600000;

function getHlsSessionKey(videoPath, quality) {
    return createHash('md5').update(videoPath + quality).digest('hex').slice(0, 12);
}

function startHlsSession(videoPath, quality) {
    const sessionKey = getHlsSessionKey(videoPath, quality);
    const sessionDir = join(HLS_CACHE, sessionKey);

    if (hlsSessions.has(sessionKey)) {
        const session = hlsSessions.get(sessionKey);
        clearTimeout(session.cleanupTimer);
        session.cleanupTimer = setTimeout(() => cleanupHlsSession(sessionKey), HLS_CLEANUP_DELAY);
        return { sessionKey, sessionDir, existing: true };
    }

    if (!existsSync(HLS_CACHE)) mkdirSync(HLS_CACHE, { recursive: true });
    if (!existsSync(sessionDir)) mkdirSync(sessionDir, { recursive: true });

    const qualityPresets = {
        low: { crf: 26, maxrate: '1200k', bufsize: '2400k', scale: 360 },
        medium: { crf: 24, maxrate: '3000k', bufsize: '6000k', scale: 480 },
        high: { crf: 22, maxrate: '6000k', bufsize: '12000k', scale: 720 },
        original: { crf: 20, maxrate: '12000k', bufsize: '24000k', scale: -2 }
    };

    const preset = qualityPresets[quality] || qualityPresets.high;
    const playlistPath = join(sessionDir, 'stream.m3u8');
    const scaleFilter = preset.scale > 0 ? `scale=-2:${preset.scale}` : null;

    let ffmpegArgs = [
        '-hide_banner',
        '-loglevel', 'warning',
        '-i', videoPath,
        '-map', '0:v:0',
        '-map', '0:a:0?',
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', preset.crf.toString(),
        '-maxrate', preset.maxrate,
        '-bufsize', preset.bufsize,
        '-profile:v', 'main',
        '-level', '4.0',
        '-g', String(HLS_SEGMENT_DURATION * 30),
        '-keyint_min', String(HLS_SEGMENT_DURATION * 30),
        '-sc_threshold', '0',
        '-threads', '0',
        '-pix_fmt', 'yuv420p'
    ];

    if (scaleFilter) ffmpegArgs.push('-vf', scaleFilter);

    ffmpegArgs.push(
        '-c:a', 'aac',
        '-b:a', '128k',
        '-ac', '2',
        '-ar', '48000',
        '-f', 'hls',
        '-hls_time', HLS_SEGMENT_DURATION.toString(),
        '-hls_list_size', '0',
        '-hls_segment_type', 'mpegts',
        '-hls_flags', 'independent_segments',
        '-hls_segment_filename', join(sessionDir, 'seg%04d.ts'),
        '-start_number', '0',
        playlistPath
    );

    const ffmpeg = spawn('ffmpeg', ffmpegArgs, { stdio: ['ignore', 'pipe', 'pipe'] });

    const session = {
        ffmpeg,
        sessionDir,
        playlistPath,
        quality,
        segmentsReady: 0,
        cleanupTimer: setTimeout(() => cleanupHlsSession(sessionKey), HLS_CLEANUP_DELAY)
    };

    hlsSessions.set(sessionKey, session);
    activeTranscodes.set(`hls-${sessionKey}`, ffmpeg);

    ffmpeg.stderr.on('data', (data) => {
        const msg = data.toString();
        if (msg.includes('Opening') && msg.includes('.ts')) {
            session.segmentsReady++;
        }
    });

    ffmpeg.on('close', () => {
        activeTranscodes.delete(`hls-${sessionKey}`);
        if (hlsSessions.has(sessionKey)) {
            hlsSessions.get(sessionKey).complete = true;
        }
    });

    return { sessionKey, sessionDir, existing: false };
}

function cleanupHlsSession(sessionKey) {
    const session = hlsSessions.get(sessionKey);
    if (!session) return;

    if (session.ffmpeg && !session.ffmpeg.killed) {
        session.ffmpeg.kill('SIGTERM');
    }
    try { rmSync(session.sessionDir, { recursive: true, force: true }); } catch {}
    activeTranscodes.delete(`hls-${sessionKey}`);
    hlsSessions.delete(sessionKey);
}

app.get('/api/hls/:videoPath(*)/master.m3u8', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const info = getVideoInfo(videoPath);
    const videoStream = info?.streams?.find(s => s.codec_type === 'video');
    const height = videoStream?.height || 1080;
    const width = videoStream?.width || 1920;

    const baseUrl = `/api/hls/${req.params.videoPath}`;
    
    let playlist = '#EXTM3U\n#EXT-X-VERSION:3\n';
    
    if (height >= 1080) {
        playlist += `#EXT-X-STREAM-INF:BANDWIDTH=12000000,RESOLUTION=${width}x${height}\n`;
        playlist += `${baseUrl}/index.m3u8?quality=original\n`;
    }
    if (height >= 720) {
        playlist += '#EXT-X-STREAM-INF:BANDWIDTH=6000000,RESOLUTION=1280x720\n';
        playlist += `${baseUrl}/index.m3u8?quality=high\n`;
    }
    playlist += '#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=854x480\n';
    playlist += `${baseUrl}/index.m3u8?quality=medium\n`;
    playlist += '#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=640x360\n';
    playlist += `${baseUrl}/index.m3u8?quality=low\n`;

    res.setHeader('Content-Type', 'application/vnd.apple.mpegurl');
    res.setHeader('Cache-Control', 'no-cache');
    res.send(playlist);
});

app.get('/api/hls/:videoPath(*)/index.m3u8', async (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);
    const quality = req.query.quality || 'high';

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const { sessionKey, sessionDir } = startHlsSession(videoPath, quality);
    const playlistPath = join(sessionDir, 'stream.m3u8');

    const maxWait = 15000;
    const start = Date.now();
    
    while (Date.now() - start < maxWait) {
        if (existsSync(playlistPath)) {
            let content = readFileSync(playlistPath, 'utf8');
            if (content.includes('#EXTINF')) {
                content = content.replace(/seg(\d+)\.ts/g, 
                    `/api/hls/${req.params.videoPath}/seg/$1.ts?quality=${quality}`);
                
                res.setHeader('Content-Type', 'application/vnd.apple.mpegurl');
                res.setHeader('Cache-Control', 'no-cache');
                return res.send(content);
            }
        }
        await new Promise(r => setTimeout(r, 250));
    }

    res.status(503).json({ error: 'Transcoding starting, please retry' });
});

app.get('/api/hls/:videoPath(*)/seg/:segNum.ts', (req, res) => {
    const quality = req.query.quality || 'high';
    const segNum = req.params.segNum.padStart(4, '0');
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const sessionKey = getHlsSessionKey(videoPath, quality);
    const session = hlsSessions.get(sessionKey);
    
    if (session) {
        clearTimeout(session.cleanupTimer);
        session.cleanupTimer = setTimeout(() => cleanupHlsSession(sessionKey), HLS_CLEANUP_DELAY);
    }

    const sessionDir = join(HLS_CACHE, sessionKey);
    const segmentPath = join(sessionDir, `seg${segNum}.ts`);

    const maxWait = 30000;
    const start = Date.now();

    const waitAndSend = () => {
        if (existsSync(segmentPath)) {
            const stats = statSync(segmentPath);
            if (stats.size > 1000) {
                res.setHeader('Content-Type', 'video/mp2t');
                res.setHeader('Cache-Control', 'public, max-age=86400');
                return res.sendFile(segmentPath);
            }
        }
        if (Date.now() - start > maxWait) {
            return res.status(503).json({ error: 'Segment not ready' });
        }
        setTimeout(waitAndSend, 150);
    };

    waitAndSend();
});

// Video info endpoint - returns metadata and transcoding requirements
app.get('/api/info/:videoPath(*)', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const info = getVideoInfo(videoPath);
    if (!info) {
        return res.status(500).json({ error: 'Could not read video info' });
    }

    const videoStream = info.streams?.find(s => s.codec_type === 'video');
    const audioStream = info.streams?.find(s => s.codec_type === 'audio');
    const requiresTranscode = needsTranscoding(videoPath);

    const parseFps = (rateStr) => {
        if (!rateStr) return 0;
        const parts = rateStr.split('/');
        if (parts.length === 2) {
            const num = parseFloat(parts[0]);
            const den = parseFloat(parts[1]);
            return den > 0 ? num / den : 0;
        }
        return parseFloat(rateStr) || 0;
    };

    res.json({
        duration: parseFloat(info.format?.duration) || 0,
        size: parseInt(info.format?.size) || 0,
        bitrate: parseInt(info.format?.bit_rate) || 0,
        video: videoStream ? {
            codec: videoStream.codec_name,
            width: videoStream.width,
            height: videoStream.height,
            fps: parseFps(videoStream.r_frame_rate)
        } : null,
        audio: audioStream ? {
            codec: audioStream.codec_name,
            channels: audioStream.channels,
            sampleRate: audioStream.sample_rate
        } : null,
        requiresTranscode,
        streamUrl: requiresTranscode 
            ? `/api/transcode/${req.params.videoPath}`
            : `/api/stream/${req.params.videoPath}`
    });
});

// Smart stream endpoint - auto-selects between direct and transcoded stream
app.get('/api/play/:videoPath(*)', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    if (needsTranscoding(videoPath)) {
        const transcodeUrl = `/api/transcode/${req.params.videoPath}`;
        const query = new URLSearchParams(req.query).toString();
        return res.redirect(307, query ? `${transcodeUrl}?${query}` : transcodeUrl);
    }

    const stat = statSync(videoPath);
    const fileSize = stat.size;
    const mimeType = mime.lookup(videoPath) || 'video/mp4';
    const range = req.headers.range;

    res.setHeader('Accept-Ranges', 'bytes');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.setHeader('Content-Type', mimeType);

    if (range) {
        const parts = range.replace(/bytes=/, '').split('-');
        const start = parseInt(parts[0], 10);
        const requestedEnd = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
        const end = Math.min(requestedEnd, Math.min(start + CHUNK_SIZE - 1, fileSize - 1));
        const chunkSize = end - start + 1;

        res.status(206);
        res.setHeader('Content-Range', `bytes ${start}-${end}/${fileSize}`);
        res.setHeader('Content-Length', chunkSize);

        createReadStream(videoPath, { start, end, highWaterMark: HIGH_WATER_MARK }).pipe(res);
    } else {
        res.setHeader('Content-Length', fileSize);
        createReadStream(videoPath, { highWaterMark: HIGH_WATER_MARK }).pipe(res);
    }
});

// Direct stream endpoint - no transcoding, original file
app.get('/api/stream/:videoPath(*)', (req, res) => {
    const videoPath = join(VIDEOS_PATH, req.params.videoPath);

    if (!existsSync(videoPath)) {
        return res.status(404).json({ error: 'Video not found' });
    }

    const stat = statSync(videoPath);
    const fileSize = stat.size;
    const mimeType = mime.lookup(videoPath) || 'video/mp4';
    const range = req.headers.range;

    res.setHeader('Accept-Ranges', 'bytes');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Content-Type', mimeType);

    if (range) {
        const parts = range.replace(/bytes=/, '').split('-');
        const start = parseInt(parts[0], 10);
        const requestedEnd = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
        const end = Math.min(requestedEnd, Math.min(start + CHUNK_SIZE - 1, fileSize - 1));
        const chunkSize = end - start + 1;

        res.status(206);
        res.setHeader('Content-Range', `bytes ${start}-${end}/${fileSize}`);
        res.setHeader('Content-Length', chunkSize);

        const stream = createReadStream(videoPath, { 
            start, 
            end, 
            highWaterMark: HIGH_WATER_MARK 
        });

        stream.on('error', (err) => {
            console.error('Stream error:', err);
            if (!res.headersSent) {
                res.status(500).end();
            }
        });

        stream.pipe(res);
    } else {
        res.setHeader('Content-Length', fileSize);
        const stream = createReadStream(videoPath, { 
            highWaterMark: HIGH_WATER_MARK 
        });

        stream.on('error', (err) => {
            console.error('Stream error:', err);
            if (!res.headersSent) {
                res.status(500).end();
            }
        });

        stream.pipe(res);
    }
});

// Active transcodes status endpoint
app.get('/api/status', (req, res) => {
    res.json({
        activeTranscodes: activeTranscodes.size,
        uptime: process.uptime()
    });
});

// Serve static frontend in production
app.use(express.static(join(__dirname, '..', 'Front', 'dist')));

app.get('*', (req, res) => {
    const indexPath = join(__dirname, '..', 'Front', 'dist', 'index.html');
    if (existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.status(404).send('Frontend not built. Run: npm run build');
    }
});

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Freeflix server running at http://0.0.0.0:${PORT}`);
    console.log(`Videos directory: ${VIDEOS_PATH}`);
    console.log('Transcoding: enabled (ffmpeg required)');
});

process.on('SIGTERM', () => {
    console.log('Shutting down server...');
    for (const [id, ffmpeg] of activeTranscodes) {
        ffmpeg.kill('SIGKILL');
    }
    activeTranscodes.clear();
    server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
    console.log('Shutting down server...');
    for (const [id, ffmpeg] of activeTranscodes) {
        ffmpeg.kill('SIGKILL');
    }
    activeTranscodes.clear();
    server.close(() => process.exit(0));
});

