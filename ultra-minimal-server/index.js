require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Middleware
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

// Auth middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Initialize database tables
async function initializeDatabase() {
  try {
    // Users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        last_sync TIMESTAMP DEFAULT NOW()
      )
    `);

    // Sync data table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sync_data (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        data_type VARCHAR(100) NOT NULL,
        entity_id VARCHAR(255) NOT NULL,
        data JSONB NOT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, data_type, entity_id)
      )
    `);

    // Sync metadata table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sync_metadata (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        device_id VARCHAR(255) NOT NULL,
        last_sync TIMESTAMP DEFAULT NOW(),
        sync_version INTEGER DEFAULT 1,
        UNIQUE(user_id, device_id)
      )
    `);

    console.log('✅ Database tables initialized');
  } catch (error) {
    console.error('❌ Database initialization error:', error);
  }
}

// Routes

// 1. Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'persona-sync-server'
  });
});

// 2. Register user
app.post('/register', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    
    const result = await pool.query(
      'INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, username',
      [username, passwordHash]
    );

    const token = jwt.sign(
      { id: result.rows[0].id, username: result.rows[0].username },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    res.status(201).json({
      message: 'User registered successfully',
      user: result.rows[0],
      token
    });
  } catch (error) {
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({ error: 'Username already exists' });
    }
    res.status(500).json({ error: 'Registration failed' });
  }
});

// 3. Login user
app.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    const result = await pool.query(
      'SELECT id, username, password_hash FROM users WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    res.json({
      message: 'Login successful',
      user: { id: user.id, username: user.username },
      token
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// 4. Push sync data
app.post('/sync/push', authenticateToken, async (req, res) => {
  try {
    const { data_type, items } = req.body;
    const userId = req.user.id;

    if (!data_type || !Array.isArray(items)) {
      return res.status(400).json({ error: 'data_type and items array required' });
    }

    if (items.length > parseInt(process.env.MAX_SYNC_ITEMS || '1000')) {
      return res.status(400).json({ error: 'Too many items to sync' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const results = [];
      for (const item of items) {
        const { entity_id, data } = item;
        
        const result = await client.query(`
          INSERT INTO sync_data (user_id, data_type, entity_id, data, updated_at)
          VALUES ($1, $2, $3, $4, NOW())
          ON CONFLICT (user_id, data_type, entity_id)
          DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()
          RETURNING id, updated_at
        `, [userId, data_type, entity_id, JSON.stringify(data)]);
        
        results.push({
          entity_id,
          synced: true,
          timestamp: result.rows[0].updated_at
        });
      }

      await client.query('COMMIT');
      
      res.json({
        message: 'Data pushed successfully',
        synced_count: results.length,
        results
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Push sync error:', error);
    res.status(500).json({ error: 'Sync push failed' });
  }
});

// 5. Pull sync data
app.get('/sync/pull/:data_type', authenticateToken, async (req, res) => {
  try {
    const { data_type } = req.params;
    const { since } = req.query;
    const userId = req.user.id;

    let query = `
      SELECT entity_id, data, updated_at
      FROM sync_data 
      WHERE user_id = $1 AND data_type = $2
    `;
    const params = [userId, data_type];

    if (since) {
      query += ` AND updated_at > $3`;
      params.push(since);
    }

    query += ` ORDER BY updated_at DESC LIMIT $${params.length + 1}`;
    params.push(parseInt(process.env.MAX_SYNC_ITEMS || '1000'));

    const result = await pool.query(query, params);

    res.json({
      data_type,
      items: result.rows.map(row => ({
        entity_id: row.entity_id,
        data: row.data,
        last_modified: row.updated_at
      })),
      total_count: result.rows.length,
      sync_timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Pull sync error:', error);
    res.status(500).json({ error: 'Sync pull failed' });
  }
});

// 6. Get sync status
app.get('/sync/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const result = await pool.query(`
      SELECT data_type, COUNT(*) as count, MAX(updated_at) as last_updated
      FROM sync_data 
      WHERE user_id = $1 
      GROUP BY data_type
    `, [userId]);

    const syncMeta = await pool.query(`
      SELECT device_id, last_sync, sync_version
      FROM sync_metadata 
      WHERE user_id = $1
    `, [userId]);

    res.json({
      user_id: userId,
      data_types: result.rows.reduce((acc, row) => {
        acc[row.data_type] = {
          count: parseInt(row.count),
          last_updated: row.last_updated
        };
        return acc;
      }, {}),
      devices: syncMeta.rows,
      server_time: new Date().toISOString()
    });
  } catch (error) {
    console.error('Sync status error:', error);
    res.status(500).json({ error: 'Failed to get sync status' });
  }
});

// 7. Update device sync metadata
app.post('/sync/device', authenticateToken, async (req, res) => {
  try {
    const { device_id } = req.body;
    const userId = req.user.id;

    if (!device_id) {
      return res.status(400).json({ error: 'device_id required' });
    }

    await pool.query(`
      INSERT INTO sync_metadata (user_id, device_id, last_sync, sync_version)
      VALUES ($1, $2, NOW(), 1)
      ON CONFLICT (user_id, device_id)
      DO UPDATE SET last_sync = NOW(), sync_version = sync_metadata.sync_version + 1
    `, [userId, device_id]);

    res.json({
      message: 'Device sync metadata updated',
      device_id,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Device sync error:', error);
    res.status(500).json({ error: 'Failed to update device sync' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
async function startServer() {
  await initializeDatabase();
  
  app.listen(PORT, () => {
    console.log(`🚀 Persona Sync Server running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  });
}

startServer().catch(console.error);

module.exports = app;
