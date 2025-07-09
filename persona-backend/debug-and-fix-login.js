#!/usr/bin/env node

/**
 * LOGIN DEBUG & FIX SCRIPT
 * 
 * Script ini akan:
 * 1. Debug akun yang bermasalah
 * 2. Reset account lock dan failed attempts
 * 3. Verifikasi password hash
 * 4. Reset session yang invalid
 * 5. Test login ulang
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const path = require('path');

// Setup Prisma dengan path yang benar
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${path.join(__dirname, 'prisma', 'dev.db')}`
    }
  }
});

class LoginDebugger {
  constructor() {
    this.SALT_ROUNDS = 12;
  }

  async debugUser(email) {
    console.log(`\n🔍 DEBUGGING USER: ${email}\n`);
    
    try {
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() },
        include: {
          sessions: {
            orderBy: { createdAt: 'desc' },
            take: 5
          }
        }
      });

      if (!user) {
        console.log('❌ User not found!');
        return null;
      }

      console.log('👤 USER INFO:');
      console.log(`   ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Display Name: ${user.displayName}`);
      console.log(`   Account Status: ${user.accountStatus}`);
      console.log(`   Email Verified: ${user.emailVerified}`);
      console.log(`   Failed Login Attempts: ${user.failedLoginAttempts}`);
      console.log(`   Locked Until: ${user.lockedUntil}`);
      console.log(`   Last Login: ${user.lastLogin}`);
      console.log(`   Created: ${user.createdAt}`);
      console.log(`   Updated: ${user.updatedAt}`);

      console.log('\n🔐 PASSWORD HASH:');
      console.log(`   Hash: ${user.passwordHash.substring(0, 20)}...`);
      console.log(`   Hash Length: ${user.passwordHash.length}`);

      console.log('\n📱 RECENT SESSIONS:');
      user.sessions.forEach((session, index) => {
        console.log(`   Session ${index + 1}:`);
        console.log(`     Device ID: ${session.deviceId}`);
        console.log(`     Is Active: ${session.isActive}`);
        console.log(`     Expires: ${session.expiresAt}`);
        console.log(`     Last Active: ${session.lastActive}`);
        console.log(`     Created: ${session.createdAt}`);
      });

      return user;

    } catch (error) {
      console.error('❌ Error debugging user:', error);
      return null;
    }
  }

  async fixAccountLock(email) {
    console.log(`\n🔧 FIXING ACCOUNT LOCK: ${email}\n`);

    try {
      const result = await prisma.user.update({
        where: { email: email.toLowerCase() },
        data: {
          failedLoginAttempts: 0,
          lockedUntil: null,
          accountStatus: 'active',
          emailVerified: true,
          lastLogin: new Date()
        }
      });

      console.log('✅ Account lock fixed successfully!');
      console.log(`   Failed attempts reset to: ${result.failedLoginAttempts}`);
      console.log(`   Lock status: ${result.lockedUntil ? 'LOCKED' : 'UNLOCKED'}`);
      console.log(`   Account status: ${result.accountStatus}`);

      return result;

    } catch (error) {
      console.error('❌ Error fixing account lock:', error);
      return null;
    }
  }

  async verifyPassword(email, password) {
    console.log(`\n🔐 VERIFYING PASSWORD: ${email}\n`);

    try {
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() }
      });

      if (!user) {
        console.log('❌ User not found!');
        return false;
      }

      const isValid = await bcrypt.compare(password, user.passwordHash);
      console.log(`Password verification: ${isValid ? '✅ VALID' : '❌ INVALID'}`);

      if (!isValid) {
        console.log('\n🔧 Would you like to reset the password? (manual step)');
        console.log('If yes, run this script with --reset-password flag');
      }

      return isValid;

    } catch (error) {
      console.error('❌ Error verifying password:', error);
      return false;
    }
  }

  async resetPassword(email, newPassword) {
    console.log(`\n🔄 RESETTING PASSWORD: ${email}\n`);

    try {
      const passwordHash = await bcrypt.hash(newPassword, this.SALT_ROUNDS);
      
      const result = await prisma.user.update({
        where: { email: email.toLowerCase() },
        data: {
          passwordHash,
          failedLoginAttempts: 0,
          lockedUntil: null,
          accountStatus: 'active',
          emailVerified: true
        }
      });

      console.log('✅ Password reset successfully!');
      console.log(`   New hash length: ${result.passwordHash.length}`);

      return result;

    } catch (error) {
      console.error('❌ Error resetting password:', error);
      return null;
    }
  }

  async cleanupSessions(email) {
    console.log(`\n🧹 CLEANING UP SESSIONS: ${email}\n`);

    try {
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() }
      });

      if (!user) {
        console.log('❌ User not found!');
        return false;
      }

      // Deactivate all sessions
      const result = await prisma.userSession.updateMany({
        where: { userId: user.id },
        data: { isActive: false }
      });

      console.log(`✅ Cleaned up ${result.count} sessions`);

      return true;

    } catch (error) {
      console.error('❌ Error cleaning up sessions:', error);
      return false;
    }
  }

  async fullFix(email, password = null) {
    console.log(`\n🚀 FULL FIX FOR: ${email}\n`);

    // 1. Debug current state
    await this.debugUser(email);

    // 2. Fix account lock
    await this.fixAccountLock(email);

    // 3. Clean up sessions
    await this.cleanupSessions(email);

    // 4. Verify password (or reset if provided)
    if (password) {
      const isValid = await this.verifyPassword(email, password);
      if (!isValid) {
        console.log('\n⚠️  Password verification failed!');
        console.log('Consider running with --reset-password if you want to set a new password');
      }
    }

    console.log('\n✅ FULL FIX COMPLETED!');
    console.log('You can now try logging in again.');
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const loginDebugger = new LoginDebugger();

  if (args.length === 0) {
    console.log(`
🔧 LOGIN DEBUG & FIX SCRIPT

Usage:
  node debug-and-fix-login.js <email>                    # Debug user
  node debug-and-fix-login.js <email> --verify <password> # Verify password
  node debug-and-fix-login.js <email> --reset <password>  # Reset password
  node debug-and-fix-login.js <email> --full-fix         # Complete fix
  node debug-and-fix-login.js <email> --full-fix <password> # Full fix + verify

Examples:
  node debug-and-fix-login.js user@example.com --full-fix
  node debug-and-fix-login.js user@example.com --verify mypassword
  node debug-and-fix-login.js user@example.com --reset newpassword123
`);
    process.exit(0);
  }

  const email = args[0];
  const action = args[1];
  const password = args[2];

  try {
    if (action === '--debug' || !action) {
      await loginDebugger.debugUser(email);
    }
    else if (action === '--verify' && password) {
      await loginDebugger.verifyPassword(email, password);
    }
    else if (action === '--reset' && password) {
      await loginDebugger.resetPassword(email, password);
    }
    else if (action === '--full-fix') {
      await loginDebugger.fullFix(email, password);
    }
    else if (action === '--cleanup') {
      await loginDebugger.cleanupSessions(email);
    }
    else if (action === '--unlock') {
      await loginDebugger.fixAccountLock(email);
    }
    else {
      console.log('❌ Invalid action. Use --help for usage info.');
    }

  } catch (error) {
    console.error('❌ Script error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);
