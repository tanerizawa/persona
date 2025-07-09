# Persona Backend

Ultra-lightweight server untuk Persona Assistant dengan arsitektur local-first. Backend ini dirancang minimal untuk mendukung sinkronisasi dan orkestrasi AI, sementara semua data utama disimpan di perangkat klien.

## 🏗️ Arsitektur

### Filosofi: "Server sebagai Orchestrator, Device sebagai Brain"

- **Server**: Hanya menangani autentikasi, sinkronisasi metadata, dan orkestrasi AI
- **Client**: Menyimpan semua data Little Brain, riwayat chat, dan konteks pengguna
- **Database**: Ultra-minimal untuk menjaga biaya server rendah

## 🚀 Fitur Utama

### ✅ Authentication Service
- User registration & login dengan JWT
- Password hashing dengan bcrypt
- Token verification & refresh

### ✅ Sync Service  
- Metadata sinkronisasi antar perangkat
- Backup terenkripsi untuk disaster recovery
- Data integrity validation

### ✅ AI Orchestration
- AI scripts management untuk prompt templates
- Health check untuk layanan AI
- Configuration management

## 📊 Database Schema

### Users Table (Authentication)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    created_at TIMESTAMP,
    last_sync TIMESTAMP,
    device_count INTEGER
);
```

### Sync Status Table (Sinkronisasi)
```sql
CREATE TABLE user_sync_status (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    device_id VARCHAR(255),
    last_sync_timestamp TIMESTAMP,
    sync_version INTEGER,
    data_hash VARCHAR(255),
    is_active BOOLEAN
);
```

### AI Scripts Table (Orkestrasi)
```sql
CREATE TABLE ai_scripts (
    id UUID PRIMARY KEY,
    script_name VARCHAR(100) UNIQUE,
    version VARCHAR(20),
    script_content JSONB,
    is_active BOOLEAN,
    created_at TIMESTAMP
);
```

### Backups Table (Recovery)
```sql
CREATE TABLE user_backups (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    encrypted_data TEXT,
    backup_date TIMESTAMP,
    data_size INTEGER,
    checksum VARCHAR(255)
);
```

## 🛠️ Tech Stack

- **Runtime**: Node.js dengan TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL dengan Prisma ORM
- **Authentication**: JWT dengan bcrypt
- **Security**: Helmet, CORS, Rate limiting
- **Testing**: Jest dengan Supertest
- **Code Quality**: ESLint + Prettier

## 📦 Installation

### Prerequisites
- Node.js 18+ 
- PostgreSQL 14+
- npm atau yarn

### Setup
```bash
# Clone repository
git clone <repo-url>
cd persona-backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env dengan konfigurasi database Anda

# Setup database
npm run prisma:migrate
npm run prisma:generate

# Start development server
npm run dev
```

## 🔧 Environment Variables

```env
NODE_ENV=development
PORT=3000
DATABASE_URL="postgresql://username:password@localhost:5432/persona_db"
JWT_SECRET=your-super-secret-jwt-key
ALLOWED_ORIGINS=http://localhost:3000
```

## 🎯 API Endpoints

### Authentication
```
POST /api/auth/register     # Register user baru
POST /api/auth/login        # Login user
GET  /api/auth/profile      # Get user profile
POST /api/auth/verify       # Verify JWT token
```

### Sync Management
```
POST /api/sync/status       # Update sync status
GET  /api/sync/status/:deviceId  # Get sync status
POST /api/sync/backup       # Create encrypted backup
GET  /api/sync/backup/latest     # Get latest backup
```

### AI Orchestration
```
GET  /api/ai/scripts        # Get active AI scripts
GET  /api/ai/scripts/:name  # Get specific script
GET  /api/ai/health         # AI services health check
```

### Health Check
```
GET  /health                # Server health status
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm test -- --coverage
```

## 🚀 Deployment

### Production Build
```bash
npm run build
npm start
```

### Docker (Optional)
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 3000
CMD ["npm", "start"]
```

## 📊 Monitoring & Health

### Health Check Endpoint
```bash
curl http://localhost:3000/health
```

### Response Example
```json
{
  "status": "OK",
  "message": "Persona Backend - Ultra-lightweight server",
  "timestamp": "2025-01-08T10:00:00.000Z",
  "uptime": 3600
}
```

## 🔒 Security Features

- **JWT Authentication** dengan expiry time
- **Password Hashing** menggunakan bcrypt (12 rounds)
- **CORS Protection** dengan whitelist origins
- **Helmet** untuk security headers
- **Request Rate Limiting**
- **Input Validation** dengan Joi/Zod
- **SQL Injection Protection** via Prisma ORM

## 📈 Performance Optimizations

- **Minimal Database Schema** untuk performa tinggi
- **Connection Pooling** dengan Prisma
- **Compression** untuk response payload
- **Efficient Indexing** pada query yang sering digunakan
- **Graceful Shutdown** untuk cleanup resources

## 🎯 Production Considerations

### Scaling
- Backend dapat di-scale horizontal karena stateless
- Database connection pooling untuk handle concurrent users
- Redis caching untuk session management (opsional)

### Security
- Rate limiting per IP address
- JWT token rotation
- Database backup encryption
- Environment variables protection

### Monitoring
- Request/response logging dengan Morgan
- Error tracking dan alerting
- Database performance monitoring
- Health check endpoints

## 📱 Flutter Integration

Backend ini dirancang khusus untuk mengintegrasikan dengan Persona Flutter app:

- **Local-first Architecture**: Flutter app bekerja offline, server hanya untuk sync
- **Minimal Data Transfer**: Hanya metadata yang disinkronisasi
- **Encrypted Backups**: Data sensitif dienkripsi sebelum backup
- **Real-time Sync**: WebSocket support untuk real-time updates (future)

## 🔄 Development Workflow

1. **Code Changes**: Edit TypeScript files di `src/`
2. **Auto Reload**: nodemon akan restart server otomatis
3. **Type Safety**: TypeScript akan catch errors sebelum runtime
4. **Database Changes**: Update Prisma schema → generate → migrate
5. **Testing**: Write tests untuk semua new features
6. **Linting**: ESLint akan check code quality

## 📚 Additional Resources

- [Prisma Documentation](https://www.prisma.io/docs)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [JWT Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
- [PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

---

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

MIT License - lihat [LICENSE](LICENSE) file untuk detail.

---

**Dibuat dengan ❤️ untuk Persona Assistant**
