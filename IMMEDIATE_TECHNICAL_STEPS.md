# 🔧 IMMEDIATE TECHNICAL STEPS - PERSONA AI ASSISTANT

**Priority**: CRITICAL  
**Timeline**: Start immediately  
**Focus**: Fix backend, secure AI integration

## 🚨 STEP 1: DEBUG BACKEND AUTHENTICATION (Today)

### **Problem Diagnosis**
```bash
# Current status: All auth tests failing (0/7 passing)
cd /Users/odangrodiana/Documents/persona-backend
npm test
# Results: 500 errors, database connection issues
```

### **Immediate Actions Required**

#### **A. Check Database Connection**
```bash
# Verify PostgreSQL is running
brew services list | grep postgresql
brew services start postgresql@14

# Check database exists
psql -h localhost -U postgres -l
```

#### **B. Environment Variables**
```bash
# Create .env file in backend root:
DATABASE_URL="postgresql://postgres:password@localhost:5432/persona_ai"
JWT_SECRET="your-super-secure-jwt-secret-key"
NODE_ENV="development"
```

#### **C. Database Migration**
```bash
cd /Users/odangrodiana/Documents/persona-backend
npx prisma generate
npx prisma db push
npx prisma migrate deploy
```

#### **D. Test Connection**
```typescript
// Quick test file: test-db.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    await prisma.$connect();
    console.log('✅ Database connected successfully');
    
    // Test user creation
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        passwordHash: 'hashedpassword',
        deviceId: 'test-device'
      }
    });
    console.log('✅ User created:', user);
  } catch (error) {
    console.error('❌ Database error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
```

## 🚨 STEP 2: FIX AUTHENTICATION ENDPOINTS (Today)

### **Backend Code Issues to Fix**

#### **A. Registration Endpoint Fix**
```typescript
// In src/controllers/authController.ts
// Current issue: Returning 400 instead of 201

// Check these areas:
1. Input validation logic
2. Password hashing implementation  
3. Database insertion errors
4. Response format consistency
```

#### **B. Login Endpoint Fix**
```typescript
// Current issue: Returning 500 instead of 200/401
// Debug areas:
1. Password comparison logic
2. JWT token generation
3. Error handling in try-catch blocks
4. Database query execution
```

### **Specific Files to Check**
```bash
# These files likely have the bugs:
/src/controllers/authController.ts
/src/services/productionAuthService.ts  
/src/config/database.ts
/src/middlewares/auth.ts
```

## 🚨 STEP 3: CREATE AI PROXY ENDPOINTS (Tomorrow)

### **New Backend Routes Required**

#### **A. Chat Proxy Route**
```typescript
// File: src/routes/aiRoutes.ts (enhance existing)
import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth';
import axios from 'axios';

const router = Router();

// Proxy chat requests to OpenRouter
router.post('/chat', authenticateToken, async (req, res) => {
  try {
    const { messages, model = 'gpt-4-turbo-preview' } = req.body;
    
    const response = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model,
        messages,
        max_tokens: 1000,
        temperature: 0.7
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': process.env.APP_URL,
          'X-Title': 'Persona AI Assistant'
        }
      }
    );
    
    res.json({
      success: true,
      data: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('AI chat error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to process AI request'
    });
  }
});

export default router;
```

#### **B. Content Generation Proxy**
```typescript
// Add to same file: content generation for home tab
router.post('/content', authenticateToken, async (req, res) => {
  try {
    const { type, context } = req.body; // type: 'music'|'article'|'quote'|'journal'
    
    const prompts = {
      music: 'Generate 3 music recommendations based on...',
      article: 'Suggest 3 articles based on...',
      quote: 'Provide an inspiring quote for...',
      journal: 'Create a thoughtful journal prompt for...'
    };
    
    const response = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: 'You are a helpful AI assistant for Persona app.' },
          { role: 'user', content: prompts[type] + context }
        ],
        max_tokens: 500,
        temperature: 0.8
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    res.json({
      success: true,
      data: response.data,
      type,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to generate content'
    });
  }
});
```

## 🚨 STEP 4: UPDATE FLUTTER TO USE BACKEND (Day 2-3)

### **Critical Flutter Changes Needed**

#### **A. Remove OpenRouter API Key**
```dart
// File: lib/core/constants/app_constants.dart
// REMOVE THIS LINE:
static const String openRouterApiKey = 'sk-or-v1-...'

// REPLACE WITH:
static const String openRouterApiKey = ''; // Moved to backend for security
```

#### **B. Update API Service**
```dart
// File: lib/core/services/api_service.dart
class ApiService {
  static const String baseUrl = AppConstants.backendBaseUrl;
  
  // Replace direct OpenRouter calls with backend calls:
  
  // OLD:
  // final response = await http.post(
  //   Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
  //   headers: {'Authorization': 'Bearer ${AppConstants.openRouterApiKey}'},
  //   body: json.encode(data),
  // );
  
  // NEW:
  static Future<Map<String, dynamic>> chatWithAI(List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/chat'),
      headers: {
        'Authorization': 'Bearer ${await _getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'messages': messages}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get AI response');
    }
  }
  
  static Future<String> _getAuthToken() async {
    // Get JWT token from secure storage
    final secureStorage = SecureStorage();
    return await secureStorage.read(key: 'auth_token') ?? '';
  }
}
```

#### **C. Add Authentication Screens**
```dart
// Create new files:
// lib/features/auth/screens/login_screen.dart
// lib/features/auth/screens/register_screen.dart

// Update main.dart to check authentication:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const MainNavigationScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
```

## 📋 EXECUTION CHECKLIST

### **Day 1: Backend Fix**
- [ ] ✅ Set up PostgreSQL database
- [ ] ✅ Configure environment variables  
- [ ] ✅ Fix database connection
- [ ] ✅ Debug auth controller issues
- [ ] ✅ Get all auth tests passing (7/7)

### **Day 2: AI Proxy**
- [ ] ✅ Implement chat proxy endpoint
- [ ] ✅ Implement content generation proxy
- [ ] ✅ Test endpoints with Postman
- [ ] ✅ Add to main app.ts routes

### **Day 3: Flutter Integration**
- [ ] ✅ Remove API key from Flutter
- [ ] ✅ Update API service to use backend
- [ ] ✅ Add authentication screens
- [ ] ✅ Test end-to-end flow

### **Day 4: Testing & Validation**
- [ ] ✅ Backend tests: 7/7 passing
- [ ] ✅ Flutter builds successfully
- [ ] ✅ AI content generation through backend
- [ ] ✅ Authentication flow working

## 🔍 VERIFICATION COMMANDS

```bash
# Backend health check:
curl http://localhost:3000/health

# Test authentication:
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","deviceId":"test"}'

# Test AI proxy:
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'

# Flutter test:
cd /Users/odangrodiana/Documents/Persona
flutter test
flutter analyze
```

---

**Start with STEP 1 immediately. Each step builds on the previous one. This will achieve secure, production-ready backend integration within 4 days.**
