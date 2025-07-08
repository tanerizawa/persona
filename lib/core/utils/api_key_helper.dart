import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ApiKeyHelper {
  static const String _apiKeyInstructions = '''
🔑 OpenRouter API Key Setup Required

Your Persona AI Assistant needs an OpenRouter API key to work with AI features.

Steps to get your API key:
1. Visit https://openrouter.ai/keys
2. Sign up or login to your account
3. Create a new API key
4. Copy the API key (starts with "sk-or-v1-...")

Then update the API key in:
.env file in the project root

Replace:
OPENROUTER_API_KEY=your-openrouter-api-key-here

With your actual API key:
OPENROUTER_API_KEY=sk-or-v1-your-actual-key...

⚠️ Important: Keep your API key secure and never share it publicly!
''';

  static void showApiKeySetupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.orange),
            SizedBox(width: 8),
            Text('API Key Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OpenRouter API key is not configured.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  _apiKeyInstructions,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  static void logApiKeyError() {
    if (kDebugMode) {
      print('\n${'=' * 60}');
      print('🔑 OPENROUTER API KEY CONFIGURATION REQUIRED');
      print('=' * 60);
      print(_apiKeyInstructions);
      print('${'=' * 60}\n');
    }
  }

  static bool isApiKeyValid(String apiKey) {
    return apiKey.isNotEmpty && 
           apiKey.startsWith('sk-or-v1-') && 
           apiKey != 'sk-or-v1-your-api-key-here' &&
           apiKey != 'YOUR_OPENROUTER_API_KEY';
  }
}
