# 🚀 Quick Setup Guide

## What You Need to Do RIGHT NOW:

### 1. Get Your OpenRouter API Key (Required)

1. **Go to**: https://openrouter.ai/keys
2. **Sign up** or **log in** to your OpenRouter account
3. **Click "Create Key"** to generate a new API key
4. **Copy** the API key (it starts with `sk-or-v1-...`)

### 2. Update Your .env File

**Open your `.env` file** in the project root and replace:
```properties
OPENROUTER_API_KEY=your-openrouter-api-key-here
```

**With your actual API key:**
```properties
OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
```

### 3. Test Your API Key

Run this command to test if your API key works:
```bash
dart run scripts/test_api_key.dart
```

### 4. Run the App

```bash
flutter run
```

## Current Issues Fixed:

✅ **Firebase Error**: Fixed - push notifications now optional  
✅ **Environment Configuration**: Complete `.env` system implemented  
❌ **OpenRouter API**: Need valid API key (see steps above)  
❌ **Backend Token Refresh**: Backend server needs restart  

## If You See "No auth credentials found":

This means your OpenRouter API key is not valid. Follow steps 1-3 above.

## If You See "Token refresh failed":

The backend server needs to be restarted:
```bash
cd persona-backend
npm run dev
```

## Need Help?

1. **API Key Issues**: Check https://openrouter.ai/keys
2. **Backend Issues**: Make sure `npm run dev` is running in persona-backend folder
3. **App Issues**: Check the console logs for specific error messages

---

**⚠️ IMPORTANT**: You MUST replace the placeholder API key with a real one from OpenRouter.ai before the AI features will work!
