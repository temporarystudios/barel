```
██████╗  █████╗ ██████╗ ███████╗██╗     
██╔══██╗██╔══██╗██╔══██╗██╔════╝██║     
██████╔╝███████║██████╔╝█████╗  ██║     
██╔══██╗██╔══██║██╔══██╗██╔══╝  ██║     
██████╔╝██║  ██║██║  ██║███████╗███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝
                                         
NEXT.JS + SUPABASE DEV CONTAINER
```

# Barel

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A secure Docker development environment for building Next.js applications with Supabase, featuring a comprehensive local development stack.

## Features

- 🐳 Multi-container setup with Docker Compose
- ⚡ Next.js with TypeScript and Tailwind CSS
- 🗄️ Local Supabase instance (PostgreSQL, Auth, Storage, Realtime)
- 🤖 AI coding assistant ready (works with Claude, Cursor, GitHub Copilot)
- 🔒 Network firewall for secure development
- 🎨 Interactive project initialization with optional features
- 📦 Helper scripts for database management
- 🔄 Hot module replacement and live reloading

## Prerequisites

- Docker Desktop installed
- VS Code or Cursor with Dev Containers extension
- Node.js and npm (for key generation script)
- At least 8GB of RAM allocated to Docker

## Quick Start

### Option 1: Automated Setup
```bash
git clone https://github.com/temporarystudios/barel
cd barel
./quick-start.sh
```

### Option 2: Manual Setup

1. **Clone this repository**
   ```bash
   git clone https://github.com/temporarystudios/barel
   cd barel
   ```

2. **Copy environment variables**
   ```bash
   cp .env.example .env
   ```

3. **Generate secure keys**
   ```bash
   ./scripts/generate-keys.sh
   # Copy the generated keys to your .env file
   ```

4. **Open in your editor**
   ```bash
   # For VS Code:
   code .
   
   # For Cursor:
   cursor .
   ```

5. **Reopen in Container**
   - **VS Code**: Press `F1` and select "Dev Containers: Reopen in Container"
   - **Cursor**: Press `Cmd/Ctrl+Shift+P` and select "Dev Containers: Reopen in Container"
   - Wait for the container to build (first time takes ~5-10 minutes)

6. **Initialize a new project**
   ```bash
   ./scripts/init-project.sh
   ```
   
   The initialization script will interactively ask you about:
   - **shadcn/ui** - Modern React component library
   - **Prisma** - Type-safe database ORM
   - **Payment Processing** - Stripe, Paddle, or both
   - **Auth providers** - Google, GitHub, Discord OAuth

## Repository Structure & Workflow

Barel supports multiple workflow strategies for managing your application code. The recommended approach is the **App-Only Repository** workflow:

### Recommended: App-Only Repository

Keep your application code in a separate repository from Barel:

```
my-project/              # Your Barel installation (not in git)
├── docker-compose.yml
├── volumes/
├── scripts/
└── app/                 # Your application (separate git repo)
    ├── .git/           # Your app's repository
    ├── src/
    ├── package.json
    └── ...
```

**Benefits:**
- Clean separation between infrastructure and application
- Smaller repository focused on your code
- Team members can use different development environments
- Easier CI/CD integration

**Setup:**
1. When running `./scripts/init-project.sh`, choose "Yes" when asked about git initialization
2. This creates a separate git repository in the `app/` directory
3. Push your app to its own remote repository

For detailed workflow options and migration guides, see [WORKFLOW_GUIDE.md](./WORKFLOW_GUIDE.md).

## How It Works

When you select "Reopen in Container", the Dev Containers extension:

1. **Builds the Docker images** automatically
2. **Starts all services** (PostgreSQL, Supabase, etc.)
3. **Opens a new window** that's running inside the container
4. **Mounts your code** so changes are reflected in real-time

You don't need to run any Docker commands manually - everything is handled by the extension!

## Container Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Host                           │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │   app       │  │   postgres   │  │    studio     │ │
│  │ (Next.js +  │  │   (DB)       │  │  (Supabase    │ │
│  │  AI Tools)  │  │              │  │   Studio)     │ │
│  └─────────────┘  └──────────────┘  └───────────────┘ │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │    kong     │  │    auth      │  │   realtime    │ │
│  │ (API Gateway)│  │  (GoTrue)    │  │  (WebSocket)  │ │
│  └─────────────┘  └──────────────┘  └───────────────┘ │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │  storage    │  │    rest      │  │ edge-runtime  │ │
│  │  (Files)    │  │ (PostgREST)  │  │  (Functions)  │ │
│  └─────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Service URLs

- **Next.js App**: http://localhost:3000
- **Supabase Studio**: http://localhost:54321
- **Supabase API**: http://localhost:8000
- **PostgreSQL**: postgresql://postgres:your-password@localhost:5432/postgres

## Available Scripts

All scripts are located in the `scripts/` directory:

- `./scripts/generate-keys.sh` - Generate secure JWT keys for Supabase
- `./scripts/check-health.sh` - Check the health of all Supabase services
- `./scripts/db-backup.sh` - Create a database backup
- `./scripts/db-restore.sh <backup-file>` - Restore from a backup
- `./scripts/init-project.sh` - Initialize a new Barel project with optional features
- `./scripts/apply-schema.sh [schema-file]` - Apply database schema/migrations
- `./scripts/init-app-repo.sh` - Initialize a separate git repository for your app

## Using with AI Coding Assistants

Barel works great with AI coding assistants:

- **Claude (via Cursor/Claude.ai)** - The devcontainer mounts Claude configuration
- **GitHub Copilot** - Works in VS Code with the extension
- **Cursor AI** - Native support when using Cursor editor

The `.devcontainer/devcontainer.json` includes proper mounts for Claude configuration.

## Database Management

### Creating Tables

1. Through Supabase Studio (http://localhost:54321)
2. Using SQL files:
   ```bash
   psql -h localhost -p 5432 -U postgres -d postgres < your-schema.sql
   ```

### Backups

Backups are automatically stored in `/workspace/backups/`:

```bash
# Create backup
./scripts/db-backup.sh

# List backups
ls -la backups/

# Restore backup
./scripts/db-restore.sh backups/supabase_backup_20240109_120000.sql
```

## Storage

Local storage files are persisted in Docker volumes. Files uploaded through Supabase Storage API are available at the `/var/lib/storage` path inside the storage container.

## Realtime Subscriptions

Realtime works out of the box. Example usage:

```javascript
const channel = supabase
  .channel('room1')
  .on('presence', { event: 'sync' }, () => {
    console.log('Online users: ', channel.presenceState())
  })
  .subscribe()
```

## Troubleshooting

### Services not starting
```bash
# Check service health
./scripts/check-health.sh

# View logs
docker-compose logs -f <service-name>

# Restart services
docker-compose restart
```

### PostgreSQL pgsodium extension error
If you encounter "FATAL: The getkey script pgsodium_getkey does not exists":
- The quick-start.sh script automatically fixes this issue
- For manual fixes: pgsodium has been removed from shared_preload_libraries
- This doesn't affect core Supabase functionality

### Analytics service (Logflare) issues
The analytics service has been disabled by default due to initialization complexity:
- To enable: uncomment the analytics service in docker-compose.yml
- Ensure LOGFLARE_API_KEY is set in your .env file
- The service requires additional database schema setup

### Database connection issues
```bash
# Test connection
psql -h localhost -p 5432 -U postgres -d postgres -c "SELECT 1"

# Check if port is exposed
docker-compose ps
```

### Permission issues
```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) .
```

## Security Notes

- The firewall blocks all external network access except for:
  - npm registry
  - GitHub
  - Anthropic API
  - Supabase domains
  - Docker internal networks
- All inter-service communication happens within the Docker network
- Sensitive keys should be rotated before production use

## Customization

### Adding new services

Edit `docker-compose.yml` to add new services:

```yaml
services:
  my-service:
    image: my-image:latest
    networks:
      - supabase
    environment:
      - MY_ENV=value
```

### Modifying firewall rules

Edit `.devcontainer/init-firewall.sh` to allow additional domains:

```bash
for domain in \
    "registry.npmjs.org" \
    "your-domain.com"; do
```

## Contributing

Feel free to submit issues and enhancement requests!

## Troubleshooting

### Docker Issues

#### "Cannot connect to the Docker daemon"
This error means Docker Desktop is not running. Solutions:

1. **Start Docker Desktop**:
   - macOS: Open Docker Desktop from Applications
   - Windows: Start Docker Desktop from Start Menu
   - Linux: Run `sudo systemctl start docker`

2. **Check Docker status**:
   ```bash
   ./scripts/check-docker.sh
   ```

3. **If Docker Desktop is running but still getting errors**:
   - Quit and restart Docker Desktop
   - Reset Docker Desktop to factory defaults (Settings → Reset)
   - Ensure your user has permissions to access Docker

#### "Docker Desktop memory insufficient"
Barel requires at least 8GB RAM allocated to Docker:

1. Open Docker Desktop settings
2. Go to Resources → Advanced
3. Increase Memory to at least 8GB
4. Click "Apply & Restart"

### Dev Container Issues

#### "Failed to reopen folder in container" or "Failed to install Cursor server"
This usually means the .env file is missing or not configured:

1. **Create .env file**:
   ```bash
   cp .env.example .env
   ```

2. **For quick start (development only)**:
   The .env.example now contains working development values. Just copy it!

3. **For production use**:
   Generate secure keys:
   ```bash
   ./scripts/generate-keys.sh
   ```
   Then update .env with the generated values.

4. **If still failing**:
   - Ensure Docker is running
   - Check: `./scripts/pre-build-check.sh`
   - Try: Command Palette → "Dev Containers: Rebuild Container"

#### Extension not found in VS Code/Cursor
Install the Dev Containers extension:
- **VS Code**: Search for "Dev Containers" in Extensions
- **Cursor**: Search for "Dev Containers" in Extensions

### Key Generation Issues

#### "jsonwebtoken not found"
Ensure Node.js and npm are installed locally:
```bash
node --version
npm --version
```

If not installed, download from [nodejs.org](https://nodejs.org/)

### Supabase Connection Issues

#### Services not starting
1. Check service health:
   ```bash
   ./scripts/check-health.sh
   ```

2. View logs for specific service:
   ```bash
   docker-compose logs -f <service-name>
   ```

3. Restart all services:
   ```bash
   docker-compose restart
   ```

### Need More Help?

- Check existing [issues](https://github.com/temporarystudios/barel/issues)
- Create a new issue with:
  - Error messages
  - Output of `./scripts/check-docker.sh`
  - Your environment details

## License

MIT