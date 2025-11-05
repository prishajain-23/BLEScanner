# BLEScanner Backend API

Backend messaging system for BLEScanner iOS app.

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.x
- **Database**: PostgreSQL 15+
- **Auth**: JWT with bcrypt password hashing
- **Push Notifications**: APNs (Apple Push Notification service)

## Setup Instructions

### Prerequisites

1. **Node.js 18+** - Check version: `node --version`
2. **PostgreSQL 15+** - Install via Homebrew:
   ```bash
   brew install postgresql@15
   brew services start postgresql@15
   ```

### Installation

1. **Install dependencies**:
   ```bash
   cd server
   npm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Create PostgreSQL database and user**:
   ```bash
   # Connect to PostgreSQL
   psql postgres

   # In psql:
   CREATE DATABASE blescanner;
   CREATE USER blescanner_user WITH PASSWORD 'blescanner_dev_pass_2025';
   GRANT ALL PRIVILEGES ON DATABASE blescanner TO blescanner_user;
   \q
   ```

4. **Run database schema**:
   ```bash
   psql -U blescanner_user -d blescanner -f db/schema.sql
   ```

   If prompted for password, use: `blescanner_dev_pass_2025`

5. **Test database connection**:
   ```bash
   node test-db.js
   ```

### Development

Start the development server:
```bash
npm run dev
```

The API will be available at: `http://localhost:3000`

### Project Structure

```
server/
├── config/          # Configuration files
│   ├── database.js  # PostgreSQL pool setup
│   └── jwt.js       # JWT configuration
├── db/              # Database files
│   └── schema.sql   # Database schema
├── middleware/      # Express middleware (Day 2)
├── routes/          # API routes (Day 2)
├── services/        # Business logic (Day 2)
├── utils/           # Helper functions (Day 2)
├── .env             # Environment variables (not in git)
├── .env.example     # Environment template
├── package.json     # Dependencies
└── index.js         # Entry point (Day 2)
```

## Database Schema

### Tables

- **users**: User accounts (id, username, password_hash, device_token)
- **messages**: Messages sent (id, from_user_id, message_text, device_name, created_at)
- **message_recipients**: Delivery tracking (message_id, to_user_id, delivered, read)
- **contacts**: User relationships (user_id, contact_user_id, nickname)

### Relationships

- Users have many messages (sender)
- Users have many message_recipients (receiver)
- Users have many contacts
- Messages have many message_recipients

## API Endpoints (Phase 1 Day 2)

Coming soon! Will include:
- Auth: `/api/auth/register`, `/api/auth/login`
- Users: `/api/users/search`, `/api/users/me`
- Contacts: `/api/contacts/*`
- Messages: `/api/messages/*`
- Devices: `/api/devices/register-push`

## Security

- Passwords hashed with bcrypt (10+ salt rounds)
- JWT tokens with 30-day expiration
- Rate limiting on sensitive endpoints
- Parameterized queries to prevent SQL injection
- HTTPS only in production

## Development Status

**Phase 1 - Day 1**: ✅ Server & Database Setup (COMPLETED)
- [x] Server directory structure
- [x] Database schema
- [x] Configuration files
- [x] Local PostgreSQL setup

**Phase 1 - Day 2**: 🚧 API Endpoints (NEXT)
**Phase 1 - Day 3**: 📅 Push Notifications
**Phase 2**: 📅 iOS App Integration

## License

AGPL-3.0 - See LICENSE.md in root directory
