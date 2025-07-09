# Persona Assistant

Modern AI Personal Assistant app with OpenRouter integration for Android and iOS. Features include AI-curated content, conversational assistant, mood tracking, psychology tests, and long-term memory system.

## 📊 Current Development Status

**Status**: Frontend (95%) | Backend Integration (55%)  
**Last Updated**: July 8, 2025

### ✅ Fully Working Features
- **Flutter Frontend**: Clean Architecture with BLoC pattern fully implemented
- **Navigation**: All 5 tabs functional (Home, Chat, Growth, Psychology, Settings)
- **OpenRouter API Integration**: Working AI content generation
  - Music recommendations with mood-based AI generation
  - Article suggestions with personalized content
  - Daily quotes and journal prompts
- **Dependency Injection**: All services properly registered with GetIt
- **Local Storage**: Hive integration working with encrypted data
- **Security Services**: Secure storage, biometric auth UI implemented
- **Test Suite**: 49 tests passing (100% success rate)
- **Build Quality**: Flutter analyze clean, APK builds successfully
- **Backend API**: Core structure with auth flow and AI proxy endpoints implemented
- **Backend Chat API**: OpenRouter proxy endpoint working with conversation tracking

### 🟡 Partially Implemented Features
- **Chat System (75%)**: Full UI implementation with BLoC pattern and backend integration
- **Backend Services (55%)**: Authentication flow and AI proxy endpoints implemented
- **AI Content Parsing (80%)**: Improved JSON parsing and error handling implemented
- **Secure API Communication (60%)**: Token-based authentication with JWT implemented

### ⏳ In Progress
- **Flutter-Backend Integration**: Token handling and real API calls through backend
- **Database Synchronization**: Two-way sync between Flutter Hive and backend Prisma
- **Advanced AI Models**: Support for multiple AI models through OpenRouter

## 🎯 Development Roadmap

### Phase 1: Backend Foundation (2-3 weeks)
1. **Fix Authentication System**
   - Debug failing tests
   - Fix database connection issues
   - Implement working JWT flow

2. **Implement AI Proxy Endpoints**
   - Create OpenRouter proxy endpoints
   - Move API key to backend environment
   - Add request logging and rate limiting

3. **Flutter-Backend Integration**
   - Implement real authentication in Flutter
   - Connect all AI requests to backend
   - Add proper error handling

### Phase 2: Security & Polish (1-2 weeks)
1. **Security Hardening**
   - Remove API keys from Flutter
   - Implement proper session management
   - Add request validation

2. **Crisis Intervention Implementation**
   - Create intervention action flows
   - Add emergency contact features
   - Implement alert mechanisms

### Phase 3: Production Deployment (1-2 weeks)
1. **Infrastructure Setup**
   - CI/CD pipeline
   - Production hosting (backend)
   - App store deployment prep

## 🌟 Features

### 🏠 Home Tab
- **AI-Curated Content**: Music recommendations, articles, quotes, and journal prompts based on your mood and preferences
- **Dynamic Personalization**: Content adapts to your emotional state and time of day
- **Contextual Awareness**: Smart greetings and suggestions based on current context

### 💬 Chat Tab
- **Conversational AI**: Powered by OpenRouter API with intelligent responses
- **Personality Understanding**: AI learns and adapts to your communication style
- **Contextual Responses**: Smart suggestions based on time, mood, and conversation history
- **Crisis Detection**: Identifies concerning patterns and suggests appropriate resources

### 📈 Growth Tab
- **Mood Tracking**: Visual mood logging with trend analysis
- **Interactive Calendar**: Track activities, emotions, and daily events
- **Life Tree Visualization**: Visual representation of personal growth across different life areas
- **Progress Analytics**: Charts and insights into your personal development journey

### 🧠 Psychology Tab
- **MBTI Test**: Myers-Briggs Type Indicator assessment
- **BDI Test**: Beck Depression Inventory for mental health screening
- **Personality Profile**: Comprehensive personality analysis and insights
- **Mental Health Resources**: Crisis intervention and professional support links
- **Test Results Integration**: Psychology test results influence AI interactions

### ⚙️ Settings Tab
- **Profile Management**: Personal information and preferences
- **Privacy & Security**: Data management and privacy controls
- **API Configuration**: OpenRouter API key management
- **Little Brain Settings**: Memory and learning preferences
- **Backup & Sync**: Cloud synchronization options

### 🧠 Little Brain System
- **Long-term Memory**: Stores conversations, moods, and behavioral patterns
- **Personality Modeling**: Builds comprehensive user personality model over time
- **Adaptive Learning**: AI becomes more personalized with continued use
- **Memory Management**: Users can view and manage stored memories
- **Growth Tracking**: Monitors personal development over extended periods

## 🛠 Technical Architecture

### Clean Architecture
- **Presentation Layer**: UI components with BLoC pattern
- **Domain Layer**: Business logic and use cases
- **Data Layer**: API services and local storage

### Technology Stack
- **Framework**: Flutter 3.32.5 with Dart 3.8.1
- **AI Integration**: OpenRouter API for multiple AI model access
- **State Management**: BLoC pattern with flutter_bloc
- **UI Framework**: Material Design 3 with dynamic theming
- **Local Storage**: Hive for efficient data persistence
- **HTTP Client**: Dio with retry and caching mechanisms
- **Dependency Injection**: GetIt with injectable code generation
- **Charts**: FL Chart for data visualization
- **Code Generation**: Build Runner for model and API generation

### Project Structure
```
lib/
├── core/
│   ├── api/              # API services and clients
│   ├── constants/        # App constants and strings
│   ├── errors/          # Error handling
│   ├── injection/       # Dependency injection
│   └── utils/           # Utility functions
├── features/
│   ├── home/            # Home tab functionality
│   ├── chat/            # AI chat system
│   ├── growth/          # Mood tracking and analytics
│   ├── psychology/      # Psychology tests and profiles
│   ├── settings/        # App settings and preferences
│   └── little_brain/    # Long-term memory system
└── shared/
    ├── themes/          # App theming
    ├── widgets/         # Reusable UI components
    └── extensions/      # Dart extensions
```

## Architecture

The application follows Clean Architecture principles with a modular, feature-based structure:

### Flutter App
- **Data Layer**: Repositories, data sources, models
- **Domain Layer**: Entities, use cases, repository interfaces
- **Presentation Layer**: BLoCs, widgets, screens
- **Core**: Shared utilities, constants, services

### Backend
- **API Layer**: Express.js controllers and routes
- **Service Layer**: Business logic implementation
- **Data Layer**: Prisma ORM for database operations
- **Middleware**: Authentication, validation, error handling

## Technology Stack

### Flutter App
- **Framework**: Flutter 3.32.5 with Dart 3.8.1
- **State Management**: BLoC pattern with flutter_bloc
- **Dependency Injection**: GetIt + Injectable
- **Local Storage**: Hive for encrypted storage
- **API Communication**: Dio + Retrofit
- **UI**: Material Design 3 with custom theming
- **Security**: flutter_secure_storage, local_auth

### Backend
- **Framework**: Node.js with Express
- **Database**: SQLite (dev) / PostgreSQL (prod) with Prisma ORM
- **Authentication**: JWT token-based auth
- **API Integration**: OpenRouter for AI capabilities
- **Testing**: Jest for unit and integration tests

## 🚀 Getting Started

### Prerequisites

- Flutter 3.32.5 or higher
- Dart 3.8.1 or higher
- Node.js 18+ (for backend)
- OpenRouter API key

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/persona_ai_assistant.git
cd persona_ai_assistant
```

2. Set up environment variables
```bash
cp .env.example .env
```

3. Edit the `.env` file with your API keys and configuration:
```properties
# OpenRouter Configuration
OPENROUTER_API_KEY=your-openrouter-api-key-here  # Replace with your actual API key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
DEFAULT_MODEL=deepseek/deepseek-chat-v3-0324

# Backend Configuration 
BACKEND_BASE_URL=http://10.0.2.2:3000  # For Android emulator
# BACKEND_BASE_URL=http://localhost:3000  # For iOS simulator

# Environment
NODE_ENV=development

# Optional Features (can be disabled)
ENABLE_PUSH_NOTIFICATIONS=false  # Set to true if you want push notifications
```

**Important**: You must replace `your-openrouter-api-key-here` with your actual OpenRouter API key from [https://openrouter.ai/keys](https://openrouter.ai/keys).

4. Install Flutter dependencies
```bash
flutter pub get
```

5. Generate required files with build_runner
```bash
dart run build_runner build --delete-conflicting-outputs
```

6. Run the Flutter application
```bash
flutter run
```

**Note**: Push notifications are disabled by default. If you want to enable them, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for configuration instructions.

### Backend Setup

1. Navigate to the backend directory
```bash
cd persona-backend
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
   - Create a `.env` file in the backend directory with:
   ```
   DATABASE_URL="file:./dev.db"
   JWT_SECRET=your_jwt_secret_here
   OPENROUTER_API_KEY=your_openrouter_api_key
   OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
   ```

4. Run database migrations
```bash
npx prisma migrate dev
```

5. Start the backend server
```bash
npm run dev
```

### API Configuration

1. **Get OpenRouter API Key**
   - Visit [OpenRouter.ai](https://openrouter.ai)
   - Create an account and generate API key
   - Add credits to your account for AI model usage

2. **Configure in App**
   - Navigate to Settings → Privacy & Security → API OpenRouter
   - Enter your API key
   - The app will validate and save the configuration

## 📱 Screenshots

*(Screenshots would be added here showing each tab and key features)*

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Build for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🔐 Privacy & Security

- **Local Data Storage**: Sensitive data stored locally using Hive encryption
- **API Security**: All API calls use HTTPS with proper authentication
- **Data Minimization**: Only necessary data is collected and stored
- **User Control**: Users can view, export, or delete their data at any time
- **Crisis Detection**: Responsible handling of mental health indicators

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Dart/Flutter style guide
- Write tests for new features
- Update documentation for API changes
- Ensure accessibility compliance
- Test on both Android and iOS

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenRouter** for AI model access and API services
- **Flutter Team** for the excellent cross-platform framework
- **Material Design** for UI/UX guidelines and components
- **Psychology Research Community** for validated assessment tools

## 📞 Support

- **Documentation**: [Wiki](wiki_url)
- **Issues**: [GitHub Issues](issues_url)
- **Discussions**: [GitHub Discussions](discussions_url)
- **Email**: support@persona-ai.app

## 🔄 Changelog

### Version 1.0.0 (Current)
- Initial release with all core features
- MBTI and BDI psychology tests
- AI chat with OpenRouter integration
- Mood tracking and analytics
- Life tree visualization
- Little Brain memory system
- Material Design 3 UI

---

**Built with ❤️ using Flutter and OpenRouter API**
