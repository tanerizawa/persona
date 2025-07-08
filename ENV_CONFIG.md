# Environment Configuration Guide

## Overview

This project uses a `.env` file as the central source of truth for all credentials, API keys, model configurations, and other environment variables. This approach provides several benefits:

- Separation of configuration from code
- Easy environment switching (development, staging, production)
- Improved security by keeping sensitive data out of version control
- Simplified deployment and configuration management

## Setup

1. Create a `.env` file in the project root:
```bash
cp .env.example .env
```

2. Edit the `.env` file to set your configuration values:
```properties
# OpenRouter Configuration
OPENROUTER_API_KEY=your-key-here
DEFAULT_MODEL=your-preferred-model
```

## Key Configuration Sections

### App Settings
```properties
# App Configuration
APP_NAME=Persona AI Assistant
APP_VERSION=1.0.0
NODE_ENV=development  # or 'production' for production builds
APP_DOMAIN=https://persona-ai.app
```

### API Configuration
```properties
# OpenRouter Configuration
OPENROUTER_API_KEY=your-api-key-here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
DEFAULT_MODEL=deepseek/deepseek-chat-v3-0324

# Backend Configuration
BACKEND_BASE_URL=http://10.0.2.2:3000  # For Android emulator
# BACKEND_BASE_URL=http://localhost:3000  # For iOS simulator
```

### Model Selection
```properties
# Models for specific features
PERSONALITY_ANALYSIS_MODEL=gpt-4-turbo-preview
MOOD_ANALYSIS_MODEL=anthropic/claude-3-haiku:beta
```

### Security
```properties
# Authentication & Security
JWT_SECRET=your-jwt-secret-here
JWT_REFRESH_SECRET=your-jwt-refresh-secret-here
```

### Feature Flags
```properties
# Feature Flags
ENABLE_PUSH_NOTIFICATIONS=false
ENABLE_BIOMETRIC_AUTH=true
ENABLE_CRISIS_INTERVENTION=true
ENABLE_BACKGROUND_SYNC=true
```

## Implementation Details

The application uses `flutter_dotenv` to load variables from the `.env` file at startup. All configuration values are accessed through getters in the `AppConstants` and `EnvironmentConfig` classes, which provide default values in case the environment variables are missing.

### Code Example
```dart
// In AppConstants
static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
static String get defaultAiModel => dotenv.env['DEFAULT_MODEL'] ?? 'default-model';

// In your code
final apiKey = AppConstants.openRouterApiKey;
final model = AppConstants.defaultAiModel;
```

## Security Considerations

- **NEVER** commit the `.env` file to version control
- Use secure values for secrets (JWT tokens, API keys)
- For production, consider using a secrets management service
- Ensure the `.env` file is added to `.gitignore`

## Troubleshooting

If your app fails to connect to APIs or services:

1. Verify the `.env` file exists in the project root
2. Check that the required variables are set correctly
3. Ensure the app has loaded the `.env` file (check logs for errors)
4. Verify API keys and endpoints are valid
5. For emulator/simulator testing, ensure the backend URL is correct
