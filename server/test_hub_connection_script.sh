#!/bin/bash

# Project Corridor - Hub Connection Test Script
# This script tests the full authentication and hub connection flow

set -e  # Exit on any error

# Configuration
API_BASE_URL="http://localhost:8080"
SHARD_MANAGER_URL="http://localhost:8081"
USERNAME="admin"
PASSWORD="nimda"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Project Corridor Hub Connection Test ===${NC}"
echo

# Function to make HTTP requests with better error handling
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local headers=$4
    
    echo -e "${YELLOW}Making ${method} request to: ${url}${NC}"
    
    if [ -n "$headers" ]; then
        if [ -n "$data" ]; then
            curl -s -X "${method}" "${url}" \
                -H "Content-Type: application/json" \
                -H "${headers}" \
                -d "${data}" \
                -w "\nHTTP Status: %{http_code}\n"
        else
            curl -s -X "${method}" "${url}" \
                -H "Content-Type: application/json" \
                -H "${headers}" \
                -w "\nHTTP Status: %{http_code}\n"
        fi
    else
        if [ -n "$data" ]; then
            curl -s -X "${method}" "${url}" \
                -H "Content-Type: application/json" \
                -d "${data}" \
                -w "\nHTTP Status: %{http_code}\n"
        else
            curl -s -X "${method}" "${url}" \
                -H "Content-Type: application/json" \
                -w "\nHTTP Status: %{http_code}\n"
        fi
    fi
}

# Step 1: Check if services are running
echo -e "${BLUE}Step 1: Checking service health${NC}"
echo "Checking Main API..."
if ! curl -s -f "${API_BASE_URL}/health" > /dev/null; then
    echo -e "${RED}❌ Main API is not responding at ${API_BASE_URL}${NC}"
    echo "Make sure the services are running: docker-compose up"
    exit 1
fi
echo -e "${GREEN}✅ Main API is healthy${NC}"

echo "Checking Shard Manager..."
if ! curl -s -f "${SHARD_MANAGER_URL}/health" > /dev/null; then
    echo -e "${RED}❌ Shard Manager is not responding at ${SHARD_MANAGER_URL}${NC}"
    echo "Make sure the shard manager is running"
    exit 1
fi
echo -e "${GREEN}✅ Shard Manager is healthy${NC}"
echo

# Step 2: Authenticate
echo -e "${BLUE}Step 2: Authenticating to Main API${NC}"
LOGIN_DATA="{\"user\":\"${USERNAME}\",\"secret\":\"${PASSWORD}\"}"
LOGIN_RESPONSE=$(make_request "POST" "${API_BASE_URL}/api/v0/auth/login" "${LOGIN_DATA}")

echo -e "${GREEN}Login Response:${NC}"
echo "${LOGIN_RESPONSE}"
echo

# Extract access token from response
ACCESS_TOKEN=$(echo "${LOGIN_RESPONSE}" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "${ACCESS_TOKEN}" ]; then
    echo -e "${RED}❌ Failed to extract access token from login response${NC}"
    echo "Response was: ${LOGIN_RESPONSE}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully authenticated${NC}"
echo -e "${YELLOW}Access Token: ${ACCESS_TOKEN:0:20}...${NC}"
echo

# Step 3: Get user info (verify token works)
echo -e "${BLUE}Step 3: Getting user information${NC}"
USER_INFO_RESPONSE=$(make_request "GET" "${API_BASE_URL}/api/v0/auth/me" "" "Authorization: Bearer ${ACCESS_TOKEN}")

echo -e "${GREEN}User Info Response:${NC}"
echo "${USER_INFO_RESPONSE}"
echo

# Step 4: Request hub connection
echo -e "${BLUE}Step 4: Requesting hub connection${NC}"
HUB_RESPONSE=$(make_request "GET" "${API_BASE_URL}/api/v0/game/hub/connection" "" "Authorization: Bearer ${ACCESS_TOKEN}")

echo -e "${GREEN}Hub Connection Response:${NC}"
echo "${HUB_RESPONSE}"
echo

# Step 5: Parse hub connection details
echo -e "${BLUE}Step 5: Parsing hub connection details${NC}"

# Extract host and port from response
HUB_HOST=$(echo "${HUB_RESPONSE}" | grep -o '"host":"[^"]*' | cut -d'"' -f4)
HUB_PORT=$(echo "${HUB_RESPONSE}" | grep -o '"port":[0-9]*' | cut -d':' -f2)
SHARD_ID=$(echo "${HUB_RESPONSE}" | grep -o '"shard_id":"[^"]*' | cut -d'"' -f4)

if [ -n "${HUB_HOST}" ] && [ -n "${HUB_PORT}" ]; then
    echo -e "${GREEN}✅ Hub connection details extracted:${NC}"
    echo -e "${YELLOW}  Host: ${HUB_HOST}${NC}"
    echo -e "${YELLOW}  Port: ${HUB_PORT}${NC}"
    echo -e "${YELLOW}  Shard ID: ${SHARD_ID}${NC}"
    echo
    
    # Step 6: Test direct connection to hub (ping test)
    echo -e "${BLUE}Step 6: Testing hub server connectivity${NC}"
    
    # Try to connect to the hub port (this will fail if no Godot server is running)
    if timeout 3 bash -c "</dev/tcp/${HUB_HOST}/${HUB_PORT}" 2>/dev/null; then
        echo -e "${GREEN}✅ Hub server is accepting connections on ${HUB_HOST}:${HUB_PORT}${NC}"
    else
        echo -e "${YELLOW}⚠️  Hub server port is not responding (expected if Godot server not running)${NC}"
        echo -e "${YELLOW}   This is normal if you haven't set up the Godot server yet${NC}"
    fi
    
else
    echo -e "${RED}❌ Failed to extract hub connection details${NC}"
    echo "Response was: ${HUB_RESPONSE}"
    exit 1
fi

# Step 7: List all shards (admin view)
echo -e "${BLUE}Step 7: Listing all shards${NC}"
SHARDS_RESPONSE=$(make_request "GET" "${API_BASE_URL}/api/v0/game/shards" "" "Authorization: Bearer ${ACCESS_TOKEN}")

echo -e "${GREEN}All Shards Response:${NC}"
echo "${SHARDS_RESPONSE}"
echo

# Step 8: Get shard manager stats
echo -e "${BLUE}Step 8: Getting shard manager statistics${NC}"
STATS_RESPONSE=$(make_request "GET" "${SHARD_MANAGER_URL}/api/v0/shards/stats/summary")

echo -e "${GREEN}Shard Manager Stats:${NC}"
echo "${STATS_RESPONSE}"
echo

# Step 9: Direct shard manager hub request
echo -e "${BLUE}Step 9: Direct shard manager hub request${NC}"
DIRECT_HUB_RESPONSE=$(make_request "GET" "${SHARD_MANAGER_URL}/api/v0/shards/hub")

echo -e "${GREEN}Direct Hub Response:${NC}"
echo "${DIRECT_HUB_RESPONSE}"
echo

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✅ Authentication: SUCCESS${NC}"
echo -e "${GREEN}✅ Hub Connection Request: SUCCESS${NC}"
echo -e "${GREEN}✅ Connection Details: ${HUB_HOST}:${HUB_PORT}${NC}"

if [ -n "${SHARD_ID}" ]; then
    echo -e "${GREEN}✅ Hub Shard ID: ${SHARD_ID}${NC}"
fi

echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Set up a Godot server to run on ${HUB_HOST}:${HUB_PORT}"
echo "2. Configure the Godot server to connect to the shard manager"
echo "3. Test client connection to the Godot server"
echo
echo -e "${BLUE}Example Godot client connection:${NC}"
echo "multiplayer.create_client(\"${HUB_HOST}\", ${HUB_PORT})"