#!/bin/bash

set -e

BASE_URL="http://142.93.184.210"

echo "🧪 Testing Signal Protocol Backend API"
echo "========================================"
echo ""

# Generate valid 32-byte keys
ALICE_IDENTITY="7dl9633gceQQktCQtAWEiVRs6Co20F4GCZFYRVfyAno="
ALICE_SIGNED="5RD+rs443Lo2QZewhVV/3DfxPasaHLpGaC97gNp/Fq0="
ALICE_SIG="ksFqZYiioUJ9ffkGx37g7DkSGp/htSBf2cXdDVIMVOnJl4ynpi/zEfn/3zKZagqXoqY7xwJzy36PRUqI4AKpNA=="
ALICE_OTK1="aixDVJm4acbHnQ8gAvAMtgUCHamy0kSOyFUz6NNX5OE="
ALICE_OTK2="gVKMgiC2+zyo6JaOnCpQ6nPj95G1oDwAzj7Jcmd9sFs="
ALICE_OTK3="FyU1sph7Y2Hwnj4zmr9htLEXNqVf0dFLKT397ekXk+8="
BOB_IDENTITY="fh7QQf/FL6PFtRJ9tuvrCIV1P3Nl+kMjjhP85c8Sc4k="
BOB_SIGNED="0CksBZzNqa6Tl4x2UqBhgljoKwmtVGK8ckroBRsv7As="
BOB_SIG="iJidFvHxuLHwf5jTpEdexpgEibyuPjga4YOXdrrhNRQ7zc5q5d06GYFSI3EK4bzJ3BH37cMK8qsrvKIfmVLsgA=="
BOB_OTK1="aMb+FOnNt+UiTM/ktK+57tB4epHA5T+Xfr2WgeeIWok="
BOB_OTK2="CTVxrXVK2VIjGnPkT0yfs4bSIjE3/cp+6fklkCrKaQ8="
REP_OTK1="PuaXtLr72pWcu+vcTyTR94CFVLF3Zi73peqoKEBO+yc="
REP_OTK2="BvVFG9xJizJLWx0lhCly40pXAfiYYJ+FcMsP7ZMsVHc="

# Test 1: Health Check
echo "✓ Test 1: Health Check"
curl -s $BASE_URL/health | jq .
echo ""

# Test 2: Register Alice
echo "✓ Test 2: Register Alice"
ALICE_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice_test","password":"password123"}')
ALICE_TOKEN=$(echo $ALICE_RESPONSE | jq -r .token)
ALICE_ID=$(echo $ALICE_RESPONSE | jq -r .user.id)
echo "Alice ID: $ALICE_ID"
echo ""

# Test 3: Register Bob
echo "✓ Test 3: Register Bob"
BOB_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"bob_test","password":"password123"}')
BOB_TOKEN=$(echo $BOB_RESPONSE | jq -r .token)
BOB_ID=$(echo $BOB_RESPONSE | jq -r .user.id)
echo "Bob ID: $BOB_ID"
echo ""

# Test 4: Check key status (before upload)
echo "✓ Test 4: Check Alice key status (before upload)"
curl -s $BASE_URL/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .
echo ""

# Test 5: Upload Alice's keys
echo "✓ Test 5: Upload Alice's keys"
ALICE_UPLOAD=$(curl -s -X POST $BASE_URL/api/keys/upload \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"identityKey\": \"$ALICE_IDENTITY\",
    \"registrationId\": 12345,
    \"signedPrekey\": {
      \"keyId\": 1,
      \"publicKey\": \"$ALICE_SIGNED\",
      \"signature\": \"$ALICE_SIG\"
    },
    \"oneTimePrekeys\": [
      {\"keyId\": 1, \"publicKey\": \"$ALICE_OTK1\"},
      {\"keyId\": 2, \"publicKey\": \"$ALICE_OTK2\"},
      {\"keyId\": 3, \"publicKey\": \"$ALICE_OTK3\"}
    ]
  }")
echo "$ALICE_UPLOAD" | jq .
echo ""

# Test 6: Check key status (after upload)
echo "✓ Test 6: Check Alice key status (after upload)"
curl -s $BASE_URL/api/keys/status \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .
echo ""

# Test 7: Upload Bob's keys
echo "✓ Test 7: Upload Bob's keys"
BOB_UPLOAD=$(curl -s -X POST $BASE_URL/api/keys/upload \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"identityKey\": \"$BOB_IDENTITY\",
    \"registrationId\": 54321,
    \"signedPrekey\": {
      \"keyId\": 1,
      \"publicKey\": \"$BOB_SIGNED\",
      \"signature\": \"$BOB_SIG\"
    },
    \"oneTimePrekeys\": [
      {\"keyId\": 1, \"publicKey\": \"$BOB_OTK1\"},
      {\"keyId\": 2, \"publicKey\": \"$BOB_OTK2\"}
    ]
  }")
echo "$BOB_UPLOAD" | jq .
echo ""

# Test 8: Fetch prekey bundle
echo "✓ Test 8: Bob fetches Alice's prekey bundle"
BUNDLE=$(curl -s $BASE_URL/api/keys/bundle/$ALICE_ID \
  -H "Authorization: Bearer $BOB_TOKEN")
echo "$BUNDLE" | jq .
echo ""

# Test 9: Check prekey count (after consumption)
echo "✓ Test 9: Check Alice prekey count (after consumption)"
curl -s $BASE_URL/api/keys/prekey-count \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .
echo ""

# Test 10: Send encrypted message
echo "✓ Test 10: Bob sends encrypted message to Alice"
SEND_RESULT=$(curl -s -X POST $BASE_URL/api/messages/send-encrypted \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"messages\": [
      {
        \"to_user_id\": $ALICE_ID,
        \"encrypted_payload\": \"c29tZV9lbmNyeXB0ZWRfZGF0YV9oZXJl\",
        \"sender_ratchet_key\": \"cmF0Y2hldF9rZXlfaGVyZQ==\",
        \"counter\": 1
      }
    ],
    \"device_name\": \"ESP32-TestDevice\"
  }")
echo "$SEND_RESULT" | jq .
echo ""

# Test 11: Fetch message history
echo "✓ Test 11: Alice fetches message history"
HISTORY=$(curl -s $BASE_URL/api/messages/history \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$HISTORY" | jq .
echo ""

# Test 12: Send legacy plaintext message
echo "✓ Test 12: Alice sends legacy plaintext message to Bob"
LEGACY_SEND=$(curl -s -X POST $BASE_URL/api/messages/send \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"to_user_ids\": [$BOB_ID],
    \"message\": \"This is a plaintext test message\",
    \"device_name\": \"ESP32-Legacy\"
  }")
echo "$LEGACY_SEND" | jq .
echo ""

# Test 13: Replenish prekeys
echo "✓ Test 13: Alice replenishes prekeys"
REPLENISH=$(curl -s -X POST $BASE_URL/api/keys/replenish-prekeys \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"oneTimePrekeys\": [
      {\"keyId\": 4, \"publicKey\": \"$REP_OTK1\"},
      {\"keyId\": 5, \"publicKey\": \"$REP_OTK2\"}
    ]
  }")
echo "$REPLENISH" | jq .
echo ""

# Test 14: Final prekey count
echo "✓ Test 14: Check Alice final prekey count"
curl -s $BASE_URL/api/keys/prekey-count \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq .
echo ""

echo "========================================"
echo "✅ All tests completed!"
echo ""
echo "Summary:"
echo "  - Alice ID: $ALICE_ID"
echo "  - Bob ID: $BOB_ID"
echo "  - Server: $BASE_URL"
