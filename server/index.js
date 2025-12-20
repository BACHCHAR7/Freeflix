import express from 'express';
import cors from 'cors';
import { createReadStream, statSync, readdirSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, extname, basename, dirname as pathDirname } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { execSync, spawn } from 'child_process';
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
const CHUNK_SIZE = 25 * 1024 * 1024; // 25MB chunks for large files
const HIGH_WATER_MARK = 1024 * 1024; // 1MB buffer

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

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Freeflix server running at http://0.0.0.0:${PORT}`);
    console.log(`Videos directory: ${VIDEOS_PATH}`);
});

