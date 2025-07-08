import dotenv from 'dotenv';

// Load environment variables first
dotenv.config();

// Start the app
import('./app').then(() => {
  console.log('🚀 Persona AI Backend started successfully');
}).catch((error) => {
  console.error('❌ Failed to start backend:', error);
  process.exit(1);
});
