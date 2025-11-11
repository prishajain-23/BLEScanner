/**
 * Signal Protocol Key Management Routes
 *
 * Endpoints for uploading and retrieving public keys for E2EE
 */

const express = require('express');
const router = express.Router();
const KeyService = require('../services/KeyService');
const authenticateToken = require('../middleware/auth');

/**
 * POST /api/keys/upload
 * Upload public keys (identity, signed prekey, one-time prekeys)
 *
 * Called once on first launch or after key regeneration
 */
router.post('/upload', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      identityKey,      // Base64-encoded public identity key
      registrationId,   // Signal Protocol registration ID
      signedPrekey,     // {keyId, publicKey (base64), signature (base64)}
      oneTimePrekeys    // [{keyId, publicKey (base64)}, ...]
    } = req.body;

    // Validate required fields
    if (!identityKey || !registrationId || !signedPrekey || !oneTimePrekeys) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['identityKey', 'registrationId', 'signedPrekey', 'oneTimePrekeys']
      });
    }

    // Validate signed prekey format
    if (!signedPrekey.keyId || !signedPrekey.publicKey || !signedPrekey.signature) {
      return res.status(400).json({
        error: 'Invalid signed prekey format',
        required: ['keyId', 'publicKey', 'signature']
      });
    }

    // Validate one-time prekeys format
    if (!Array.isArray(oneTimePrekeys) || oneTimePrekeys.length === 0) {
      return res.status(400).json({
        error: 'oneTimePrekeys must be a non-empty array'
      });
    }

    // Validate one-time prekeys structure
    for (const prekey of oneTimePrekeys) {
      if (!prekey.keyId || !prekey.publicKey) {
        return res.status(400).json({
          error: 'Invalid one-time prekey format',
          required: ['keyId', 'publicKey']
        });
      }
    }

    // Convert base64 to buffers
    const identityKeyBuffer = Buffer.from(identityKey, 'base64');
    const signedPrekeyBuffer = Buffer.from(signedPrekey.publicKey, 'base64');
    const signatureBuffer = Buffer.from(signedPrekey.signature, 'base64');

    // Validate key sizes (Curve25519 keys are 32 bytes)
    if (identityKeyBuffer.length !== 32) {
      return res.status(400).json({ error: 'Identity key must be 32 bytes' });
    }
    if (signedPrekeyBuffer.length !== 32) {
      return res.status(400).json({ error: 'Signed prekey must be 32 bytes' });
    }

    // Store identity key
    await KeyService.storeIdentityKey(userId, identityKeyBuffer, registrationId);

    // Store signed prekey
    await KeyService.storeSignedPrekey(
      userId,
      signedPrekey.keyId,
      signedPrekeyBuffer,
      signatureBuffer
    );

    // Store one-time prekeys
    const prekeyBuffers = oneTimePrekeys.map(prekey => ({
      keyId: prekey.keyId,
      publicKey: Buffer.from(prekey.publicKey, 'base64')
    }));

    // Validate all prekey sizes
    for (const prekey of prekeyBuffers) {
      if (prekey.publicKey.length !== 32) {
        return res.status(400).json({ error: 'All one-time prekeys must be 32 bytes' });
      }
    }

    const storedCount = await KeyService.storeOneTimePrekeys(userId, prekeyBuffers);

    res.json({
      success: true,
      message: 'Keys uploaded successfully',
      oneTimePrekeyCount: storedCount
    });
  } catch (error) {
    console.error('Error uploading keys:', error);
    res.status(500).json({ error: 'Failed to upload keys' });
  }
});

/**
 * GET /api/keys/bundle/:userId
 * Get prekey bundle for initiating session with a user
 *
 * Returns:
 * - Identity key
 * - Registration ID
 * - Signed prekey (most recent)
 * - One one-time prekey (consumed after retrieval)
 */
router.get('/bundle/:userId', authenticateToken, async (req, res) => {
  try {
    const targetUserId = parseInt(req.params.userId, 10);
    const requesterId = req.user.id;

    if (isNaN(targetUserId)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    // Can't fetch own bundle (use for testing only)
    if (targetUserId === requesterId) {
      return res.status(400).json({ error: 'Cannot fetch your own prekey bundle' });
    }

    const bundle = await KeyService.getPreKeyBundle(targetUserId, requesterId);

    if (!bundle) {
      return res.status(404).json({
        error: 'Prekey bundle not found',
        message: 'User has not uploaded keys yet'
      });
    }

    // Convert buffers to base64 for JSON response
    res.json({
      identityKey: bundle.identityKey.toString('base64'),
      registrationId: bundle.registrationId,
      signedPrekey: {
        keyId: bundle.signedPrekey.keyId,
        publicKey: bundle.signedPrekey.publicKey.toString('base64'),
        signature: bundle.signedPrekey.signature.toString('base64')
      },
      oneTimePrekey: bundle.oneTimePrekey ? {
        keyId: bundle.oneTimePrekey.keyId,
        publicKey: bundle.oneTimePrekey.publicKey.toString('base64')
      } : null
    });
  } catch (error) {
    console.error('Error fetching prekey bundle:', error);
    res.status(500).json({ error: 'Failed to fetch prekey bundle' });
  }
});

/**
 * POST /api/keys/replenish-prekeys
 * Upload additional one-time prekeys when count is low
 */
router.post('/replenish-prekeys', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { oneTimePrekeys } = req.body;

    if (!Array.isArray(oneTimePrekeys) || oneTimePrekeys.length === 0) {
      return res.status(400).json({ error: 'oneTimePrekeys must be a non-empty array' });
    }

    // Validate structure
    for (const prekey of oneTimePrekeys) {
      if (!prekey.keyId || !prekey.publicKey) {
        return res.status(400).json({
          error: 'Invalid one-time prekey format',
          required: ['keyId', 'publicKey']
        });
      }
    }

    // Convert to buffers and validate
    const prekeyBuffers = oneTimePrekeys.map(prekey => ({
      keyId: prekey.keyId,
      publicKey: Buffer.from(prekey.publicKey, 'base64')
    }));

    for (const prekey of prekeyBuffers) {
      if (prekey.publicKey.length !== 32) {
        return res.status(400).json({ error: 'All one-time prekeys must be 32 bytes' });
      }
    }

    const storedCount = await KeyService.storeOneTimePrekeys(userId, prekeyBuffers);

    res.json({
      success: true,
      message: 'Prekeys replenished successfully',
      storedCount
    });
  } catch (error) {
    console.error('Error replenishing prekeys:', error);
    res.status(500).json({ error: 'Failed to replenish prekeys' });
  }
});

/**
 * GET /api/keys/prekey-count
 * Get available one-time prekey count
 */
router.get('/prekey-count', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const count = await KeyService.getAvailablePrekeyCount(userId);

    res.json({
      count,
      needsReplenishment: count < 20  // Alert if below threshold
    });
  } catch (error) {
    console.error('Error getting prekey count:', error);
    res.status(500).json({ error: 'Failed to get prekey count' });
  }
});

/**
 * GET /api/keys/status
 * Check if user has uploaded keys
 */
router.get('/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const hasKeys = await KeyService.hasKeys(userId);
    const count = hasKeys ? await KeyService.getAvailablePrekeyCount(userId) : 0;

    res.json({
      hasKeys,
      prekeyCount: count,
      needsSetup: !hasKeys
    });
  } catch (error) {
    console.error('Error checking key status:', error);
    res.status(500).json({ error: 'Failed to check key status' });
  }
});

/**
 * DELETE /api/keys
 * Delete all keys (for key rotation or account deletion)
 */
router.delete('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    await KeyService.deleteAllKeys(userId);

    res.json({
      success: true,
      message: 'All keys deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting keys:', error);
    res.status(500).json({ error: 'Failed to delete keys' });
  }
});

module.exports = router;
