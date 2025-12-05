Onboarding Guide

1. Change into the service folder

   ```bash
   cd record-service
   ```

   Run this from the repository root so subsequent commands run in the service folder.

2. Install Node dependencies

   ```bash
   npm install
   ```

3. Create a local `.env` from the example (pick the command for your shell)

   PowerShell (Windows) — overwrites if `.env` already exists:

   ```powershell
   Copy-Item -Path '.\.env.example' -Destination '.\.env' -Force
   ```

   cmd.exe (Windows):

   ```cmd
   copy /Y ".env.example" ".env"
   ```

   Bash / Linux / macOS — do not overwrite an existing `.env`:

   ```bash
   cp -n .env.example .env
   ```

4. Start required containers (if using Docker)

   ```bash
   docker compose up
   ```

   Start any required containers (database or other services). Use `-d` to run detached if you prefer:

   ```bash
   docker compose up -d
   ```

5. Generate Prisma client

   ```bash
   npx prisma generate
   ```

   Generate the Prisma client after the database is available and `DATABASE_URL` is set in `.env`.

6. Start the service in development mode

   ```bash
   npm run dev
   ```

   Start the service in development/watch mode.
