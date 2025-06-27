# Environment Configuration Guide

This document explains how to configure and use different environments (Development, Testing, Production) in the Startupworld Flutter app.

## Overview

The app supports three environments:
- **Development** (`dev.startupworld.in`) - For development and testing
- **Testing** (`smartcookie.in`) - For staging and testing
- **Production** (`startupworld.in`) - For live production use

## Login Format

### Student Login
```json
{
  "email": "student@example.com",
  "password": "password123",
  "user_type": "student",
  "api_key": "efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u"
}
```

### Staff Login
```json
{
  "username": "staff_username",
  "password": "password123",
  "usertype": "3",
  "api_key": "efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u"
}
```

**Note**: Staff can use either username or email address in the username field.

## Configuration Files

### 1. `lib/config/app_config.dart`
This is the main configuration file where you can:
- Set the default environment
- Configure API endpoints for each environment
- Set environment-specific settings

### 2. `lib/config/environment.dart`
Contains the environment enum and helper methods for getting environment-specific values.

### 3. `lib/services/api_client.dart`
Uses the environment configuration to set up API clients with the correct base URLs and settings.

## How to Change Environment

### Method 1: Change Default Environment (Recommended for builds)
Edit `lib/config/app_config.dart`:

```dart
// Change this line to set the default environment
static const Environment defaultEnvironment = Environment.production; // or .development, .testing
```

### Method 2: Runtime Environment Selection (Development only)
In development mode, you can use the environment selector widget in the top-right corner of the app to switch between environments at runtime.

## Environment-Specific Settings

### Development Environment
- **Base URL**: `https://dev.startupworld.in/`
- **API Key**: `dev_api_key_here` (replace with actual dev key)
- **Timeout**: 30 seconds
- **Logging**: Enabled
- **Color**: Orange

### Testing Environment
- **Base URL**: `https://smartcookie.in/`
- **API Key**: `test_api_key_here` (replace with actual test key)
- **Timeout**: 60 seconds
- **Logging**: Enabled
- **Color**: Blue

### Production Environment
- **Base URL**: `https://startupworld.in`
- **API Key**: `efc10cqkr4Ta29EIcYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u`
- **Timeout**: 120 seconds
- **Logging**: Disabled
- **Color**: Green

## Build Configurations

### For Development Build
```bash
flutter build apk --debug
# or
flutter run
```

### For Testing Build
1. Change `defaultEnvironment` to `Environment.testing` in `app_config.dart`
2. Run: `flutter build apk --release`

### For Production Build
1. Change `defaultEnvironment` to `Environment.production` in `app_config.dart`
2. Run: `flutter build apk --release`

## API Key Configuration

### Development
Replace `dev_api_key_here` in `app_config.dart` with your actual development API key.

### Testing
Replace `test_api_key_here` in `app_config.dart` with your actual testing API key.

### Production
The production API key is already configured.

## Features

### Environment Selector Widget
- Only visible in development mode
- Allows switching between environments at runtime
- Shows current environment with color coding
- Displays confirmation when environment is changed

### API Logging
- Development and Testing: Full API request/response logging
- Production: No logging for security and performance

### Timeout Configuration
- Development: 30 seconds (faster feedback)
- Testing: 60 seconds (balanced)
- Production: 120 seconds (reliable)

## Security Considerations

1. **API Keys**: Never commit real API keys to version control
2. **Logging**: Disabled in production to prevent sensitive data exposure
3. **Environment Detection**: The environment selector is only visible in development mode

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Check if the base URL is correct for your environment
   - Verify the API key is valid
   - Ensure the server is accessible

2. **Environment Not Changing**
   - Make sure you're in development mode to use the environment selector
   - Check that `AppConfig.initialize()` is called in `main()`

3. **Build Issues**
   - Ensure all dependencies are installed: `flutter pub get`
   - Check for any syntax errors in configuration files

### Debug Information
When in development mode, you can see:
- Current environment in the top-right corner
- API request/response logs in the console
- Environment-specific timeout and logging settings

## Best Practices

1. **Development**: Use development environment for local development
2. **Testing**: Use testing environment for QA and staging
3. **Production**: Use production environment for live releases
4. **API Keys**: Store sensitive keys securely and never commit them to version control
5. **Logging**: Keep logging enabled in development/testing, disabled in production 