# FreeFlix

Self-hosted video streaming server with a Netflix-like interface. Stream your personal video library to your Apple TV, web browser, or any device on your local network.

![FreeFlix](Graphics/intro.gif)

## Features

- Auto-discovery of video files organized by category and genre
- Native tvOS application with cinematic UI
- Web interface optimized for TV displays (1920x1080)
- HTTP range requests for efficient video streaming
- Automatic thumbnail extraction via ffmpeg
- Custom thumbnail support (PNG, JPG, WebP)
- Multi-format support: MP4, MKV, MOV, AVI, WebM, M4V

## Architecture

```
FreeFlix/
├── server/           # Node.js Express backend
├── Front/            # Vue.js web frontend (TV-optimized)
├── FreeFlixTVOS/     # Native tvOS SwiftUI application
└── Videos/           # Media library root
    └── Categories/
        ├── Films/
        │   ├── Action/
        │   ├── Comedy/
        │   └── ...
        └── Series/
            ├── Drama/
            └── ...
```

## Requirements

### Server
- Node.js 18+
- ffmpeg (for thumbnail generation)

### tvOS App
- Xcode 15+
- tvOS 17+
- Apple TV 4K

## Quick Start

### 1. Install dependencies

```bash
npm install
cd Front && npm install && cd ..
```

### 2. Add your videos

Organize your media files in the `Videos/Categories/` directory:

```
Videos/Categories/
├── Films/
│   ├── Action/
│   │   ├── Movie.mp4
│   │   └── Movie.jpg      # Optional custom thumbnail
│   └── Comedy/
│       └── Another.mkv
└── Series/
    └── SciFi/
        ├── Show.S01E01.mp4
        └── Show.S01E01.png  # Optional custom thumbnail
```

### 3. Start the server

```bash
npm start
```

Server runs at `http://localhost:3001`

### 4. Access the interface

Open `http://<your-server-ip>:3001` in a browser or configure the tvOS app.

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/categories` | Library organized by category > genre > videos |
| `GET /api/library` | Full directory tree structure |
| `GET /api/thumbnail/:path` | Video thumbnail (auto-generated or custom) |
| `GET /api/stream/:path` | Video stream with range support |

## Configuration

### Server

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3001 | Server port |

### tvOS App

The tvOS app connects to the server via the Settings screen. Default server address: `192.168.1.159:3001`

Configure in `APIService.swift` or through the app's settings.

## Building

### Web Frontend

```bash
cd Front
npm install
npm run dev      # Development server at http://localhost:5173
npm run build    # Production build to Front/dist/
```

### tvOS Application

1. Open `FreeFlixTVOS/FreeFlix/FreeFlix.xcodeproj` in Xcode
2. Select your Apple TV as the target device
3. Build and run (Cmd+R)

Dependencies (resolved via Swift Package Manager):
- [KSPlayer](https://github.com/kingslay/KSPlayer) - Video player with MKV/subtitle support
- [FFmpegKit](https://github.com/kingslay/FFmpegKit) - FFmpeg integration

## Custom Thumbnails

Place an image file with the same name as the video in the same directory:

```
Videos/Categories/Films/Action/
├── Movie.mp4
└── Movie.jpg    # or .png, .jpeg, .webp
```

If no custom thumbnail exists, the server extracts a frame from the video at 5 seconds using ffmpeg.

## Network Setup

For Apple TV access, ensure:
1. Server and Apple TV are on the same network
2. Port 3001 is accessible (firewall rules)
3. tvOS app is configured with the correct server IP

## Development

```bash
npm run server   # Start backend only
npm run dev      # Start frontend dev server
npm run build    # Build frontend for production
```

## License

MIT

