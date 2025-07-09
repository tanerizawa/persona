# Ultra-Minimal Persona Sync Server

## Overview

Ultra-minimal Node.js + PostgreSQL server for Persona Local-First Architecture sync capabilities. Designed to be the smallest possible production server to support multi-device sync while maintaining privacy.

## Features

- 🔐 JWT Authentication (register/login)
- 📤 Push sync data to server
- 📥 Pull sync data from server  
- 📊 Sync status and metadata
- 🔄 Device sync tracking
- 🛡️ Basic security (Helmet, CORS)
- 📦 Minimal dependencies

## API Endpoints

### 1. Health Check

```
GET /health
Response: { status: "ok", timestamp: "...", service: "persona-sync-server" }
```

### 2. Register User

```
POST /register
Body: { username: "user", password: "pass" }
Response: { user: {...}, token: "jwt_token" }
```

### 3. Login User

```
POST /login  
Body: { username: "user", password: "pass" }
Response: { user: {...}, token: "jwt_token" }
```

### 4. Push Sync Data

```
POST /sync/push
Headers: Authorization: Bearer <token>
Body: { 
  data_type: "memories", 
  items: [{ entity_id: "id", data: {...} }] 
}
```

### 5. Pull Sync Data

```
GET /sync/pull/:data_type?since=timestamp
Headers: Authorization: Bearer <token>
Response: { items: [...], total_count: 10 }
```

### 6. Get Sync Status

```
GET /sync/status
Headers: Authorization: Bearer <token>
Response: { data_types: {...}, devices: [...] }
```

### 7. Update Device Metadata

```
POST /sync/device
Headers: Authorization: Bearer <token>
Body: { device_id: "device_uuid" }
```

## Setup

### 1. Database Setup (PostgreSQL)

```bash
# Install PostgreSQL
brew install postgresql  # macOS
# or apt-get install postgresql  # Ubuntu

# Create database
createdb persona_sync

# Or using psql:
psql -c "CREATE DATABASE persona_sync;"
```

### 2. Server Setup

```bash
cd ultra-minimal-server
npm install
cp .env.example .env

# Edit .env with your database credentials
nano .env

# Start server
npm run dev  # Development
npm start    # Production
```

### 3. Environment Variables

```bash
PORT=3000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=persona_sync
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRE=7d
CORS_ORIGIN=*
MAX_SYNC_ITEMS=1000
```

## Database Schema

### Tables Created Automatically

1. **users** - User authentication
2. **sync_data** - Actual sync data (JSONB)
3. **sync_metadata** - Device and sync tracking

## Integration with Flutter

### 1. Add to Flutter dependencies

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.0
```

### 2. Example Flutter integration

```dart
class SyncService {
  static const String baseUrl = 'http://localhost:3000';
  
  static Future<void> pushMemories(List<Memory> memories) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/push'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data_type': 'memories',
        'items': memories.map((m) => {
          'entity_id': m.id,
          'data': m.toJson(),
        }).toList(),
      }),
    );
  }
  
  static Future<List<Memory>> pullMemories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/pull/memories'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // Process response...
  }
}
```

## Security Notes

- Change JWT_SECRET in production
- Use HTTPS in production
- Limit CORS_ORIGIN in production
- Consider rate limiting for production
- Add input validation as needed

## Production Deployment

### Option 1: Railway/Render/Heroku

1. Create account on Railway.app
2. Connect GitHub repo
3. Set environment variables
4. Add PostgreSQL addon
5. Deploy

### Option 2: VPS (DigitalOcean/Linode)

```bash
# Install Node.js and PostgreSQL
# Clone repo and setup
# Use PM2 for process management
npm install -g pm2
pm2 start index.js --name persona-sync
pm2 save
pm2 startup
```

### Option 3: Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Monitoring

- Health check endpoint: `/health`
- Server logs via console
- Add APM tool (New Relic, DataDog) as needed

## Performance

- Handles ~1000 items per sync request
- JWT tokens expire in 7 days
- JSONB for flexible data storage
- Indexed queries for performance

## Size

- ~200 lines of code
- 7 essential dependencies
- ~10MB Docker image
- Minimal resource usage

This server provides the essential sync capabilities needed for Persona's Local-First Architecture while remaining ultra-minimal and production-ready.
