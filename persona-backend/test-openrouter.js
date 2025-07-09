#!/usr/bin/env node

// Test script untuk OpenRouter API
require('dotenv').config();
const axios = require('axios');

async function testOpenRouterAPI() {
  const apiKey = process.env.OPENROUTER_API_KEY;
  
  console.log('=== OpenRouter API Test ===');
  console.log('API Key length:', apiKey ? apiKey.length : 'NOT SET');
  console.log('API Key prefix:', apiKey ? apiKey.substring(0, 12) + '...' : 'NOT SET');
  console.log('Base URL:', process.env.OPENROUTER_BASE_URL);
  console.log('Default Model:', process.env.DEFAULT_MODEL);
  console.log('');

  if (!apiKey) {
    console.error('❌ ERROR: OPENROUTER_API_KEY not found in environment');
    return;
  }

  console.log('🔍 Testing API key validation...');
  
  try {
    // Test 1: Get available models
    console.log('\n📋 Test 1: Getting available models...');
    const modelsResponse = await axios.get('https://openrouter.ai/api/v1/models', {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'HTTP-Referer': 'https://persona-ai-assistant.com',
        'X-Title': 'Persona Assistant'
      }
    });
    
    console.log('✅ Models endpoint successful');
    console.log('Available models count:', modelsResponse.data.data?.length || 0);
    
    // Show some free models
    const freeModels = modelsResponse.data.data?.filter(model => 
      model.id.includes('free') || model.pricing?.prompt === "0"
    ).slice(0, 5);
    
    console.log('\n🆓 Some free models available:');
    freeModels?.forEach(model => {
      console.log(`  - ${model.id}`);
    });

  } catch (error) {
    console.error('❌ Models endpoint failed:');
    console.error('Status:', error.response?.status);
    console.error('Data:', JSON.stringify(error.response?.data, null, 2));
  }

  // Test 2: Simple chat completion
  console.log('\n💬 Test 2: Testing chat completion...');
  
  try {
    const chatResponse = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
      model: process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free',
      messages: [
        { role: 'user', content: 'Hello, this is a test message. Please respond briefly.' }
      ],
      max_tokens: 50,
      temperature: 0.7
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'HTTP-Referer': 'https://persona-ai-assistant.com',
        'X-Title': 'Persona Assistant'
      }
    });

    console.log('✅ Chat completion successful');
    console.log('Response:', chatResponse.data.choices[0]?.message?.content);
    console.log('Model used:', chatResponse.data.model);
    
  } catch (error) {
    console.error('❌ Chat completion failed:');
    console.error('Status:', error.response?.status);
    console.error('Data:', JSON.stringify(error.response?.data, null, 2));
    
    if (error.response?.status === 401) {
      console.log('\n🔧 Troubleshooting 401 error:');
      console.log('1. Check if API key is valid');
      console.log('2. Check if API key has correct permissions');
      console.log('3. Check if account has sufficient credits');
    }
    
    if (error.response?.status === 404) {
      console.log('\n🔧 Troubleshooting 404 error:');
      console.log('1. Check if model name is correct');
      console.log('2. Check if model is available for your account');
      console.log('3. Try a different model (e.g., meta-llama/llama-3.1-8b-instruct:free)');
    }
  }

  // Test 3: Account info
  console.log('\n👤 Test 3: Getting account information...');
  
  try {
    const accountResponse = await axios.get('https://openrouter.ai/api/v1/auth/key', {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'HTTP-Referer': 'https://persona-ai-assistant.com',
        'X-Title': 'Persona Assistant'
      }
    });

    console.log('✅ Account info retrieved');
    console.log('Account data:', JSON.stringify(accountResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Account info failed:');
    console.error('Status:', error.response?.status);
    console.error('Data:', JSON.stringify(error.response?.data, null, 2));
  }
}

// Run the test
testOpenRouterAPI().catch(console.error);
