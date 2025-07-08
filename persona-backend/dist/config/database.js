"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
const client_1 = require("@prisma/client");
class Database {
    static getInstance() {
        if (!Database.instance) {
            Database.instance = new client_1.PrismaClient({
                log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
            });
        }
        return Database.instance;
    }
    static async connect() {
        try {
            await Database.getInstance().$connect();
            console.log('✅ Database connected successfully');
        }
        catch (error) {
            console.error('❌ Database connection failed:', error);
            process.exit(1);
        }
    }
    static async disconnect() {
        try {
            await Database.getInstance().$disconnect();
            console.log('✅ Database disconnected successfully');
        }
        catch (error) {
            console.error('❌ Database disconnection failed:', error);
        }
    }
}
exports.prisma = Database.getInstance();
exports.default = Database;
//# sourceMappingURL=database.js.map