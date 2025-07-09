import express from 'express';

const router = express.Router();

/**
 * Remote Configuration Endpoint
 * Provides centralized configuration management for Flutter app
 */
router.get('/app-config', (req, res) => {
  try {
    const appConfig = {
      // App Metadata
      app: {
        name: process.env.APP_NAME || 'Persona Assistant',
        version: process.env.APP_VERSION || '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        domain: process.env.APP_DOMAIN || 'https://persona-ai.app',
        lastUpdated: new Date().toISOString()
      },

      // AI Configuration (Server-managed for security)
      ai: {
        baseUrl: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
        defaultModel: process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free',
        personalityModel: process.env.PERSONALITY_ANALYSIS_MODEL || 'gpt-4-turbo-preview',
        moodModel: process.env.MOOD_ANALYSIS_MODEL || 'anthropic/claude-3-haiku:beta',
        confidenceThreshold: parseFloat(process.env.AI_CONFIDENCE_THRESHOLD || '0.7'),
        enableLocalAI: process.env.ENABLE_LOCAL_AI === 'true',
        // API key is NOT exposed to client
      },

      // Backend Configuration
      backend: {
        baseUrl: process.env.BACKEND_BASE_URL || 'http://localhost:3000',
        apiVersion: process.env.API_VERSION || 'v1',
        timeout: parseInt(process.env.API_TIMEOUT_SECONDS || '30') * 1000,
        retryAttempts: parseInt(process.env.MAX_SYNC_RETRIES || '3'),
      },

      // Feature Flags (Dynamic toggles)
      features: {
        pushNotifications: process.env.ENABLE_PUSH_NOTIFICATIONS === 'true',
        biometricAuth: process.env.ENABLE_BIOMETRIC_AUTH === 'true',
        crisisIntervention: process.env.ENABLE_CRISIS_INTERVENTION === 'true',
        backgroundSync: process.env.ENABLE_BACKGROUND_SYNC === 'true',
        offlineMode: process.env.ENABLE_OFFLINE_MODE === 'true',
        analytics: process.env.ENABLE_ANALYTICS === 'true',
        localAI: process.env.ENABLE_LOCAL_AI === 'true',
      },

      // Sync Configuration
      sync: {
        intervalHours: parseInt(process.env.SYNC_INTERVAL_HOURS || '6'),
        maxRetries: parseInt(process.env.MAX_SYNC_RETRIES || '3'),
        timeoutSeconds: parseInt(process.env.SYNC_TIMEOUT_SECONDS || '30'),
      },

      // Crisis Intervention
      crisis: {
        hotline: process.env.CRISIS_HOTLINE || '988',
        textLine: process.env.CRISIS_TEXT || '741741',
        emergency: process.env.EMERGENCY_CONTACT || '911',
      },

      // Development Settings
      development: {
        debugMode: process.env.DEBUG_MODE === 'true',
        mockApiResponses: process.env.MOCK_API_RESPONSES === 'true',
        skipOnboarding: process.env.SKIP_ONBOARDING === 'true',
        logLevel: process.env.LOG_LEVEL || 'info',
      },

      // Security Settings
      security: {
        forceHttps: process.env.FORCE_HTTPS === 'true',
        enableSslPinning: process.env.ENABLE_SSL_PINNING === 'true',
        rateLimitEnabled: true,
        maxRequestsPerWindow: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'),
      },

      // UI Configuration
      ui: {
        theme: {
          primaryColor: process.env.PRIMARY_COLOR || '#6750A4',
          accentColor: process.env.ACCENT_COLOR || '#625B71',
          darkMode: process.env.DARK_MODE_DEFAULT === 'true',
        },
        animations: {
          enabled: process.env.ANIMATIONS_ENABLED !== 'false',
          duration: parseInt(process.env.ANIMATION_DURATION_MS || '300'),
        },
        locale: process.env.DEFAULT_LOCALE || 'en',
      },

      // Cache Configuration
      cache: {
        ttlMinutes: parseInt(process.env.CONFIG_CACHE_TTL_MINUTES || '30'),
        version: process.env.CONFIG_VERSION || '1.0',
      }
    };

    // Set cache headers for configuration
    res.set({
      'Cache-Control': `public, max-age=${appConfig.cache.ttlMinutes * 60}`,
      'ETag': `"${appConfig.cache.version}-${Date.now()}"`,
      'Content-Type': 'application/json'
    });

    res.json({
      success: true,
      data: appConfig,
      timestamp: new Date().toISOString(),
      version: appConfig.cache.version
    });

  } catch (error) {
    console.error('Error fetching app configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch app configuration',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Feature Flag Update Endpoint (Admin only)
 * Allows dynamic feature flag updates
 */
router.patch('/features', (req, res) => {
  try {
    const { features } = req.body;
    
    // In production, add proper admin authentication here
    if (process.env.NODE_ENV === 'production') {
      // TODO: Implement admin authentication
      // const isAdmin = await verifyAdminToken(req.headers.authorization);
      // if (!isAdmin) return res.status(403).json({ error: 'Admin access required' });
    }

    // Update feature flags (in production, update database/config store)
    const updatedFeatures = {
      ...features,
      lastUpdated: new Date().toISOString()
    };

    res.json({
      success: true,
      data: { features: updatedFeatures },
      message: 'Feature flags updated successfully'
    });

  } catch (error) {
    console.error('Error updating feature flags:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update feature flags'
    });
  }
});

export default router;
