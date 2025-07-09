#!/usr/bin/env node

// Test dengan model yang lebih umum tersedia
require('dotenv').config();
const axios = require('axios');

async function testBasicModels() {
  const apiKey = process.env.OPENROUTER_API_KEY;
  
  console.log('=== Testing Basic Available Models ===');
  
  // First, get the actual list of available models
  try {
    const modelsResponse = await axios.get('https://openrouter.ai/api/v1/models', {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'HTTP-Referer': 'https://persona-ai-assistant.com'
      }
    });
    
    // Find free models that are available
    const freeModels = modelsResponse.data.data.filter(model => {
      const isFree = model.pricing && (
        model.pricing.prompt === "0" || 
        model.pricing.prompt === 0 ||
        model.id.includes('free')
      );
      return isFree;
    });
    
    console.log(`Found ${freeModels.length} free models`);
    
    // Test the first few free models
    for (let i = 0; i < Math.min(5, freeModels.length); i++) {
      const model = freeModels[i];
      console.log(`\n🧪 Testing: ${model.id}`);
      
      try {
        const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
          model: model.id,
          messages: [
            { role: 'user', content: 'Hello!' }
          ],
          max_tokens: 20
        }, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`,
            'HTTP-Referer': 'https://persona-ai-assistant.com',
            'X-Title': 'Persona Assistant'
          }
        });

        console.log('✅ SUCCESS!');
        console.log('Model:', model.id);
        console.log('Response:', response.data.choices[0]?.message?.content);
        
        // Update .env with working model
        const fs = require('fs');
        let envContent = fs.readFileSync('.env', 'utf8');
        envContent = envContent.replace(
          /DEFAULT_MODEL=.*/,
          `DEFAULT_MODEL=${model.id}`
        );
        fs.writeFileSync('.env', envContent);
        console.log(`✅ Updated .env with working model: ${model.id}`);
        return; // Exit on first success
        
      } catch (error) {
        console.log('❌ Failed:', error.response?.data?.error?.message || error.message);
      }
    }
    
    console.log('\n❌ No working free models found');
    
  } catch (error) {
    console.error('❌ Failed to get models list:', error.response?.data || error.message);
  }
}

testBasicModels().catch(console.error);
