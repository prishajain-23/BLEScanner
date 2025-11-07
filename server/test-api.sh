#!/bin/bash

# BLEScanner API Production Test Suite
# Tests all endpoints in production environment

BASE_URL="http://142.93.184.210/api"
SERVER_URL="http://142.93.184.210"

echo "======================================"
echo "BLEScanner API Production Test Suite"
echo "======================================"
echo ""

# Test 1: Health Check
echo "[1/12] Health Check"
echo "GET $SERVER_URL/health"
echo "---"
curl -s "$SERVER_URL/health" | jq '.'
echo ""
sleep 1

# Test 2: Register User 1
echo "[2/12] Register User 1 (alice_test)"
echo "POST $BASE_URL/auth/register"
echo "---"
REGISTER1=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice_test","password":"password123"}')
echo $REGISTER1 | jq '.'
TOKEN1=$(echo $REGISTER1 | jq -r '.token')
USER1_ID=$(echo $REGISTER1 | jq -r '.user.id')
echo "✓ Token 1: ${TOKEN1:0:30}..."
echo "✓ User 1 ID: $USER1_ID"
echo ""
sleep 1

# Test 3: Register User 2
echo "[3/12] Register User 2 (bob_test)"
echo "POST $BASE_URL/auth/register"
echo "---"
REGISTER2=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"bob_test","password":"password123"}')
echo $REGISTER2 | jq '.'
TOKEN2=$(echo $REGISTER2 | jq -r '.token')
USER2_ID=$(echo $REGISTER2 | jq -r '.user.id')
echo "✓ Token 2: ${TOKEN2:0:30}..."
echo "✓ User 2 ID: $USER2_ID"
echo ""
sleep 1

# Test 4: Login User 1
echo "[4/12] Login alice_test"
echo "POST $BASE_URL/auth/login"
echo "---"
LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice_test","password":"password123"}')
echo $LOGIN | jq '.'
echo ""
sleep 1

# Test 5: Get User Profile
echo "[5/12] Get alice_test Profile"
echo "GET $BASE_URL/users/me"
echo "---"
curl -s "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN1" | jq '.'
echo ""
sleep 1

# Test 6: Search Users
echo "[6/12] Search for 'bob'"
echo "GET $BASE_URL/users/search?q=bob"
echo "---"
curl -s "$BASE_URL/users/search?q=bob" \
  -H "Authorization: Bearer $TOKEN1" | jq '.'
echo ""
sleep 1

# Test 7: Add Contact (alice adds bob)
echo "[7/12] Alice adds Bob as contact"
echo "POST $BASE_URL/contacts/add"
echo "---"
ADD_CONTACT=$(curl -s -X POST "$BASE_URL/contacts/add" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"contact_username":"bob_test"}')
echo $ADD_CONTACT | jq '.'
CONTACT_ID=$(echo $ADD_CONTACT | jq -r '.contact.id')
echo "✓ Contact ID: $CONTACT_ID"
echo ""
sleep 1

# Test 8: List Contacts
echo "[8/12] List Alice's Contacts"
echo "GET $BASE_URL/contacts"
echo "---"
curl -s "$BASE_URL/contacts" \
  -H "Authorization: Bearer $TOKEN1" | jq '.'
echo ""
sleep 1

# Test 9: Send Message (alice to bob)
echo "[9/12] Alice sends message to Bob"
echo "POST $BASE_URL/messages/send"
echo "---"
MESSAGE=$(curl -s -X POST "$BASE_URL/messages/send" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d "{
    \"to_user_ids\": [$USER2_ID],
    \"message\": \"ESP32 Device Connected\",
    \"device_name\": \"Living Room Sensor\"
  }")
echo $MESSAGE | jq '.'
MESSAGE_ID=$(echo $MESSAGE | jq -r '.message.id')
echo "✓ Message ID: $MESSAGE_ID"
echo ""
sleep 1

# Test 10: Get Message History (Bob's perspective)
echo "[10/12] Get Bob's Message History"
echo "GET $BASE_URL/messages/history?limit=10"
echo "---"
curl -s "$BASE_URL/messages/history?limit=10" \
  -H "Authorization: Bearer $TOKEN2" | jq '.'
echo ""
sleep 1

# Test 11: Mark Message as Read
echo "[11/12] Bob marks message as read"
echo "POST $BASE_URL/messages/$MESSAGE_ID/read"
echo "---"
curl -s -X POST "$BASE_URL/messages/$MESSAGE_ID/read" \
  -H "Authorization: Bearer $TOKEN2" | jq '.'
echo ""
sleep 1

# Test 12: Register Device Token
echo "[12/12] Register Push Device Token"
echo "POST $BASE_URL/devices/register-push"
echo "---"
curl -s -X POST "$BASE_URL/devices/register-push" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": "test_device_token_abc123def456",
    "platform": "ios"
  }' | jq '.'
echo ""
sleep 1

# Test 13: Remove Contact
echo "[13/13] Alice removes Bob as contact"
echo "DELETE $BASE_URL/contacts/$CONTACT_ID"
echo "---"
curl -s -X DELETE "$BASE_URL/contacts/$CONTACT_ID" \
  -H "Authorization: Bearer $TOKEN1" | jq '.'
echo ""

echo ""
echo "======================================"
echo "✓ All Tests Complete!"
echo "======================================"
echo ""
echo "Summary:"
echo "  - User 1 (alice_test): ID $USER1_ID"
echo "  - User 2 (bob_test): ID $USER2_ID"
echo "  - Contact ID: $CONTACT_ID"
echo "  - Message ID: $MESSAGE_ID"
echo ""
