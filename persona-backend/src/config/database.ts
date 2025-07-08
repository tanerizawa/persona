import { PrismaClient } from '@prisma/client';

class Database {
  private static instance: PrismaClient;

  public static getInstance(): PrismaClient {
    if (!Database.instance) {
      Database.instance = new PrismaClient({
        log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
      });
    }
    return Database.instance;
  }

  public static async connect(): Promise<void> {
    try {
      await Database.getInstance().$connect();
      console.log('✅ Database connected successfully');
    } catch (error) {
      console.error('❌ Database connection failed:', error);
      process.exit(1);
    }
  }

  public static async disconnect(): Promise<void> {
    try {
      await Database.getInstance().$disconnect();
      console.log('✅ Database disconnected successfully');
    } catch (error) {
      console.error('❌ Database disconnection failed:', error);
    }
  }
}

export const prisma = Database.getInstance();
export default Database;
