#!/bin/bash

# --- INPUTS ---
read -p "Enter Server IP: " SERVER_IP
read -p "Enter Port: " SERVER_PORT
read -p "Enter Admin Auth Token: " AUTH_TOKEN

BASE_URL="http://$SERVER_IP:$SERVER_PORT"
# We filter for birthdays starting with 1997-10
QUERY_URL="$BASE_URL/api/collections/users/records?filter=(birthday~'1997-10')&perPage=500"

echo "-----------------------------------------------"
echo "🔍 Searching for October 1997 records..."
echo "-----------------------------------------------"

# 1. Fetch the records
# We save the JSON response to a temporary file
RESPONSE=$(curl -s -X GET "$QUERY_URL" -H "Authorization: $AUTH_TOKEN")

# 2. Extract the IDs
# This regex looks for the "id":"..." pattern in the JSON
IDS=$(echo "$RESPONSE" | grep -oP '"id":"\K[^"]+')

COUNT=$(echo "$IDS" | wc -w)

if [ "$COUNT" -eq 0 ]; then
    echo "✅ No matching records found. The database is already clean!"
    exit 0
fi

echo "Found $COUNT records to delete."
read -p "⚠️ Proceed with deletion? (y/n): " PROCEED

if [ "$PROCEED" != "y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# 3. Loop and Delete
CURRENT=1
for ID in $IDS
do
    DELETE_URL="$BASE_URL/api/collections/users/records/$ID"
    
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$DELETE_URL" \
        -H "Authorization: $AUTH_TOKEN")

    if [ "$STATUS" -eq 204 ]; then
        echo "[$CURRENT/$COUNT] 🗑️ Deleted ID: $ID"
    else
        echo "[$CURRENT/$COUNT] ❌ Failed to delete ID: $ID (Status: $STATUS)"
    fi
    
    ((CURRENT++))
done

echo "-----------------------------------------------"
echo "✨ Cleanup Complete!"
echo "-----------------------------------------------"
