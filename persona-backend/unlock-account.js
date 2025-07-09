// Script to unlock user account
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function unlockAccount(email) {
  try {
    const user = await prisma.user.update({
      where: { email: email },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
        accountStatus: 'active'
      }
    });
    
    console.log(`✅ Account unlocked for: ${email}`);
    console.log(`User ID: ${user.id}`);
    console.log(`Status: ${user.account_status}`);
    console.log(`Failed attempts reset to: ${user.failed_login_attempts}`);
    
  } catch (error) {
    console.error('❌ Error unlocking account:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Get email from command line or use default
const email = process.argv[2] || 'x@mail.com';
console.log(`🔧 Unlocking account for: ${email}`);

unlockAccount(email);
