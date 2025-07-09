# 🔑 OpenRouter API Key Setup Guide

## ⚠️ API Key Required for AI Features

Persona Assistant uses OpenRouter API untuk fitur-fitur AI seperti chat assistant dan content generation. Untuk menggunakan fitur-fitur ini, Anda perlu mengkonfigurasi API key.

## 📋 Step-by-Step Setup

### 1. **Dapatkan OpenRouter API Key**

1. Kunjungi [https://openrouter.ai/keys](https://openrouter.ai/keys)
2. Daftar atau login ke akun Anda
3. Klik "Create Key" untuk membuat API key baru
4. Beri nama key (contoh: "Persona Development")
5. Copy API key yang dimulai dengan `sk-or-v1-...`

### 2. **Update Konfigurasi App**

Edit file: `.env` di root project:

```properties
# OpenRouter Configuration
OPENROUTER_API_KEY=sk-or-v1-your-api-key-here
```

Pastikan Anda menggantinya dengan API key yang sebenarnya:

```properties
OPENROUTER_API_KEY=sk-or-v1-1234567890abcdef...
```

### 3. **Restart Application**

Setelah mengupdate API key:
```bash
flutter clean
flutter pub get
flutter run
```

## 🛡️ Security Best Practices

### ⚠️ **JANGAN** commit API key ke Git
```bash
# Tambahkan ke .gitignore jika belum ada
echo "lib/core/constants/app_constants.dart" >> .gitignore
```

### 🌍 Environment Variables

Aplikasi ini telah dikonfigurasi untuk menggunakan environment variables melalui file `.env`. Ini memungkinkan konfigurasi mudah tanpa mengubah kode sumber:

1. **Jika belum ada file `.env`**, salin dari template:
```bash
cp .env.example .env
```

2. **Edit file `.env`** untuk mengatur semua konfigurasi:
```properties
# OpenRouter Configuration
OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
DEFAULT_MODEL=deepseek/deepseek-chat-v3-0324

# Backend Configuration
BACKEND_BASE_URL=http://10.0.2.2:3000  # For Android emulator
# BACKEND_BASE_URL=http://localhost:3000  # For iOS simulator

# Environment
NODE_ENV=development  # Change to 'production' for production builds
```

**Note**: Semua konfigurasi telah diatur untuk dimuat otomatis saat aplikasi dijalankan.

## 🧪 Testing API Key Configuration

Gunakan script validasi untuk memastikan API key dikonfigurasi dengan benar:

```bash
# Jalankan dari root project
dart run scripts/validate_api_key.dart
```

## 🆘 Troubleshooting

### Error: "No auth credentials found"
- ✅ Pastikan API key dimulai dengan `sk-or-v1-`
- ✅ Pastikan tidak ada spasi di awal/akhir API key
- ✅ Pastikan API key tidak expired

### Error: "API Key is invalid or expired"
- ✅ Login ke OpenRouter dashboard untuk cek status key
- ✅ Generate API key baru jika perlu
- ✅ Update konfigurasi dengan key yang baru

### Error: "Rate limit exceeded"
- ✅ Tunggu beberapa menit sebelum mencoba lagi
- ✅ Cek usage limit di OpenRouter dashboard
- ✅ Upgrade plan jika diperlukan

## 💰 Biaya dan Limits

### Free Tier
- $0.002 per 1K tokens (Claude 3.5 Sonnet)
- Cocok untuk development dan testing
- Rate limit: 200 requests/day

### Paid Plans
- Pay-per-use dengan rate yang kompetitif
- Higher rate limits
- Priority access

## 🎯 Fitur yang Memerlukan API Key

### ✅ Dengan API Key:
- 💬 AI Chat Assistant dengan personality awareness
- 🏠 AI-curated home content (musik, artikel, quotes)
- 📝 Smart journal prompts
- 🧠 Advanced conversation analysis

### ✅ Tanpa API Key (Offline Mode):
- 📊 Mood tracking dan analytics
- 🧠 Psychology tests (MBTI, BDI)
- 📅 Calendar dan life tree visualization
- 💾 Local data management
- 🔄 Data sync dan backup

## 📱 Development vs Production

### Development
```dart
static const String openRouterApiKey = 'sk-or-v1-dev-key...';
```

### Production
Gunakan secure storage atau environment variables:
```dart
static String get openRouterApiKey {
  return const String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: 'sk-or-v1-fallback-key...',
  );
}
```

## 🔗 Links Berguna

- [OpenRouter API Docs](https://openrouter.ai/docs)
- [OpenRouter Dashboard](https://openrouter.ai/activity)
- [OpenRouter Models](https://openrouter.ai/models)
- [Persona GitHub Issues](https://github.com/your-repo/issues)

---

💡 **Tip**: Untuk testing, Anda bisa mulai dengan free tier OpenRouter yang sudah cukup untuk development dan demo.
