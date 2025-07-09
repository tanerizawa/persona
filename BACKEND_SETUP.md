# Persona Assistant - Backend Setup Guide

## 🚀 Technology Stack

### Core Backend
- **Runtime**: Node.js 18+ 
- **Framework**: Express.js
- **Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Language**: TypeScript

### AI & External Services
- **AI Provider**: OpenRouter API
- **Vector Database**: pgvector (PostgreSQL extension)
- **File Storage**: AWS S3 / Local Storage

### Authentication & Security
- **Auth**: JWT + Refresh Tokens
- **Validation**: Joi / Zod
- **Security**: Helmet, CORS, Rate Limiting
- **Encryption**: bcryptjs

### Development Tools
- **ORM**: Prisma / TypeORM
- **API Docs**: Swagger/OpenAPI
- **Testing**: Jest + Supertest
- **Linting**: ESLint + Prettier

## 📁 Backend Project Structure

```
persona-backend/
├── src/
│   ├── config/           # Database, env configs
│   ├── controllers/      # Route handlers
│   ├── middlewares/      # Auth, validation, error handling
│   ├── models/          # Database models/schemas
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── utils/           # Helper functions
│   └── types/           # TypeScript types
├── prisma/              # Database schema & migrations
├── tests/               # Unit & integration tests
├── docs/                # API documentation
└── docker/              # Docker configuration
```

## 🛠 Setup Commands

### 1. Initialize Project
```bash
mkdir persona-backend
cd persona-backend
npm init -y
```

### 2. Install Dependencies
```bash
# Core dependencies
npm install express cors helmet morgan compression
npm install jsonwebtoken bcryptjs joi
npm install prisma @prisma/client pg redis
npm install axios dotenv uuid

# Development dependencies
npm install -D typescript @types/node @types/express
npm install -D @types/jsonwebtoken @types/bcryptjs @types/pg
npm install -D nodemon ts-node eslint prettier jest supertest
npm install -D @types/jest @types/supertest
```

### 3. Setup TypeScript
```bash
npx tsc --init
```

### 4. Database Setup
```bash
# Install PostgreSQL (macOS)
brew install postgresql redis
brew services start postgresql
brew services start redis

# Initialize Prisma
npx prisma init
```

## 🗃 Database Schema Implementation

Based on `IMPLEMENTATION_PLAN.md` specifications.

## 🔐 Environment Variables

```env
# Server
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database
DATABASE_URL="postgresql://username:password@localhost:5432/persona_ai?schema=public"
REDIS_URL="redis://localhost:6379"

# Authentication
JWT_SECRET=your_super_secret_jwt_key
JWT_REFRESH_SECRET=your_refresh_secret_key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# OpenRouter API
OPENROUTER_API_KEY=your_openrouter_api_key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Security
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
ALLOWED_ORIGINS=http://localhost:3000,https://your-frontend-domain.com
```

## 📊 Next Steps

1. **Database Schema Setup** - Implement Prisma schemas
2. **Authentication System** - JWT-based auth with refresh tokens  
3. **Core API Routes** - User management, Little Brain endpoints
4. **OpenRouter Integration** - Proxy and enhance AI requests
5. **Little Brain Service** - Context extraction, personality modeling
6. **Testing Setup** - Unit and integration tests
7. **Docker Configuration** - Containerized deployment
8. **API Documentation** - Swagger/OpenAPI specs

## 🎯 Development Workflow

1. **Local Development**: `npm run dev`
2. **Database Migrations**: `npx prisma migrate dev`
3. **Generate Prisma Client**: `npx prisma generate`
4. **Run Tests**: `npm test`
5. **Build for Production**: `npm run build`

Ready to start building! 🚀
