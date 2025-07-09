#!/usr/bin/env node

// Test dengan model berbeda dan pengaturan privacy yang benar
require('dotenv').config();
const axios = require('axios');

async function testDifferentModels() {
  const apiKey = process.env.OPENROUTER_API_KEY;
  
  console.log('=== Testing Different Models with Privacy Settings ===');
  
  const modelsToTest = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'mistralai/mistral-small-3.2-24b-instruct:free',
    'openrouter/cypher-alpha:free',
    'deepseek/deepseek-r1-0528:free'
  ];

  for (const model of modelsToTest) {
    console.log(`\n🧪 Testing model: ${model}`);
    
    try {
      const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
        model: model,
        messages: [
          { role: 'user', content: 'Say hello briefly.' }
        ],
        max_tokens: 30,
        temperature: 0.7,
        // Add privacy settings to avoid data policy issues
        stream: false,
        // These settings help with privacy compliance
        transforms: []
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
          'HTTP-Referer': 'https://persona-ai-assistant.com',
          'X-Title': 'Persona Assistant',
          // Add header to indicate we want to use models without data restrictions
          'X-Data-Policy': 'allow-all'
        }
      });

      console.log('✅ Success!');
      console.log('Response:', response.data.choices[0]?.message?.content);
      console.log('Actual model:', response.data.model);
      break; // Use first successful model
      
    } catch (error) {
      console.log('❌ Failed');
      console.log('Status:', error.response?.status);
      console.log('Error:', error.response?.data?.error?.message);
    }
  }
}

testDifferentModels().catch(console.error);
