import 'dart:io';

/// Script untuk validasi OpenRouter API Key configuration
/// Usage: dart run scripts/validate_api_key.dart
void main() async {
  print('🔍 Validating OpenRouter API Key Configuration...\n');

  try {
    // Check for .env file
    final envFile = File('.env');
    
    if (!envFile.existsSync()) {
      print('❌ .env file not found!');
      print('   Please create a .env file in the project root directory.');
      print('   You can copy .env.example if available.');
      exit(1);
    }

    final envContents = await envFile.readAsString();
    
    // Extract API key from .env file
    final apiKeyRegex = RegExp(r'^OPENROUTER_API_KEY=(.*)$', multiLine: true);
    final match = apiKeyRegex.firstMatch(envContents);
    
    if (match == null) {
      print('❌ Could not find OPENROUTER_API_KEY in .env file');
      print('   Expected format: OPENROUTER_API_KEY=your-key');
      exit(1);
    }

    final apiKey = match.group(1)!.trim();
    
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
      print('   3. Replace the placeholder in .env file');
      print('   4. Run this script again to verify');
      print('');
      print('💡 See API_KEY_SETUP.md for detailed instructions.');
      exit(1);
    }

    if (!apiKey.startsWith('sk-or-v1-')) {
      print('❌ Invalid API key format!');
      print('   OpenRouter API keys should start with "sk-or-v1-"');
      print('   Current key starts with: "${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}..."');
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
    print('🚀 Your Persona app should now be able to:');
    print('   • Connect to OpenRouter API');
    print('   • Use AI chat features');
    print('   • Generate curated content');
    print('   • Provide intelligent responses');
    print('');
    print('🧪 Next steps:');
    print('   • Test the chat feature in your app');
    print('   • Check the console for any API errors');
    print('   • Verify AI content generation works');
    print('');
    print('💡 Note: API key is now loaded from .env file for better security.');
    
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
    'sk-or-v1-your-openrouter-api-key-here',
  ];
  
  return placeholders.any((placeholder) => apiKey == placeholder);
}
