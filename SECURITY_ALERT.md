# 🚨 CRITICAL SECURITY ALERT

**Date:** November 7, 2025
**Issue:** APNs Private Key Exposed in Git History
**Severity:** HIGH

## Problem

The APNs private key file (`server/config/AuthKey_X859SFN76P.p8`) was committed to the repository in earlier commits and is now exposed in the git history. GitGuardian detected this and sent an alert.

**File Path:** `server/config/AuthKey_X859SFN76P.p8`
**Key ID:** X859SFN76P
**Team ID:** NV97R9Q8MF
**Bundle ID:** com.prishajain.blescanner

## Impact

- Anyone with access to the repository can extract this key from git history
- The key can be used to send push notifications to your app users
- This is a security risk for your users and your app

## Immediate Actions Required

### 1. Revoke the Exposed Key

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles** → **Keys**
3. Find key **X859SFN76P**
4. Click **Revoke** to disable it immediately

### 2. Generate a New APNs Key

1. In Apple Developer Portal, go to **Keys**
2. Click the **+** button to create a new key
3. Name it: "BLEScanner APNs Key"
4. Check **Apple Push Notifications service (APNs)**
5. Click **Continue** then **Register**
6. **Download the .p8 file** (you can only do this once!)
7. Note the **Key ID** (e.g., ABC123XYZ9)

### 3. Update Backend Configuration

1. SSH into your production server:
   ```bash
   ssh root@142.93.184.210
   ```

2. Upload the new key:
   ```bash
   cd /var/www/blescanner-backend/server/config
   rm AuthKey_*.p8  # Remove old key
   # Upload new key via SCP or SFTP
   ```

3. Update environment variables:
   ```bash
   nano /var/www/blescanner-backend/server/.env
   ```

   Update:
   ```env
   APNS_KEY_ID=ABC123XYZ9  # Your new key ID
   APNS_TEAM_ID=NV97R9Q8MF  # Same
   APNS_BUNDLE_ID=com.prishajain.blescanner  # Same
   APNS_KEY_PATH=./config/AuthKey_ABC123XYZ9.p8  # New filename
   ```

4. Restart the server:
   ```bash
   pm2 restart blescanner-backend
   pm2 logs blescanner-backend  # Verify it starts correctly
   ```

### 4. Clean Git History (IMPORTANT!)

**Option A: Remove from History (Recommended for Public Repos)**

```bash
cd /Users/prishajain/Desktop/GitHub/BLEScanner

# Install BFG Repo-Cleaner (if not installed)
brew install bfg

# Remove the key from all commits
bfg --delete-files AuthKey_X859SFN76P.p8

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (WARNING: This rewrites history!)
git push --force --all
git push --force --tags
```

**Option B: For Private Repos Only**

If this is a private repo and you trust all collaborators, you can just ensure the key is in `.gitignore` and not commit it again.

### 5. Verify Security

1. Check that `.gitignore` includes:
   ```
   server/config/*.p8
   *.p8
   ```

2. Verify the key is gone from the repo:
   ```bash
   git log --all --full-history --oneline | grep "AuthKey"
   ```

3. Test push notifications with the new key

## Prevention

1. **Always add sensitive files to `.gitignore` BEFORE committing**
2. **Use environment variables for secrets**
3. **Never commit .p8, .pem, .key, .env files**
4. **Enable pre-commit hooks** to scan for secrets
5. **Regularly audit your .gitignore**

## Files to NEVER Commit

- `*.p8` (APNs keys)
- `*.pem` (certificates)
- `*.key` (private keys)
- `.env` (environment variables)
- `*.mobileprovision` (provisioning profiles)
- Database credentials
- API keys
- OAuth secrets

## Current Status

- [x] Security alert received
- [x] Issue documented
- [ ] Key revoked in Apple Developer Portal
- [ ] New key generated
- [ ] Backend updated with new key
- [ ] Git history cleaned
- [ ] Verified push notifications work with new key

## Resources

- [Apple Developer Portal](https://developer.apple.com/account)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [GitGuardian](https://www.gitguardian.com/)

---

**⚠️ DO NOT IGNORE THIS ALERT ⚠️**

This is a real security issue that needs immediate attention. Follow the steps above as soon as possible.
