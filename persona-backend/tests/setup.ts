import Database from '../src/config/database';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
// Jest globals are automatically available in test files

// Load test environment variables
dotenv.config({ path: '.env.test' });

// Create a new Prisma client for tests
const prisma = new PrismaClient();

beforeAll(async () => {
  // Ensure we're using the test database
  process.env.NODE_ENV = 'test';
  
  try {
    // Run migrations on the test database
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    
    // Connect to the database
    await Database.connect();
    console.log('✅ Test database connected successfully');
  } catch (error) {
    console.error('❌ Test setup failed:', error);
    throw error;
  }
});

beforeEach(async () => {
  // Clean up test data before each test
  const tablenames = await prisma.$queryRaw<Array<{ name: string }>>`
    SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_prisma_%'
  `;
  
  // Clean all tables except migrations
  for (const { name } of tablenames.filter(t => t.name !== '_prisma_migrations')) {
    await prisma.$executeRawUnsafe(`DELETE FROM "${name}"`);
  }
});

afterAll(async () => {
  await prisma.$disconnect();
  await Database.disconnect();
});
