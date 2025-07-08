import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/database';

describe('Authentication Endpoints', () => {
  beforeEach(async () => {
    // Clean up test data
    await prisma.userSyncStatus.deleteMany();
    await prisma.userBackup.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'Password123',
        name: 'Test User',
        deviceId: 'test-device-123'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.user.email).toBe(userData.email);
      expect(response.body.accessToken).toBeDefined();
      expect(response.body.user.passwordHash).toBeUndefined();
    });

    it('should return error for duplicate email', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'Password123',
        name: 'Test User',
        deviceId: 'test-device-123'
      };

      // First registration
      await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      // Second registration with same email
      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(409);

      expect(response.body.error).toContain('already exists');
    });

    it('should return error for invalid password length', async () => {
      const userData = {
        email: 'test@example.com',
        password: '123', // Too short
        name: 'Test User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Password minimal 8 karakter');
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Create test user
      await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Password123',
          name: 'Test User',
          deviceId: 'test-device-123'
        });
    });

    it('should login with valid credentials', async () => {
      const loginData = {
        email: 'test@example.com',
        password: 'Password123',
        deviceId: 'test-device-123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user.email).toBe(loginData.email);
      expect(response.body.accessToken).toBeDefined();
    });

    it('should return error for invalid credentials', async () => {
      const loginData = {
        email: 'test@example.com',
        password: 'wrongpassword'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Email atau password salah');
    });
  });

  describe('GET /api/auth/profile', () => {
    let authToken: string;

    beforeEach(async () => {
      // Register and get token
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Password123',
          name: 'Test User',
          deviceId: 'test-device-123'
        });

      authToken = response.body.accessToken;
    });

    it('should get user profile with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user.email).toBe('test@example.com');
    });

    it('should return error without token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Authentication required');
    });
  });
});
