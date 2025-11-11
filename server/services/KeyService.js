/**
 * KeyService - Signal Protocol Key Management
 *
 * Handles storage and retrieval of:
 * - Identity keys (public, long-term)
 * - Signed prekeys (public, medium-term)
 * - One-time prekeys (public, single-use)
 *
 * Note: Private keys never leave the client device
 */

const { pool } = require('../config/database');

class KeyService {
  /**
   * Store user's identity key (first-time setup)
   * @param {number} userId - User ID
   * @param {Buffer} publicKey - Public identity key (32 bytes)
   * @param {number} registrationId - Signal Protocol registration ID
   * @returns {Promise<boolean>} Success status
   */
  async storeIdentityKey(userId, publicKey, registrationId) {
    try {
      const result = await pool.query(
        `INSERT INTO identity_keys (user_id, public_key, registration_id, created_at, updated_at)
         VALUES ($1, $2, $3, NOW(), NOW())
         ON CONFLICT (user_id)
         DO UPDATE SET
           public_key = EXCLUDED.public_key,
           registration_id = EXCLUDED.registration_id,
           updated_at = NOW()
         RETURNING user_id`,
        [userId, publicKey, registrationId]
      );

      return result.rows.length > 0;
    } catch (error) {
      console.error('Error storing identity key:', error);
      throw error;
    }
  }

  /**
   * Store signed prekey
   * @param {number} userId - User ID
   * @param {number} keyId - Prekey ID
   * @param {Buffer} publicKey - Public prekey (32 bytes)
   * @param {Buffer} signature - Signature from identity key
   * @returns {Promise<boolean>} Success status
   */
  async storeSignedPrekey(userId, keyId, publicKey, signature) {
    try {
      const result = await pool.query(
        `INSERT INTO signed_prekeys (user_id, key_id, public_key, signature, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (user_id, key_id)
         DO UPDATE SET
           public_key = EXCLUDED.public_key,
           signature = EXCLUDED.signature,
           created_at = NOW()
         RETURNING id`,
        [userId, keyId, publicKey, signature]
      );

      return result.rows.length > 0;
    } catch (error) {
      console.error('Error storing signed prekey:', error);
      throw error;
    }
  }

  /**
   * Store batch of one-time prekeys
   * @param {number} userId - User ID
   * @param {Array<{keyId: number, publicKey: Buffer}>} prekeys - Array of prekeys
   * @returns {Promise<number>} Number of keys stored
   */
  async storeOneTimePrekeys(userId, prekeys) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      let storedCount = 0;

      for (const prekey of prekeys) {
        const result = await client.query(
          `INSERT INTO one_time_prekeys (user_id, key_id, public_key, consumed, created_at)
           VALUES ($1, $2, $3, FALSE, NOW())
           ON CONFLICT (user_id, key_id) DO NOTHING
           RETURNING id`,
          [userId, prekey.keyId, prekey.publicKey]
        );

        if (result.rows.length > 0) {
          storedCount++;
        }
      }

      // Update user's prekey count
      await client.query(
        `UPDATE users
         SET prekey_count = (
           SELECT COUNT(*) FROM one_time_prekeys
           WHERE user_id = $1 AND consumed = FALSE
         )
         WHERE id = $1`,
        [userId]
      );

      await client.query('COMMIT');

      return storedCount;
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error storing one-time prekeys:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get prekey bundle for initiating session with a user
   * @param {number} userId - Target user ID
   * @param {number} requesterId - Requesting user ID (for tracking)
   * @returns {Promise<Object|null>} Prekey bundle or null if not found
   */
  async getPreKeyBundle(userId, requesterId) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // 1. Get identity key
      const identityResult = await client.query(
        'SELECT public_key, registration_id FROM identity_keys WHERE user_id = $1',
        [userId]
      );

      if (identityResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null;
      }

      const identityKey = identityResult.rows[0];

      // 2. Get current signed prekey (most recent)
      const signedPrekeyResult = await client.query(
        `SELECT key_id, public_key, signature
         FROM signed_prekeys
         WHERE user_id = $1
         ORDER BY created_at DESC
         LIMIT 1`,
        [userId]
      );

      if (signedPrekeyResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null;
      }

      const signedPrekey = signedPrekeyResult.rows[0];

      // 3. Get and consume one one-time prekey
      const oneTimePrekeyResult = await client.query(
        `UPDATE one_time_prekeys
         SET consumed = TRUE, consumed_at = NOW(), consumed_by = $2
         WHERE id = (
           SELECT id FROM one_time_prekeys
           WHERE user_id = $1 AND consumed = FALSE
           ORDER BY created_at ASC
           LIMIT 1
         )
         RETURNING key_id, public_key`,
        [userId, requesterId]
      );

      const oneTimePrekey = oneTimePrekeyResult.rows.length > 0
        ? oneTimePrekeyResult.rows[0]
        : null;

      // 4. Update user's prekey count
      await client.query(
        `UPDATE users
         SET prekey_count = (
           SELECT COUNT(*) FROM one_time_prekeys
           WHERE user_id = $1 AND consumed = FALSE
         )
         WHERE id = $1`,
        [userId]
      );

      await client.query('COMMIT');

      // Return prekey bundle
      return {
        identityKey: identityKey.public_key,
        registrationId: identityKey.registration_id,
        signedPrekey: {
          keyId: signedPrekey.key_id,
          publicKey: signedPrekey.public_key,
          signature: signedPrekey.signature
        },
        oneTimePrekey: oneTimePrekey ? {
          keyId: oneTimePrekey.key_id,
          publicKey: oneTimePrekey.public_key
        } : null
      };
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error getting prekey bundle:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get available prekey count for a user
   * @param {number} userId - User ID
   * @returns {Promise<number>} Number of available one-time prekeys
   */
  async getAvailablePrekeyCount(userId) {
    try {
      const result = await pool.query(
        'SELECT COUNT(*) as count FROM one_time_prekeys WHERE user_id = $1 AND consumed = FALSE',
        [userId]
      );

      return parseInt(result.rows[0].count, 10);
    } catch (error) {
      console.error('Error getting prekey count:', error);
      throw error;
    }
  }

  /**
   * Check if user has uploaded keys
   * @param {number} userId - User ID
   * @returns {Promise<boolean>} True if user has keys
   */
  async hasKeys(userId) {
    try {
      const result = await pool.query(
        'SELECT 1 FROM identity_keys WHERE user_id = $1 LIMIT 1',
        [userId]
      );

      return result.rows.length > 0;
    } catch (error) {
      console.error('Error checking if user has keys:', error);
      throw error;
    }
  }

  /**
   * Delete all keys for a user (for account deletion or key rotation)
   * @param {number} userId - User ID
   * @returns {Promise<boolean>} Success status
   */
  async deleteAllKeys(userId) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      await client.query('DELETE FROM one_time_prekeys WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM signed_prekeys WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM identity_keys WHERE user_id = $1', [userId]);

      await client.query('COMMIT');

      return true;
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error deleting keys:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new KeyService();
