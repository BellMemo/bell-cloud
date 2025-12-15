#!/bin/bash

# Configuration
URL="http://localhost:5244"
USER="admin"
PASSWORD=""

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Bell Cloud initialization...${NC}"

# 1. Check if container is running
if ! docker ps | grep -q bell-cloud; then
    echo "Container 'bell-cloud' is not running. Starting it..."
    docker compose up -d
    echo "Waiting for service to be ready (may take a few seconds)..."
    sleep 5
else
    echo "Container 'bell-cloud' is running."
fi

# 2. Wait for API to be responsive
MAX_RETRIES=30
count=0
echo -n "Waiting for Alist to accept connections..."
until curl -s "$URL" > /dev/null; do
    echo -n "."
    sleep 1
    count=$((count+1))
    if [ $count -ge $MAX_RETRIES ]; then
        echo "Timed out waiting for Alist."
        exit 1
    fi
done
echo " Ready!"

# 3. Set/Get Password
if [ -z "$1" ]; then
    # Generate random password if not provided
    PASSWORD=$(openssl rand -base64 12)
    echo -e "Generated random password: ${GREEN}$PASSWORD${NC}"
else
    PASSWORD="$1"
    echo "Using provided password."
fi

echo "Setting admin password..."
# docker exec without -it to avoid TTY errors in scripts
docker exec bell-cloud ./alist admin set "$PASSWORD" > /dev/null 2>&1

# 4. Login to get Token
echo "Logging in to get API token..."
LOGIN_PAYLOAD=$(cat <<EOF
{
  "username": "$USER",
  "password": "$PASSWORD"
}
EOF
)

# Use python3 to parse JSON (available on most macOS/Linux systems)
TOKEN=$(curl -s -X POST "$URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "$LOGIN_PAYLOAD" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('token', ''))")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "None" ]; then
    echo "Failed to get token. Check logs."
    exit 1
fi

# 5. Add Storage
# Note: 'addition' field is a stringified JSON in Alist v3
ADDITION=$(cat <<EOF
{"root_folder_path":"/mnt/local","thumbnail":false,"thumb_cache_folder":"","show_hidden":true,"mkdir_perm":"777"}
EOF
)
# JSON escape the addition string for the payload
ADDITION_ESCAPED=$(echo "$ADDITION" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read().strip()))")

STORAGE_PAYLOAD=$(cat <<EOF
{
  "mount_path": "/BellMemo",
  "order": 0,
  "remark": "Created by init script",
  "cache_expiration": 30,
  "web_proxy": false,
  "webdav_policy": "302_redirect",
  "down_proxy_url": "",
  "extract_folder": "",
  "driver": "Local",
  "addition": $ADDITION_ESCAPED
}
EOF
)

echo "Adding '/BellMemo' storage..."
# We use /api/admin/storage/create
RESPONSE=$(curl -s -X POST "$URL/api/admin/storage/create" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$STORAGE_PAYLOAD")

CODE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('code', -1))")

if [ "$CODE" -eq 200 ]; then
    echo -e "${GREEN}Success! Storage mounted.${NC}"
else
    # Check if failure is due to duplicate (code might vary, but we print response)
    MSG=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', ''))")
    if [[ "$MSG" == *"repeated"* ]]; then
        echo "Storage '/BellMemo' already exists."
    else
        echo "Failed to add storage. Response: $RESPONSE"
    fi
fi

echo ""
echo -e "${GREEN}Initialization Complete!${NC}"
echo "-----------------------------------"
echo -e "URL:      $URL"
echo -e "Username: $USER"
echo -e "Password: $PASSWORD"
echo "-----------------------------------"

