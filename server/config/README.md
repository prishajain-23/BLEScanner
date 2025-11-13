# APNs Configuration

## APNs Private Key

**IMPORTANT:** The APNs private key file (`AuthKey_*.p8`) is NOT included in this repository for security reasons.

### Setup Instructions

1. **Generate APNs Key** (if you don't have one):
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Click "+" to create a new key
   - Select "Apple Push Notifications service (APNs)"
   - Download the `.p8` file (you can only download it once!)

2. **Place the key file**:
   - Save the downloaded `.p8` file to this directory: `server/config/`
   - The file should be named: `AuthKey_<KEY_ID>.p8`

3. **Update your `.env` file**:
   ```bash
   APNS_KEY_ID=<YOUR_KEY_ID>
   APNS_TEAM_ID=<YOUR_TEAM_ID>
   APNS_TOPIC=com.prishajain.blescanner
   APNS_KEY_PATH=./config/AuthKey_<YOUR_KEY_ID>.p8
   APNS_PRODUCTION=false  # Use 'true' for production
   ```

### Security Notes

- **NEVER commit `.p8` files to git**
- The `.p8` file is already in `.gitignore`
- Store the key securely (password manager, secure notes, etc.)
- If exposed, revoke and generate a new key immediately

### Current Configuration

For the BLEScanner production server:
- Key ID: `N2UGRH67CT` (Active - Created Nov 12, 2025)
- Team ID: `NV97R9Q8MF`
- Bundle ID: `com.prishajain.medaloffreedom`
- Previous Key: `X859SFN76P` (REVOKED Nov 12, 2025 @ 3:40PM EST - compromised)
