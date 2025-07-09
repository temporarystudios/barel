# Barel Workflow Guide

This guide explains how to effectively use Barel in your development workflow and manage your application code with version control.

## Repository Strategies

### Option 1: App-Only Repository (Recommended)

This approach keeps your application code separate from the Barel infrastructure, treating Barel as a development environment rather than part of your application.

**Advantages:**
- Clean separation of concerns
- Smaller repository size
- Easier CI/CD integration
- Cleaner commit history focused on your app
- Team members can choose their own development environment

**Setup:**
```bash
# 1. Clone Barel
git clone https://github.com/temporarystudios/barel.git my-project-env
cd my-project-env

# 2. Run quick start
./quick-start.sh

# 3. Initialize your project
./scripts/init-project.sh

# 4. When prompted, choose to initialize a separate git repository
# This creates a new git repo in the app/ directory

# 5. Your app is now its own repository!
cd app
git remote add origin https://github.com/yourusername/your-app.git
git push -u origin main
```

**Directory Structure:**
```
my-project-env/          # Barel (not in your app's git)
├── .git/               # Barel's git (can be deleted)
├── docker-compose.yml
├── volumes/
├── scripts/
└── app/                # Your application
    ├── .git/           # Your app's git repository
    ├── src/
    ├── package.json
    └── ...
```

### Option 2: Monorepo Approach

Include Barel as part of your application repository.

**Advantages:**
- Everything in one place
- Reproducible environment for all team members
- Infrastructure as code

**Disadvantages:**
- Larger repository
- Infrastructure changes mixed with app changes
- May include unnecessary files for production

**Setup:**
```bash
# 1. Clone Barel
git clone https://github.com/temporarystudios/barel.git my-project
cd my-project

# 2. Remove Barel's git history
rm -rf .git

# 3. Initialize your own repository
git init
git add .
git commit -m "Initial commit with Barel infrastructure"

# 4. Run quick start and init
./quick-start.sh
./scripts/init-project.sh

# 5. Add your remote
git remote add origin https://github.com/yourusername/your-project.git
git push -u origin main
```

### Option 3: Gitignore App Directory

A hybrid approach where you keep Barel in your repo but gitignore the app directory.

**Setup:**
```bash
# Add to .gitignore
app/
!app/.env.example
!app/README.md
```

## Deployment Considerations

### App-Only Repository
Your production deployment only needs your app code:
```yaml
# .github/workflows/deploy.yml
- uses: actions/checkout@v3  # Checks out only your app
- run: npm ci
- run: npm run build
- run: npm run deploy
```

### Monorepo Approach
You'll need to specify the app directory:
```yaml
# .github/workflows/deploy.yml
- uses: actions/checkout@v3
- run: cd app && npm ci
- run: cd app && npm run build
- run: cd app && npm run deploy
```

## Team Collaboration

### App-Only Repository
Team members can choose their development environment:
```bash
# Developer A uses Barel
git clone https://github.com/temporarystudios/barel.git
git clone https://github.com/team/app.git barel/app

# Developer B uses their own setup
git clone https://github.com/team/app.git
# Uses their preferred local development environment
```

### Monorepo Approach
Everyone uses the same environment:
```bash
# All developers
git clone https://github.com/team/project.git
cd project
./quick-start.sh
```

## Updating Barel

### App-Only Repository
```bash
# Update Barel without affecting your app
cd my-project-env
git pull origin main  # If you kept Barel's git
# Or manually download updates
```

### Monorepo Approach
```bash
# Manually merge updates from Barel
git remote add barel https://github.com/temporarystudios/barel.git
git fetch barel
git merge barel/main --allow-unrelated-histories
# Resolve conflicts if any
```

## Best Practices

1. **Environment Variables**: Never commit `.env` files. Use `.env.example` as a template.

2. **Database Backups**: Before major updates, backup your database:
   ```bash
   ./scripts/db-backup.sh
   ```

3. **Volume Data**: The `volumes/` directory contains your database data. Back it up regularly but don't commit it.

4. **Secrets Management**: Use a proper secrets management system for production. Barel's generated keys are for development only.

5. **Docker Images**: Consider creating custom Docker images for production based on Barel's configuration.

## Quick Decision Guide

Choose **App-Only Repository** if:
- You want a clean separation between infrastructure and application
- You're building a production application
- You need flexible deployment options
- Team members may use different development environments

Choose **Monorepo** if:
- You want everything in one place
- Your entire team will use Barel
- You want to version control your development environment
- You're building a proof of concept or internal tool

## Migration Between Approaches

### From Monorepo to App-Only
```bash
cd app
git init
git add .
git commit -m "Extract app from monorepo"
git remote add origin https://github.com/yourusername/app.git
git push -u origin main

# Update parent repo's .gitignore
cd ..
echo "app/" >> .gitignore
git add .gitignore
git commit -m "Ignore app directory"
```

### From App-Only to Monorepo
```bash
# In Barel directory
cd app
rm -rf .git  # Remove app's git
cd ..
git add app/
git commit -m "Include app in monorepo"
```