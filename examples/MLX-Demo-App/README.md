# MLX Cache Demo App

A demonstration application showcasing **Explicit Cache Management (ECM)** for Large Language Models using Apple's MLX framework.

## Overview

This demo app demonstrates how ECM enables efficient content reuse in LLM conversations through user-controlled caching directives. Users can cache large documents and reference them across multiple queries, eliminating redundant computation.

## Features

- ✅ **Live ECM Demonstration**: Working cache operations with real MLX models
- ✅ **Interactive UI**: SwiftUI interface with cache status visualization
- ✅ **Example Workflows**: Pre-built scenarios for document analysis
- ✅ **Real-time Cache Monitoring**: Live view of active caches and token counts
- ✅ **Mobile Optimized**: Keyboard handling and responsive design
- ✅ **Multiple Model Support**: Fallback across different model sizes

## Screenshots

[Add screenshots of the app in action]

## Requirements

- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+
- Apple Silicon Mac (for MLX models)
- 8GB+ RAM recommended

## Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/[username]/llm-explicit-cache-management.git
cd llm-explicit-cache-management/Examples/MLX-Demo-App
```

### 2. Open in Xcode
```bash
open MLXCacheDemo.xcodeproj
```

### 3. Add ECM Framework Dependency
The project is configured to use the ECMFramework as a local Swift package dependency.

If you need to reconfigure:
1. File → Add Package Dependencies
2. Add Local → Select `../../ECMFramework`
3. Add to target

### 4. Build and Run
- Select your target device (iOS Simulator or Mac)
- Press ⌘+R to build and run

## Usage

### Basic Workflow

1. **Launch the app** - MLX model will load automatically
2. **Cache content** using example buttons or custom directives
3. **Ask questions** referencing cached content
4. **Monitor cache status** in the green cache display area

### Example Scenarios

#### 📄 Document Analysis
```
1. Tap "📄 Cache Document" 
   → Caches: [System Cache: legal_doc] This comprehensive legal agreement...

2. Tap "❓ Ask Question"
   → Query: Based on cache reference: legal_doc, what is the contract duration?
   → Response: The contract duration is 3 years.
```

#### 🔄 Multiple Caches
```
1. Cache multiple documents with different IDs
2. Reference specific caches in your questions
3. Clean individual caches or clear all
```

### Cache Directives Reference

#### Cache Storage
```
[System Cache: {id}] {content}
```
Example: `[System Cache: legal_doc] This agreement covers...`

#### Cache Reference
```
Based on cache reference: {id}, {question}
```
Example: `Based on cache reference: legal_doc, what is the termination clause?`

#### Cache Management
```
[System Clean Cache: {id}]    // Remove specific cache
[System Clean Cache]          // Remove all caches
```

## App Architecture

### Key Components

#### MLXCacheService
- Manages MLX model loading and inference
- Integrates with ECMFramework for cache operations
- Handles generation parameters and error cases

#### ContentView
- Main SwiftUI interface
- Keyboard handling and responsive design
- Example buttons and input management

#### ECMCacheStatusView
- Real-time cache monitoring
- Token count display
- Cache management controls

### Model Loading Strategy

The app tries multiple models in order of preference:
1. `mlx-community/Qwen2.5-0.5B-Instruct-4bit` (fastest)
2. `mlx-community/SmolLM2-360M-Instruct-4bit` (fallback)
3. `mlx-community/Llama-3.2-1B-Instruct-4bit` (fallback)

This ensures the app works across different model availability scenarios.

## Performance Monitoring

The app includes built-in performance monitoring:

- **Memory Usage**: Real-time GPU cache memory display
- **Token Counts**: Shows tokens saved through caching
- **Response Times**: Observable generation speed
- **Cache Efficiency**: Visual feedback on cache hits

## Troubleshooting

### Model Loading Issues
- Ensure you have sufficient RAM (8GB+ recommended)
- Check internet connection for model downloads
- Try restarting the app if models fail to load

### Cache Not Working
- Verify directive syntax matches examples
- Check cache status display for active caches
- Use "Clear All" button to reset if needed

### Performance Issues  
- Close other memory-intensive apps
- Use smaller models (0.5B parameter versions)
- Clear old caches regularly

### UI Issues
- Restart app if keyboard doesn't dismiss
- Check for iOS/macOS version compatibility
- Report issues on GitHub

## Development

### Project Structure
```
MLXCacheDemo/
├── MLXCacheDemo.xcodeproj
├── MLXCacheDemo/
│   ├── ContentView.swift           # Main UI
│   ├── MLXCacheService.swift       # MLX integration (if separate)
│   ├── MLXCacheDemoApp.swift      # App entry point
│   └── Info.plist
└── README.md
```

### Adding New Features

#### New Cache Directives
1. Extend `CacheDirective.Operation` in ECMFramework
2. Update parser patterns
3. Add UI examples in demo app

#### New Models
1. Add model configuration to `modelConfigs` array
2. Test memory requirements
3. Update fallback logic if needed

#### UI Improvements
1. Follow existing SwiftUI patterns
2. Maintain keyboard handling
3. Test on both iOS and macOS

### Testing

#### Manual Testing Scenarios
- [ ] Model loads successfully
- [ ] Cache operations work correctly
- [ ] Cache references generate proper responses
- [ ] UI responds correctly to keyboard
- [ ] Memory usage stays reasonable
- [ ] Error messages are helpful

#### Performance Testing
- [ ] Response times with/without cache
- [ ] Memory usage under load
- [ ] Large document handling
- [ ] Multiple cache scenarios

## Contributing

This demo app serves as a reference implementation for ECMFramework integration. Contributions welcome:

1. **Bug Fixes**: UI issues, memory leaks, crashes
2. **Features**: New example scenarios, better visualizations
3. **Models**: Support for additional MLX models
4. **Platforms**: iPad-specific optimizations

## Known Limitations

- **Model Size**: Limited by device memory
- **Cache Persistence**: Caches cleared on app restart
- **Concurrent Requests**: Single request at a time
- **Model Selection**: Automatic fallback only

## Future Enhancements

- [ ] Cache persistence across app launches
- [ ] Custom model selection UI
- [ ] Performance benchmarking tools
- [ ] Batch processing capabilities
- [ ] Export/import cache functionality

## License

[Your chosen license]

## Support

- 📖 **Framework Docs**: See ECMFramework README
- 🐛 **Report Issues**: GitHub Issues
- 💬 **Discussions**: GitHub Discussions
- 📧 **Contact**: [Your contact information]