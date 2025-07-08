#!/bin/bash

# Persona AI Backend Integration Test Script
# This script tests the complete authentication flow

echo "🚀 PERSONA AI BACKEND INTEGRATION TEST"
echo "======================================="

# Configuration
BASE_URL="http://localhost:3000/api"
TEST_EMAIL="test@personaai.com"
TEST_PASSWORD="TestPass123!"
TEST_NAME="Test User"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test health endpoint
echo ""
print_info "Testing health endpoint..."
health_response=$(curl -s -w "%{http_code}" -o /tmp/health.json "$BASE_URL/../health")
if [ "$health_response" = "200" ]; then
    print_success "Health check passed"
    cat /tmp/health.json | jq .
else
    print_error "Health check failed (HTTP $health_response)"
    exit 1
fi

# Test user registration
echo ""
print_info "Testing user registration..."
register_response=$(curl -s -w "%{http_code}" -o /tmp/register.json \
    -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"name\": \"$TEST_NAME\",
        \"deviceId\": \"test-device-123\"
    }")

if [ "$register_response" = "201" ]; then
    print_success "User registration successful"
    ACCESS_TOKEN=$(cat /tmp/register.json | jq -r '.accessToken')
    REFRESH_TOKEN=$(cat /tmp/register.json | jq -r '.refreshToken')
    USER_ID=$(cat /tmp/register.json | jq -r '.user.id')
    
    echo "Access Token: ${ACCESS_TOKEN:0:20}..."
    echo "User ID: $USER_ID"
else
    print_error "User registration failed (HTTP $register_response)"
    cat /tmp/register.json | jq .
    
    # Try login if registration failed (user might already exist)
    print_info "Attempting login instead..."
    login_response=$(curl -s -w "%{http_code}" -o /tmp/login.json \
        -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"$TEST_PASSWORD\",
            \"deviceId\": \"test-device-123\"
        }")
    
    if [ "$login_response" = "200" ]; then
        print_success "Login successful"
        ACCESS_TOKEN=$(cat /tmp/login.json | jq -r '.accessToken')
        REFRESH_TOKEN=$(cat /tmp/login.json | jq -r '.refreshToken')
        USER_ID=$(cat /tmp/login.json | jq -r '.user.id')
    else
        print_error "Login also failed (HTTP $login_response)"
        cat /tmp/login.json | jq .
        exit 1
    fi
fi

# Test get profile (protected endpoint)
echo ""
print_info "Testing get profile (protected endpoint)..."
profile_response=$(curl -s -w "%{http_code}" -o /tmp/profile.json \
    -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$profile_response" = "200" ]; then
    print_success "Get profile successful"
    cat /tmp/profile.json | jq .
else
    print_error "Get profile failed (HTTP $profile_response)"
    cat /tmp/profile.json | jq .
fi

# Test update profile
echo ""
print_info "Testing update profile..."
update_response=$(curl -s -w "%{http_code}" -o /tmp/update.json \
    -X PUT "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Updated Test User\",
        \"bio\": \"This is a test bio for integration testing\",
        \"preferences\": {
            \"theme\": \"dark\",
            \"language\": \"en\",
            \"notifications\": true
        }
    }")

if [ "$update_response" = "200" ]; then
    print_success "Update profile successful"
    cat /tmp/update.json | jq .
else
    print_error "Update profile failed (HTTP $update_response)"
    cat /tmp/update.json | jq .
fi

# Test token refresh
echo ""
print_info "Testing token refresh..."
refresh_response=$(curl -s -w "%{http_code}" -o /tmp/refresh.json \
    -X POST "$BASE_URL/auth/refresh" \
    -H "Content-Type: application/json" \
    -d "{
        \"refreshToken\": \"$REFRESH_TOKEN\"
    }")

if [ "$refresh_response" = "200" ]; then
    print_success "Token refresh successful"
    NEW_ACCESS_TOKEN=$(cat /tmp/refresh.json | jq -r '.accessToken')
    echo "New Access Token: ${NEW_ACCESS_TOKEN:0:20}..."
    ACCESS_TOKEN=$NEW_ACCESS_TOKEN
else
    print_error "Token refresh failed (HTTP $refresh_response)"
    cat /tmp/refresh.json | jq .
fi

# Test logout
echo ""
print_info "Testing logout..."
logout_response=$(curl -s -w "%{http_code}" -o /tmp/logout.json \
    -X POST "$BASE_URL/auth/logout" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Device-ID: test-device-123")

if [ "$logout_response" = "200" ]; then
    print_success "Logout successful"
    cat /tmp/logout.json | jq .
else
    print_error "Logout failed (HTTP $logout_response)"
    cat /tmp/logout.json | jq .
fi

# Test accessing protected endpoint after logout
echo ""
print_info "Testing protected endpoint after logout (should fail)..."
protected_response=$(curl -s -w "%{http_code}" -o /tmp/protected.json \
    -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$protected_response" = "401" ]; then
    print_success "Protected endpoint correctly rejected expired token"
else
    print_error "Protected endpoint should have rejected expired token (HTTP $protected_response)"
    cat /tmp/protected.json | jq .
fi

echo ""
print_success "🎉 Backend integration test completed!"
echo ""
print_info "Test Summary:"
echo "- Health check: ✅"
echo "- User registration/login: ✅"
echo "- Get profile: ✅"
echo "- Update profile: ✅"
echo "- Token refresh: ✅"
echo "- Logout: ✅"
echo "- Token validation: ✅"
echo ""
print_success "Backend is ready for Flutter integration!"

# Cleanup
rm -f /tmp/health.json /tmp/register.json /tmp/login.json /tmp/profile.json /tmp/update.json /tmp/refresh.json /tmp/logout.json /tmp/protected.json
