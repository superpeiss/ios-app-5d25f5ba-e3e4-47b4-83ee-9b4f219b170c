# Music Video Generator iOS App

An automatic music video generator that analyzes audio files and creates compelling visual content.

## Features

- **Audio Analysis**: Automatically analyzes tempo, energy, and emotional characteristics
- **Lyrics Transcription**: Uses Speech framework to transcribe lyrics from audio
- **Smart Video Generation**: Fetches stock footage and assembles clips based on song analysis
- **Video Editor**: Fine-tune results by swapping clips, adjusting transitions, and applying color grading
- **Export**: Save your music video to Photos or share directly

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.0+

## Setup

### 1. Generate Xcode Project

This project uses XcodeGen to generate the `.xcodeproj` file. Install XcodeGen:

```bash
brew install xcodegen
```

Then generate the project:

```bash
cd MusicVideoGenerator
xcodegen generate
```

### 2. Configure API Keys

For stock footage fetching, you need to configure a Pexels API key:

1. Get a free API key from [Pexels](https://www.pexels.com/api/)
2. Open `MusicVideoGenerator/Services/MediaFetchingService.swift`
3. Replace `YOUR_PEXELS_API_KEY` with your actual API key

### 3. Build and Run

Open the generated `MusicVideoGenerator.xcodeproj` in Xcode and build for iOS Simulator or Device.

## Project Structure

```
MusicVideoGenerator/
├── Models/              # Data models
├── Views/               # SwiftUI views
├── ViewModels/          # View models
├── Services/            # Business logic services
│   ├── AudioAnalyzerService.swift
│   ├── LyricsTranscriptionService.swift
│   ├── MediaFetchingService.swift
│   └── VideoCompositionService.swift
├── Resources/           # Assets and resources
└── Info.plist          # App configuration
```

## Permissions

The app requires the following permissions:

- **Speech Recognition**: For lyrics transcription
- **Microphone**: For audio analysis
- **Photo Library**: To save generated videos

## Architecture

- **SwiftUI**: Modern declarative UI
- **Combine**: Reactive state management
- **AVFoundation**: Audio/video processing
- **Speech**: Lyrics transcription
- **NaturalLanguage**: Theme extraction

## Usage

1. Launch the app
2. Upload an audio file (MP3, WAV, M4A)
3. Wait for analysis (tempo, energy, lyrics)
4. Review auto-generated video clips
5. Edit clips, adjust timing, and apply color grading
6. Export and share your music video

## Notes

- First run requires Speech Recognition permission
- Video generation works best with API key configured
- Without API key, app uses placeholder clips
- Export quality: 1080p @ 30fps

## License

MIT License
