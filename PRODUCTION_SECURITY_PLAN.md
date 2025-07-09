# 🔐 Persona - USER MANAGEMENT & SECURITY PLAN

## 📊 **STRATEGI KEAMANAN UNTUK 100 USER PERTAMA**

### 🔑 **1. API KEY MANAGEMENT**

#### **Pendekatan Multi-Layer Security:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Backend Server │    │  OpenRouter AI  │
│                 │    │                 │    │                 │
│ • No API Key    │◄──►│ • Master API Key│◄──►│ • Rate Limiting │
│ • Device Token  │    │ • User Quotas   │    │ • Usage Tracking│
│ • Local Crypto  │    │ • Request Proxy │    │ • Cost Control  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### **Implementasi:**
1. **Frontend (Flutter)**: Tidak menyimpan API key sama sekali
2. **Backend**: Menyimpan dan mengelola API key secara terpusat
3. **Proxy System**: Semua request AI melalui backend
4. **User Quotas**: Pembatasan penggunaan per user
5. **Rate Limiting**: Perlindungan dari abuse

---

### 👥 **2. USER MANAGEMENT SYSTEM**

#### **Database Schema (Production Ready):**
```sql
-- Users Table (Enhanced)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  verification_token VARCHAR(255),
  
  -- Profile Information
  display_name VARCHAR(100),
  avatar_url TEXT,
  bio TEXT,
  
  -- Account Status
  account_status ENUM('active', 'suspended', 'pending') DEFAULT 'pending',
  subscription_tier ENUM('free', 'premium') DEFAULT 'free',
  
  -- Usage Tracking
  api_quota_daily INTEGER DEFAULT 50,
  api_usage_today INTEGER DEFAULT 0,
  last_quota_reset DATE DEFAULT CURRENT_DATE,
  
  -- Security
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP NULL,
  last_login TIMESTAMP,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP NULL
);

-- Device Sessions
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  device_id VARCHAR(64) NOT NULL,
  device_name VARCHAR(100),
  device_type ENUM('android', 'ios', 'web'),
  
  -- Session Management
  access_token_hash VARCHAR(255) NOT NULL,
  refresh_token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  
  -- Security Tracking
  ip_address INET,
  user_agent TEXT,
  last_active TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, device_id)
);

-- API Usage Tracking
CREATE TABLE api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  endpoint VARCHAR(100) NOT NULL,
  request_size INTEGER,
  response_size INTEGER,
  processing_time INTEGER, -- milliseconds
  tokens_used INTEGER,
  cost_cents INTEGER, -- in cents
  status_code INTEGER,
  error_message TEXT,
  
  created_at TIMESTAMP DEFAULT NOW()
);

-- Security Events
CREATE TABLE security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type VARCHAR(50) NOT NULL,
  severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
  description TEXT,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB,
  
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

### 🛡️ **3. IMPLEMENTASI KEAMANAN**

#### **A. Authentication Flow:**
```
1. Registration:
   ├─ Email validation
   ├─ Password strength check (min 8 char, mixed case, numbers)
   ├─ Device fingerprinting
   ├─ Email verification required
   └─ Account pending until verified

2. Login:
   ├─ Rate limiting (5 attempts per hour)
   ├─ Device recognition
   ├─ JWT token generation (15min access + 7day refresh)
   ├─ Session tracking
   └─ Security event logging

3. API Access:
   ├─ Token validation on every request
   ├─ User quota checking
   ├─ Request logging
   ├─ Rate limiting
   └─ Cost tracking
```

#### **B. Security Headers & Middleware:**
```typescript
// Security middleware stack
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://openrouter.ai"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// Rate limiting
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
}));

// Request size limiting
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ limit: '1mb', extended: true }));
```

---

### 💰 **4. COST MANAGEMENT**

#### **User Quotas (Free Tier):**
- **Daily API Calls**: 50 requests
- **Monthly Tokens**: 100,000 tokens
- **Chat Sessions**: 10 sessions/day
- **Psychology Tests**: 3 tests/month
- **Data Storage**: 50MB per user

#### **Usage Monitoring:**
```typescript
interface UserQuota {
  daily_api_calls: number;
  monthly_tokens: number;
  chat_sessions_today: number;
  psychology_tests_month: number;
  storage_used_mb: number;
}

// Automatic quota reset
// Daily: Reset at midnight
// Monthly: Reset on account creation anniversary
```

---

### 🔄 **5. BACKUP & DISASTER RECOVERY**

#### **Data Protection Strategy:**
1. **Local Data**: Encrypted with device-specific keys
2. **Server Backup**: Daily encrypted backups to secure cloud storage
3. **Point-in-time Recovery**: 30-day retention
4. **Geographic Redundancy**: Multi-region deployment ready

#### **User Data Export:**
- **GDPR Compliance**: Complete data export in JSON format
- **Data Portability**: Easy migration to other platforms
- **Deletion Rights**: Complete account and data deletion

---

### 📊 **6. MONITORING & ANALYTICS**

#### **Security Metrics:**
- **Failed Login Attempts**: Real-time monitoring
- **Unusual API Usage**: Spike detection
- **Geographic Anomalies**: Login from new locations
- **Device Changes**: New device notifications

#### **Performance Metrics:**
- **API Response Times**: < 500ms target
- **Error Rates**: < 1% target
- **User Satisfaction**: In-app feedback
- **Cost per User**: Monthly tracking

---

### 🚀 **7. DEPLOYMENT CHECKLIST**

#### **Production Readiness:**
- ✅ HTTPS/TLS 1.3 encryption
- ✅ Database connection pooling
- ✅ Redis session store
- ✅ Log aggregation (ELK stack)
- ✅ Health check endpoints
- ✅ Graceful shutdown handling
- ✅ Environment variable management
- ✅ Docker containerization
- ✅ Load balancer configuration
- ✅ Database migrations
- ✅ Backup automation
- ✅ Monitoring alerts

#### **Scaling Preparation:**
- **Horizontal Scaling**: Stateless backend design
- **Database Optimization**: Proper indexing, query optimization
- **Caching Strategy**: Redis for sessions, API responses
- **CDN Integration**: Static asset delivery
- **Microservices Ready**: Modular architecture

---

### 📱 **8. ANDROID-SPECIFIC SECURITY**

#### **App Security Features:**
```kotlin
// Android Manifest Security
<application
    android:allowBackup="false"
    android:extractNativeLibs="false"
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">

// Network Security Config
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">your-api-domain.com</domain>
        <pin-set expiration="2026-01-01">
            <pin digest="SHA-256">your-certificate-pin</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

#### **Biometric Authentication:**
- **Fingerprint/Face unlock**: Secondary authentication
- **Hardware Security Module**: Credential storage
- **Secure Enclave**: iOS equivalent protection

---

### 🎯 **9. GO-LIVE STRATEGY**

#### **Phase 1: Beta Testing (20 users)**
- Internal testing team
- Core feature validation
- Performance baseline
- Security audit

#### **Phase 2: Limited Release (50 users)**
- Invite-only access
- Feedback collection
- Load testing
- Bug fixes

#### **Phase 3: Public Launch (100 users)**
- Open registration
- Marketing campaign
- Customer support
- Scaling monitoring

---

### 📋 **10. COMPLIANCE & LEGAL**

#### **Data Protection:**
- **GDPR**: European user compliance
- **CCPA**: California user compliance
- **COPPA**: Under-13 user protection
- **HIPAA**: Health data considerations

#### **Terms of Service:**
- Clear usage policies
- Data retention policies
- User responsibilities
- Service limitations

---

## 🎉 **READY FOR 100 USERS**

Dengan implementasi ini, Persona siap untuk menangani 100 user pertama dengan:

✅ **Security**: Enterprise-grade protection
✅ **Scalability**: Ready for growth
✅ **Cost Control**: Predictable expenses
✅ **User Experience**: Smooth, secure operation
✅ **Compliance**: Legal requirements met
✅ **Monitoring**: Full visibility into operations

**Total estimated monthly cost for 100 users: $50-100 USD**
(Includes hosting, AI API usage, and infrastructure)
