import 'dart:io';

/// Script untuk validasi OpenRouter API Key configuration
/// Usage: dart run scripts/validate_api_key.dart
void main() async {
  print('🔍 Validating OpenRouter API Key Configuration...\n');

  try {
    // Read app_constants.dart file
    final constantsFile = File('lib/core/constants/app_constants.dart');
    
    if (!constantsFile.existsSync()) {
      print('❌ File not found: lib/core/constants/app_constants.dart');
      print('   Make sure you are running this from the project root directory.');
      exit(1);
    }

    final contents = await constantsFile.readAsString();
    
    // Extract API key from file
    final apiKeyRegex = RegExp(r"static const String openRouterApiKey = '([^']+)';");
    final match = apiKeyRegex.firstMatch(contents);
    
    if (match == null) {
      print('❌ Could not find openRouterApiKey declaration in app_constants.dart');
      print('   Expected format: static const String openRouterApiKey = \'your-key\';');
      exit(1);
    }

    final apiKey = match.group(1)!;
    
    // Validate API key format
    print('📋 API Key Analysis:');
    print('   Length: ${apiKey.length} characters');
    print('   Starts with sk-or-v1-: ${apiKey.startsWith('sk-or-v1-')}');
    print('   Is placeholder: ${_isPlaceholder(apiKey)}');
    print('');

    if (_isPlaceholder(apiKey)) {
      print('⚠️  API Key is still a placeholder!');
      print('');
      print('📝 To fix this:');
      print('   1. Visit https://openrouter.ai/keys');
      print('   2. Create a new API key');
      print('   3. Replace the placeholder in lib/core/constants/app_constants.dart');
      print('   4. Run this script again to verify');
      print('');
      print('💡 See API_KEY_SETUP.md for detailed instructions.');
      exit(1);
    }

    if (!apiKey.startsWith('sk-or-v1-')) {
      print('❌ Invalid API key format!');
      print('   OpenRouter API keys should start with "sk-or-v1-"');
      print('   Current key starts with: "${apiKey.substring(0, 10)}..."');
      exit(1);
    }

    if (apiKey.length < 20) {
      print('⚠️  API key seems too short!');
      print('   OpenRouter API keys are typically longer than 20 characters.');
      print('   Please verify your API key is complete.');
      exit(1);
    }

    // All validations passed
    print('✅ API Key Configuration Validated Successfully!');
    print('');
    print('🚀 Your Persona AI app should now be able to:');
    print('   • Connect to OpenRouter API');
    print('   • Use AI chat features');
    print('   • Generate curated content');
    print('   • Provide intelligent responses');
    print('');
    print('🧪 Next steps:');
    print('   • Run: flutter clean && flutter pub get');
    print('   • Test the chat feature in your app');
    print('   • Check the console for any API errors');
    
  } catch (e) {
    print('❌ Error during validation: $e');
    exit(1);
  }
}

bool _isPlaceholder(String apiKey) {
  final placeholders = [
    'YOUR_OPENROUTER_API_KEY',
    'sk-or-v1-your-api-key-here',
    'sk-or-v1-your-actual-api-key-here',
    'sk-or-v1-replace-with-your-key',
  ];
  
  return placeholders.any((placeholder) => apiKey == placeholder);
}
