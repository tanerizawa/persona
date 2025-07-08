import { PrismaClient } from '@prisma/client';
declare class Database {
    private static instance;
    static getInstance(): PrismaClient;
    static connect(): Promise<void>;
    static disconnect(): Promise<void>;
}
export declare const prisma: PrismaClient<import(".prisma/client").Prisma.PrismaClientOptions, never, import("@prisma/client/runtime/library").DefaultArgs>;
export default Database;
