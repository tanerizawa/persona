"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var supertest_1 = require("supertest");
var index_1 = require("../src/index");
var database_1 = require("../src/config/database");
describe('Authentication Endpoints', function () {
    beforeEach(function () { return __awaiter(void 0, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: 
                // Clean up test data
                return [4 /*yield*/, database_1.prisma.userSyncStatus.deleteMany()];
                case 1:
                    // Clean up test data
                    _a.sent();
                    return [4 /*yield*/, database_1.prisma.userBackup.deleteMany()];
                case 2:
                    _a.sent();
                    return [4 /*yield*/, database_1.prisma.user.deleteMany()];
                case 3:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    }); });
    afterAll(function () { return __awaiter(void 0, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, database_1.prisma.$disconnect()];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    }); });
    describe('POST /api/auth/register', function () {
        it('should register a new user successfully', function () { return __awaiter(void 0, void 0, void 0, function () {
            var userData, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        userData = {
                            email: 'test@example.com',
                            password: 'password123'
                        };
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/register')
                                .send(userData)
                                .expect(201)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(true);
                        expect(response.body.data.user.email).toBe(userData.email);
                        expect(response.body.data.token).toBeDefined();
                        expect(response.body.data.user.passwordHash).toBeUndefined();
                        return [2 /*return*/];
                }
            });
        }); });
        it('should return error for duplicate email', function () { return __awaiter(void 0, void 0, void 0, function () {
            var userData, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        userData = {
                            email: 'test@example.com',
                            password: 'password123'
                        };
                        // First registration
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/register')
                                .send(userData)
                                .expect(201)];
                    case 1:
                        // First registration
                        _a.sent();
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/register')
                                .send(userData)
                                .expect(409)];
                    case 2:
                        response = _a.sent();
                        expect(response.body.success).toBe(false);
                        expect(response.body.error).toContain('already exists');
                        return [2 /*return*/];
                }
            });
        }); });
        it('should return error for invalid password length', function () { return __awaiter(void 0, void 0, void 0, function () {
            var userData, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        userData = {
                            email: 'test@example.com',
                            password: '123' // Too short
                        };
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/register')
                                .send(userData)
                                .expect(400)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(false);
                        expect(response.body.error).toContain('at least 6 characters');
                        return [2 /*return*/];
                }
            });
        }); });
    });
    describe('POST /api/auth/login', function () {
        beforeEach(function () { return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: 
                    // Create test user
                    return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                            .post('/api/auth/register')
                            .send({
                            email: 'test@example.com',
                            password: 'password123'
                        })];
                    case 1:
                        // Create test user
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        }); });
        it('should login with valid credentials', function () { return __awaiter(void 0, void 0, void 0, function () {
            var loginData, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        loginData = {
                            email: 'test@example.com',
                            password: 'password123'
                        };
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/login')
                                .send(loginData)
                                .expect(200)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(true);
                        expect(response.body.data.user.email).toBe(loginData.email);
                        expect(response.body.data.token).toBeDefined();
                        return [2 /*return*/];
                }
            });
        }); });
        it('should return error for invalid credentials', function () { return __awaiter(void 0, void 0, void 0, function () {
            var loginData, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        loginData = {
                            email: 'test@example.com',
                            password: 'wrongpassword'
                        };
                        return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                                .post('/api/auth/login')
                                .send(loginData)
                                .expect(401)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(false);
                        expect(response.body.error).toContain('Invalid email or password');
                        return [2 /*return*/];
                }
            });
        }); });
    });
    describe('GET /api/auth/profile', function () {
        var authToken;
        beforeEach(function () { return __awaiter(void 0, void 0, void 0, function () {
            var response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                            .post('/api/auth/register')
                            .send({
                            email: 'test@example.com',
                            password: 'password123'
                        })];
                    case 1:
                        response = _a.sent();
                        authToken = response.body.data.token;
                        return [2 /*return*/];
                }
            });
        }); });
        it('should get user profile with valid token', function () { return __awaiter(void 0, void 0, void 0, function () {
            var response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                            .get('/api/auth/profile')
                            .set('Authorization', "Bearer ".concat(authToken))
                            .expect(200)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(true);
                        expect(response.body.data.user.email).toBe('test@example.com');
                        return [2 /*return*/];
                }
            });
        }); });
        it('should return error without token', function () { return __awaiter(void 0, void 0, void 0, function () {
            var response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, (0, supertest_1.default)(index_1.default)
                            .get('/api/auth/profile')
                            .expect(401)];
                    case 1:
                        response = _a.sent();
                        expect(response.body.success).toBe(false);
                        expect(response.body.error).toContain('Access token required');
                        return [2 /*return*/];
                }
            });
        }); });
    });
});
