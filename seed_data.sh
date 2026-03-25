#!/bin/bash

# --- INPUTS ---
read -p "Enter Server IP (e.g., 192.168.0.13): " SERVER_IP
read -p "Enter Port (e.g., 8080): " SERVER_PORT
read -p "Enter Admin Auth Token: " AUTH_TOKEN

BASE_URL="http://$SERVER_IP:$SERVER_PORT"
COLLECTION_URL="$BASE_URL/api/collections/users/records"

echo "-----------------------------------------------"
echo "🚀 Starting injection of 2,000 Auth records..."
echo "-----------------------------------------------"

names=("Alex" "Jordan" "Taylor" "Morgan" "Casey" "Riley" "Jamie" "Skyler" "Harry" "Charlie")
statuses=("active" "pending" "archived")

for i in {1..2000}
do
    # 1. Generate unique identifiers
    ID_PADDED=$(printf "%04d" $i)
    RAND_NAME="${names[$RANDOM % ${#names[@]}]}_$ID_PADDED"
    RAND_STATUS="${statuses[$RANDOM % ${#statuses[@]}]}"
    
    # Required for Auth Collections:
    USER_EMAIL="user_${ID_PADDED}@example.com"
    USER_PASS="password123"

    # 2. Randomize Birthday logic (10% chance for Oct 1997)
    CHANCE=$((1 + $RANDOM % 100))
    if [ $CHANCE -le 10 ]; then
        DAY=$((1 + $RANDOM % 31))
        BIRTHDAY="1997-10-$(printf "%02d" $DAY) 12:00:00Z"
    else
        YEAR=$((1980 + $RANDOM % 31))
        MONTH=$((1 + $RANDOM % 12))
        DAY=$((1 + $RANDOM % 28))
        BIRTHDAY="$YEAR-$(printf "%02d" $MONTH)-$(printf "%02d" $DAY) 12:00:00Z"
    fi

    # 3. Send Request
    # We capture the HTTP status code to see if it's working
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "$COLLECTION_URL" \
        -H "Authorization: $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$USER_EMAIL\",
            \"password\": \"$USER_PASS\",
            \"passwordConfirm\": \"$USER_PASS\",
            \"name\": \"$RAND_NAME\",
            \"birthday\": \"$BIRTHDAY\",
            \"status\": \"$RAND_STATUS\",
            \"verified\": true
        }")

    # 4. Progress Tracking & Debugging
    HTTP_STATUS="${RESPONSE:${#RESPONSE}-3}"
    
    if [ "$HTTP_STATUS" -ne 200 ]; then
        echo "❌ Failed at record $i (HTTP $HTTP_STATUS). Response: ${RESPONSE:0:${#RESPONSE}-3}"
        exit 1
    fi

    if (( $i % 100 == 0 )); then
        echo "✅ Injected $i/2000 records..."
    fi
done

echo "-----------------------------------------------"
echo "✨ Finished! 2,000 users created."
