# Articulate - Collaborative Drawing App

A real-time collaborative drawing application with offline support, AI-powered suggestions, and voice commands. Built with Flutter and featuring a hybrid local-remote storage architecture.

## 🎨 Features

### Core Drawing Features

- **Real-time Collaborative Drawing**: Multiple users can draw simultaneously on the same canvas
- **Offline Support**: Continue drawing even without internet connection
- **Automatic Sync**: Seamless synchronization between local and remote storage
- **Multiple Drawing Tools**: Brush, eraser, line, rectangle, and circle tools
- **Customizable Colors**: Color picker with custom color selection
- **Adjustable Stroke Width**: Slider to control brush stroke thickness
- **Undo/Redo**: Collaborative undo and redo operations
- **Clear Canvas**: Clear entire canvas with confirmation

### AI-Powered Features

- **Smart Canvas Completion**: AI analyzes your drawing and suggests enhancements
- **OpenAI Integration**: Uses GPT-4 Vision to understand and complete drawings
- **Automatic Suggestions**: AI generates additional strokes to enhance artwork
- **Style Preservation**: Maintains artistic style and technique consistency

### Voice Control

- **Voice Commands**: Control drawing tools and actions with voice
- **Speech-to-Text**: Convert voice to text for commands
- **Text-to-Speech**: Audio feedback for voice interactions
- **Permission Management**: Automatic microphone permission handling
- **Voice Help**: Built-in help system for voice commands

### Session Management

- **Session Creation**: Generate unique session IDs for collaboration
- **Session Joining**: Join existing sessions with session ID
- **User Identification**: Unique user IDs for multi-user support
- **Connection Status**: Real-time connection indicator
- **Session History**: View and manage previous sessions

### Technical Features

- **Hybrid Storage**: Local SQLite + Remote Supabase synchronization
- **Conflict Resolution**: Automatic handling of concurrent edits
- **Connectivity Monitoring**: Real-time network status detection
- **Error Recovery**: Robust error handling and recovery mechanisms
- **Performance Optimization**: Efficient rendering and data management

## 🏗️ Architecture

### Storage Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Storage │    │  Hybrid Repo    │    │ Remote Storage  │
│   (SQLite)      │◄──►│   (Orchestrator)│◄──►│   (Supabase)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow

1. **Local First**: All changes are saved locally first
2. **Bidirectional Sync**: Real-time synchronization between local and remote
3. **Conflict Resolution**: Automatic version-based conflict resolution
4. **Offline Queue**: Changes are queued when offline and synced when online

### Key Components

#### Data Layer

- **HybridCanvasRepository**: Orchestrates local and remote storage
- **DriftCanvasRepository**: Local SQLite storage using Drift ORM
- **SupabaseCanvasRepository**: Remote storage with real-time subscriptions
- **SharedPreferencesRepository**: User preferences and settings

#### Feature Modules

- **Canvas Feature**: Core drawing functionality and session management
- **Tools Feature**: Drawing tools, color picker, and stroke controls
- **Voice Feature**: Voice commands and speech recognition

#### State Management

- **BLoC Pattern**: Flutter BLoC for state management
- **CanvasCubit**: Manages canvas state and drawing operations
- **ToolsCubit**: Handles drawing tool states
- **VoiceCubit**: Manages voice recognition and TTS

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / Xcode (for mobile development)
- Supabase account (for backend)
- OpenAI API key (for AI features)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd articulate
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

Create a `.env` file in the root directory:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# OpenAI Configuration (Optional)
OPENAI_API_KEY=your_openai_api_key
OPENAI_API_URL=https://api.openai.com/v1/chat/completions
OPENAI_MODEL=gpt-4o-mini
```

### 4. Database Setup

Run the Supabase setup script in your Supabase SQL editor:

```sql
-- Copy and paste the contents of supabase_setup.sql
```

### 5. Generate Code

```bash
flutter packages pub run build_runner build
```

### 6. Run the Application

```bash
# For development
flutter run

# For production build
flutter build apk  # Android
flutter build ios  # iOS
```

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Web**: Chrome, Firefox, Safari (experimental)

## 🔧 Configuration

### Supabase Setup

1. Create a new Supabase project
2. Run the database setup script (`supabase_setup.sql`)
3. Enable real-time subscriptions for `drawing_strokes` table
4. Configure Row Level Security (RLS) policies

### OpenAI Setup (Optional)

1. Get an OpenAI API key from https://platform.openai.com
2. Add the API key to your `.env` file
3. AI features will be disabled if not configured

### Permissions

The app requires the following permissions:

- **Microphone**: For voice commands
- **Storage**: For local data persistence
- **Network**: For remote synchronization

## 🎯 Usage

### Creating a Session

1. Launch the app
2. Enter a session title (optional)
3. Tap "Create Session"
4. Share the generated session ID with collaborators

### Joining a Session

1. Launch the app
2. Enter the session ID
3. Tap "Join Session"

### Drawing Tools

- **Brush**: Freehand drawing
- **Eraser**: Remove drawn elements
- **Line**: Draw straight lines
- **Rectangle**: Draw rectangles
- **Circle**: Draw circles

### Voice Commands

- "Draw a circle" - Creates a circle
- "Change color to red" - Changes drawing color
- "Clear canvas" - Clears the entire canvas
- "Undo" - Undoes the last action
- "Redo" - Redoes the last undone action

### AI Suggestions

- Draw something on the canvas
- Tap the AI suggestion button
- AI will analyze and suggest enhancements
- Accept or reject suggestions

## 🔄 Synchronization

### Online Mode

- Real-time bidirectional sync
- Immediate conflict resolution
- Live collaboration with other users

### Offline Mode

- Local-only storage
- Changes queued for sync
- Automatic sync when connection restored

### Conflict Resolution

- Version-based conflict detection
- Automatic resolution using timestamps
- Manual conflict resolution for complex cases

## 🛠️ Development

### Project Structure

```
lib/
├── constants/          # App constants and configuration
├── data/              # Data layer and repositories
├── features/          # Feature modules
│   ├── canvas/        # Drawing canvas functionality
│   ├── tools/         # Drawing tools
│   └── voice/         # Voice commands
└── main.dart          # App entry point
```

### Key Dependencies

- **flutter_bloc**: State management
- **supabase_flutter**: Backend integration
- **drift**: Local database ORM
- **speech_to_text**: Voice recognition
- **flutter_tts**: Text-to-speech
- **lottie**: Animations

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🐛 Troubleshooting

### Common Issues

**Supabase Connection Failed**

- Verify your Supabase URL and API key
- Check network connectivity
- Ensure Supabase project is active

**Voice Commands Not Working**

- Grant microphone permissions
- Check device microphone settings
- Restart the app after permission changes

**Sync Issues**

- Check internet connection
- Verify Supabase real-time subscriptions
- Clear app data and restart

**AI Features Not Working**

- Verify OpenAI API key configuration
- Check API usage limits
- Ensure proper image capture permissions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For support and questions:

- Create an issue on GitHub
- Check the troubleshooting section
- Review the documentation

---

**Articulate** - Where collaboration meets creativity through real-time drawing and AI-powered enhancements.
