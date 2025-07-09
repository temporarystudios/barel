#!/bin/bash
set -euo pipefail

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source ASCII art if available
if [ -f "/workspace/scripts/ascii-art.sh" ]; then
    source /workspace/scripts/ascii-art.sh
    show_barel_barrel
else
    echo -e "${CYAN}🚀 Barel Project Initializer${NC}"
    echo -e "${CYAN}===========================${NC}"
fi
echo ""

# Source environment variables
if [ -f "/workspace/.env" ]; then
    echo -e "${BLUE}Loading environment variables...${NC}"
    set -a
    source /workspace/.env
    set +a
else
    echo -e "${RED}❌ .env file not found! Please ensure you're in a Barel devcontainer.${NC}"
    exit 1
fi

# Check if Supabase services are running
echo -e "${BLUE}Checking Supabase services...${NC}"
# Use kong:8000 when inside container, localhost:8000 when on host
if [ -f /.dockerenv ]; then
    # We're inside a container
    SUPABASE_URL="http://kong:8000"
else
    # We're on the host
    SUPABASE_URL="http://localhost:8000"
fi

if ! curl -s $SUPABASE_URL/auth/v1/health -H "apikey: $ANON_KEY" > /dev/null 2>&1; then
    echo -e "${RED}❌ Supabase services are not running!${NC}"
    echo -e "${YELLOW}Please ensure all services are running:${NC}"
    echo -e "${YELLOW}  - From your host machine: docker compose ps${NC}"
    echo -e "${YELLOW}  - All services should show as 'Up' and 'healthy'${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Supabase services are ready${NC}"

# Validate required environment variables
if [ -z "${ANON_KEY:-}" ] || [ -z "${SERVICE_ROLE_KEY:-}" ]; then
    echo -e "${RED}❌ Required environment variables not set!${NC}"
    echo "Please ensure ANON_KEY and SERVICE_ROLE_KEY are set in your .env file"
    exit 1
fi

# Determine project location
if [ -f "/workspace/barel.json" ]; then
    # We're in a Barel devcontainer, create app in subdirectory
    echo -e "${CYAN}Detected Barel environment. Creating project in 'app' directory...${NC}"
    PROJECT_DIR="/workspace/app"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
elif [ "$PWD" != "/workspace" ]; then
    cd /workspace
    PROJECT_DIR="/workspace"
else
    PROJECT_DIR="/workspace"
fi

# Check if package.json already exists in target directory
if [ -f "$PROJECT_DIR/package.json" ]; then
    echo -e "${RED}⚠️  package.json already exists in $PROJECT_DIR. This script is for new projects only.${NC}"
    echo -e "${YELLOW}To start over, remove the existing project: rm -rf $PROJECT_DIR${NC}"
    exit 1
fi

# Interactive configuration
echo -e "${YELLOW}Let's configure your new project:${NC}"
echo ""

# Project configuration
USE_SHADCN="no"
USE_PRISMA="no"
USE_STRIPE="no"
USE_PADDLE="no"
AUTH_PROVIDERS=""

# Ask about shadcn/ui
echo -e "${MAGENTA}Would you like to install shadcn/ui? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    USE_SHADCN="yes"
fi

# Ask about Prisma
echo -e "${MAGENTA}Would you like to install Prisma ORM? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    USE_PRISMA="yes"
fi

# Ask about payment processing
echo -e "${MAGENTA}Would you like to add payment processing?${NC}"
echo "1) No payments"
echo "2) Stripe"
echo "3) Paddle"
echo "4) Both Stripe and Paddle"
read -r payment_choice

case $payment_choice in
    2) USE_STRIPE="yes" ;;
    3) USE_PADDLE="yes" ;;
    4) USE_STRIPE="yes"; USE_PADDLE="yes" ;;
    *) ;; # No payments
esac

# Ask about auth providers
echo -e "${MAGENTA}Which auth providers would you like to configure?${NC}"
echo "1) Email/Password only"
echo "2) Email/Password + Google"
echo "3) Email/Password + GitHub"
echo "4) Email/Password + Google + GitHub"
echo "5) All providers (Email, Google, GitHub, Discord)"
read -r auth_choice

case $auth_choice in
    1) AUTH_PROVIDERS="email" ;;
    2) AUTH_PROVIDERS="email,google" ;;
    3) AUTH_PROVIDERS="email,github" ;;
    4) AUTH_PROVIDERS="email,google,github" ;;
    5) AUTH_PROVIDERS="email,google,github,discord" ;;
    *) AUTH_PROVIDERS="email" ;;
esac

echo ""
echo -e "${GREEN}Configuration selected! Starting project setup...${NC}"
echo ""

# Create Next.js project
echo -e "${BLUE}📦 Creating Next.js project...${NC}"
cd "$PROJECT_DIR"
npx create-next-app@latest . \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --no-git

# Install Supabase dependencies
echo -e "${BLUE}📦 Installing Supabase dependencies...${NC}"
npm install @supabase/supabase-js @supabase/ssr

# Install development dependencies
echo -e "${BLUE}📦 Installing development dependencies...${NC}"
npm install -D @types/node encoding

# Optional: Install shadcn/ui
if [ "$USE_SHADCN" = "yes" ]; then
    echo -e "${BLUE}📦 Installing shadcn/ui...${NC}"
    npx shadcn@latest init -y
    npx shadcn@latest add button card dialog form input label
fi

# Optional: Install Prisma
if [ "$USE_PRISMA" = "yes" ]; then
    echo -e "${BLUE}📦 Installing Prisma...${NC}"
    npm install -D prisma
    npm install @prisma/client
    npx prisma init
fi

# Optional: Install Stripe
if [ "$USE_STRIPE" = "yes" ]; then
    echo -e "${BLUE}📦 Installing Stripe...${NC}"
    npm install stripe @stripe/stripe-js
fi

# Optional: Install Paddle
if [ "$USE_PADDLE" = "yes" ]; then
    echo -e "${BLUE}📦 Installing Paddle...${NC}"
    npm install @paddle/paddle-js
fi

# Create project structure
echo -e "${BLUE}📁 Creating project structure...${NC}"
mkdir -p src/lib/supabase src/components/ui src/hooks src/types src/app/api

# Create Supabase client utilities
echo -e "${BLUE}📝 Creating Supabase client utilities...${NC}"

# Client component utility
cat > src/lib/supabase/client.ts << 'EOF'
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
EOF

# Server component utility
cat > src/lib/supabase/server.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
EOF

# Create environment variables
echo -e "${BLUE}📝 Creating environment variables...${NC}"
cat > .env.local << EOF
# Supabase
NEXT_PUBLIC_SUPABASE_URL=http://localhost:8000
NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY}
SUPABASE_SERVICE_KEY=${SERVICE_ROLE_KEY}

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF

# Add Stripe env vars if selected
if [ "$USE_STRIPE" = "yes" ]; then
    cat >> .env.local << EOF

# Stripe
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=
EOF
fi

# Add Paddle env vars if selected
if [ "$USE_PADDLE" = "yes" ]; then
    cat >> .env.local << EOF

# Paddle
PADDLE_VENDOR_ID=
PADDLE_API_KEY=
PADDLE_PUBLIC_KEY=
NEXT_PUBLIC_PADDLE_VENDOR_ID=
NEXT_PUBLIC_PADDLE_SANDBOX=true
PADDLE_WEBHOOK_SECRET=
EOF
fi

# Add OAuth env vars based on selection
if [[ "$AUTH_PROVIDERS" == *"google"* ]]; then
    cat >> .env.local << EOF

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
EOF
fi

if [[ "$AUTH_PROVIDERS" == *"github"* ]]; then
    cat >> .env.local << EOF

# GitHub OAuth
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
EOF
fi

if [[ "$AUTH_PROVIDERS" == *"discord"* ]]; then
    cat >> .env.local << EOF

# Discord OAuth
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
EOF
fi

# Create middleware for auth
echo -e "${BLUE}📝 Creating middleware...${NC}"
cat > src/middleware.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: DO NOT REMOVE auth.getUser()
  const { data: { user } } = await supabase.auth.getUser()

  if (
    !user &&
    !request.nextUrl.pathname.startsWith('/login') &&
    !request.nextUrl.pathname.startsWith('/auth')
  ) {
    // no user, potentially respond by redirecting the user to the login page
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
EOF


# Create database schema
echo -e "${BLUE}📝 Creating database schema...${NC}"
mkdir -p "$PROJECT_DIR/supabase"
cat > "$PROJECT_DIR/supabase/schema.sql" << 'EOF'
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users profile table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
EOF

# Add payment tables if any payment provider is selected
if [ "$USE_STRIPE" = "yes" ] || [ "$USE_PADDLE" = "yes" ]; then
    cat >> supabase/schema.sql << 'EOF'

-- Payment customers table (supports multiple providers)
CREATE TABLE IF NOT EXISTS payment_customers (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  stripe_customer_id TEXT UNIQUE,
  paddle_customer_id TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Subscriptions table (provider-agnostic)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  provider TEXT NOT NULL CHECK (provider IN ('stripe', 'paddle')),
  provider_subscription_id TEXT NOT NULL,
  provider_price_id TEXT NOT NULL,
  status TEXT NOT NULL,
  current_period_start TIMESTAMP WITH TIME ZONE,
  current_period_end TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(provider, provider_subscription_id)
);

-- Enable RLS
ALTER TABLE payment_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own payment data" ON payment_customers
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can view their own subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);
EOF
fi

# Create login page with server actions
echo -e "${BLUE}📝 Creating auth pages...${NC}"
mkdir -p src/app/login
cat > src/app/login/page.tsx << 'EOF'
import { login, signup } from './actions'

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>
}) {
  const params = await searchParams
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <div className="w-full max-w-md space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
            Sign in to your account
          </h2>
          {params?.error && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
              <p className="text-sm text-red-600">{params.error}</p>
            </div>
          )}
        </div>
        <form className="mt-8 space-y-6">
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email" className="sr-only">
                Email address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
              />
            </div>
          </div>

          <div className="flex gap-4">
            <button
              formAction={login}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Sign in
            </button>
            <button
              formAction={signup}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Sign up
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# Create server actions for auth
cat > src/app/login/actions.ts << 'EOF'
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

export async function login(formData: FormData) {
  const supabase = await createClient()

  const data = {
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  }

  const { error } = await supabase.auth.signInWithPassword(data)

  if (error) {
    redirect('/error')
  }

  revalidatePath('/', 'layout')
  redirect('/')
}

export async function signup(formData: FormData) {
  const supabase = await createClient()

  const data = {
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  }

  const { error } = await supabase.auth.signUp(data)

  if (error) {
    redirect('/error')
  }

  revalidatePath('/', 'layout')
  redirect('/')
}
EOF

# Create auth callback route
mkdir -p src/app/auth/callback
cat > src/app/auth/callback/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const origin = requestUrl.origin

  if (code) {
    const supabase = await createClient()
    await supabase.auth.exchangeCodeForSession(code)
  }

  return NextResponse.redirect(`${origin}/`)
}
EOF

# Update root layout
echo -e "${BLUE}📝 Updating root layout...${NC}"
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Barel App",
  description: "Built with Barel - Next.js + Supabase development environment",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF

# Create a simple home page
echo -e "${BLUE}📝 Creating home page...${NC}"
cat > src/app/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function Home() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  return (
    <div className="min-h-screen p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-4">Welcome back!</h1>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          You are logged in as: {user.email}
        </p>
        <form action="/auth/signout" method="post">
          <button
            type="submit"
            className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          >
            Sign Out
          </button>
        </form>
      </div>
    </div>
  )
}
EOF

# Create sign out route
mkdir -p src/app/auth/signout
cat > src/app/auth/signout/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const supabase = await createClient()
  await supabase.auth.signOut()
  
  revalidatePath('/', 'layout')
  return NextResponse.redirect(new URL('/login', request.url))
}
EOF

echo ""

# Apply database schema
echo -e "${BLUE}📊 Applying database schema...${NC}"

# Determine database host based on environment
if [ -f /.dockerenv ]; then
    # We're inside a container, use the service name
    DB_HOST="db"
    AUTH_URL="http://auth:9999/health"
else
    # We're on the host, use localhost
    DB_HOST="localhost"
    AUTH_URL="http://localhost:9999/health"
fi

# Wait for auth service to be ready
echo -e "${YELLOW}Waiting for auth service...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s "$AUTH_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Auth service is ready${NC}"
        break
    fi
    echo -n "."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 2
done
echo ""

# Ensure PostgreSQL client is installed
if ! command -v psql >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing PostgreSQL client...${NC}"
    apt-get update -qq && apt-get install -y -qq postgresql-client
fi

# Apply the schema with retry logic
SCHEMA_APPLIED=false
for i in {1..3}; do
    echo -e "${BLUE}Applying database schema (attempt $i/3)...${NC}"
    
    # First ensure auth schema exists
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p 5432 -U postgres -d postgres -c "CREATE SCHEMA IF NOT EXISTS auth;" 2>/dev/null || true
    
    # Apply the app schema
    if PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p 5432 -U postgres -d postgres < "$PROJECT_DIR/supabase/schema.sql"; then
        echo -e "${GREEN}✅ Database schema applied successfully!${NC}"
        SCHEMA_APPLIED=true
        break
    else
        echo -e "${YELLOW}⚠️  Schema application failed, retrying in 5 seconds...${NC}"
        sleep 5
    fi
done

if [ "$SCHEMA_APPLIED" = false ]; then
    echo -e "${RED}❌ Failed to apply database schema after 3 attempts${NC}"
    echo -e "${RED}This is a critical error - authentication will not work without the schema${NC}"
    echo -e "${YELLOW}Please check the logs and ensure the database is accessible${NC}"
    exit 1
fi

# Git repository initialization
echo -e "${MAGENTA}Would you like to initialize a git repository for your app? (y/n)${NC}"
echo -e "${CYAN}This creates a separate git repo in the app/ directory${NC}"
echo -e "${CYAN}(Recommended for the 'App-Only Repository' workflow)${NC}"
read -r git_response
if [[ "$git_response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Initializing git repository...${NC}"
    if [ -f "/workspace/scripts/init-app-repo.sh" ]; then
        /workspace/scripts/init-app-repo.sh
    else
        # Fallback if script not found
        cd "$PROJECT_DIR"
        git init
        git add .
        git commit -m "Initial commit" || true
        echo -e "${GREEN}✓ Git repository initialized${NC}"
        cd - > /dev/null
    fi
fi

echo ""
if [ -f "/workspace/scripts/ascii-art.sh" ]; then
    show_success
else
    echo -e "${GREEN}✅ Project initialization complete!${NC}"
    echo ""
fi
echo -e "${YELLOW}Next steps:${NC}"
if [ "$PROJECT_DIR" = "/workspace/app" ]; then
    echo "1. cd app"
    echo "2. Run 'npm run dev' to start the development server"
else
    echo "1. Run 'npm run dev' to start the development server"
fi
echo "3. Visit http://localhost:3000 to see your app"
echo "4. Visit http://localhost:54321 for Supabase Studio"

if [ "$USE_SHADCN" = "yes" ]; then
    echo ""
    echo -e "${CYAN}📚 shadcn/ui installed! Check out: https://ui.shadcn.com/docs${NC}"
fi

if [ "$USE_PRISMA" = "yes" ]; then
    echo ""
    echo -e "${CYAN}📚 Prisma installed! Next steps:${NC}"
    echo "   - Update prisma/schema.prisma with your models"
    echo "   - Run 'npx prisma db push' to sync with database"
fi

if [ "$USE_STRIPE" = "yes" ]; then
    echo ""
    echo -e "${CYAN}💳 Stripe installed! Don't forget to:${NC}"
    echo "   - Add your Stripe keys to .env.local"
    echo "   - Set up webhooks at https://dashboard.stripe.com"
fi

if [ "$USE_PADDLE" = "yes" ]; then
    echo ""
    echo -e "${CYAN}🚣 Paddle installed! Don't forget to:${NC}"
    echo "   - Add your Paddle credentials to .env.local"
    echo "   - Set up webhooks at https://vendors.paddle.com"
    echo "   - Configure sandbox mode for development"
fi

if [[ "$AUTH_PROVIDERS" != "email" ]]; then
    echo ""
    echo -e "${CYAN}🔐 OAuth providers selected! Configure them in:${NC}"
    echo "   - Supabase Dashboard: http://localhost:54321"
    echo "   - Add OAuth credentials to .env.local"
fi