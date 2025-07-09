import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function createTestUser() {
  try {
    console.log('🔄 Creating test user...');
    
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: 'x@mail.com' }
    });

    if (existingUser) {
      console.log('✅ Test user already exists!');
      console.log('User ID:', existingUser.id);
      console.log('Email:', existingUser.email);
      console.log('Display Name:', existingUser.displayName);
      return;
    }

    // Hash the password
    const passwordHash = await bcrypt.hash('Tan12089', 12);

    // Create test user
    const user = await prisma.user.create({
      data: {
        email: 'x@mail.com',
        passwordHash,
        displayName: 'Test User',
        accountStatus: 'active', // Make it active so no verification needed
        emailVerified: true,
        failedLoginAttempts: 0
      }
    });

    console.log('✅ Test user created successfully!');
    console.log('Email: x@mail.com');
    console.log('Password: Tan12089');
    console.log('User ID:', user.id);
    console.log('Display Name:', user.displayName);

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createTestUser();
