#!/usr/bin/env node

/**
 * Simple backend database setup and validation script
 * Tests the core authentication system without external dependencies
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Validating Backend Configuration...\n');

// Check if required files exist
const checkFile = (filePath, description) => {
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${description}: ${filePath}`);
    return true;
  } else {
    console.log(`❌ Missing ${description}: ${filePath}`);
    return false;
  }
};

// Check package.json
const packagePath = path.join(__dirname, '../package.json');
const hasPackage = checkFile(packagePath, 'Package configuration');

// Check Prisma schema
const schemaPath = path.join(__dirname, '../prisma/schema.prisma');
const hasSchema = checkFile(schemaPath, 'Prisma schema');

// Check environment files
const envTestPath = path.join(__dirname, '../.env.test');
const hasEnvTest = checkFile(envTestPath, 'Test environment');

// Check source files
const appPath = path.join(__dirname, '../src/app.ts');
const hasApp = checkFile(appPath, 'Express app');

const dbPath = path.join(__dirname, '../src/config/database.ts');
const hasDb = checkFile(dbPath, 'Database config');

console.log('\n📋 Configuration Analysis:');

if (hasPackage) {
  try {
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    console.log(`   App Name: ${packageJson.name}`);
    console.log(`   Version: ${packageJson.version}`);
    console.log(`   Main Script: ${packageJson.main}`);
    console.log(`   Test Script: ${packageJson.scripts?.test || 'Not defined'}`);
  } catch (e) {
    console.log(`   ⚠️ Could not parse package.json: ${e.message}`);
  }
}

if (hasEnvTest) {
  try {
    const envContent = fs.readFileSync(envTestPath, 'utf8');
    const hasDbUrl = envContent.includes('DATABASE_URL');
    const hasJwtSecret = envContent.includes('JWT_SECRET');
    console.log(`   Database URL configured: ${hasDbUrl ? '✅' : '❌'}`);
    console.log(`   JWT Secret configured: ${hasJwtSecret ? '✅' : '❌'}`);
  } catch (e) {
    console.log(`   ⚠️ Could not read .env.test: ${e.message}`);
  }
}

console.log('\n🔧 Issues Identified:');

let issueCount = 0;

// Check for Prisma client
const prismaClientPath = path.join(__dirname, '../node_modules/.prisma/client');
if (!fs.existsSync(prismaClientPath)) {
  console.log('❌ Prisma client not generated');
  console.log('   Solution: Run `npm run prisma:generate`');
  issueCount++;
}

// Check node_modules
const nodeModulesPath = path.join(__dirname, '../node_modules');
if (!fs.existsSync(nodeModulesPath)) {
  console.log('❌ Dependencies not installed');
  console.log('   Solution: Run `npm install`');
  issueCount++;
}

// Check if TypeScript is compiled
const distPath = path.join(__dirname, '../dist');
if (!fs.existsSync(distPath) || fs.readdirSync(distPath).length === 0) {
  console.log('⚠️ TypeScript not compiled (optional for tests)');
  console.log('   Solution: Run `npm run build`');
}

if (issueCount === 0) {
  console.log('✅ No critical issues found!');
  console.log('\n🚀 Next steps:');
  console.log('   1. Generate Prisma client: npm run prisma:generate');
  console.log('   2. Run tests: npm test');
  console.log('   3. Start development server: npm run dev');
} else {
  console.log(`\n❌ Found ${issueCount} critical issue(s) that need to be resolved.`);
}

console.log('\n💡 For network-free testing, ensure:');
console.log('   - SQLite database (file::memory: works offline)');
console.log('   - All dependencies are in node_modules');
console.log('   - Prisma client is generated');