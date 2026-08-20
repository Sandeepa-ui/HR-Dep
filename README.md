# Office Inventory Management

A browser-based office inventory and buddy reward management application.

## Run locally

Open `index.html` in a browser. The application uses browser storage for its local data and loads third-party libraries from public CDNs.

## Publish with GitHub Pages

1. Create a new GitHub repository.
2. Upload all project files, keeping `index.html` in the repository root.
3. Commit and push the files to the `main` branch.
4. Open the repository's **Settings > Pages** and choose **GitHub Actions** as the source.
5. Wait for the **Deploy static site to GitHub Pages** workflow to finish.

The published site will be available from the repository's **Settings > Pages** page.

## Database

GitHub Pages only hosts static files; it does not run a database. The project includes [database.sql](database.sql), which is compatible with PostgreSQL and Supabase.

To create the database:

1. Create a project on Supabase or another PostgreSQL provider.
2. Open its SQL editor.
3. Paste the contents of `database.sql` and run it.
4. Open [supabase-config.js](supabase-config.js) and set `url` and `anonKey` from Supabase **Project Settings > API**.
5. Upload `supabase-config.js` with the rest of the project and redeploy GitHub Pages.

Once configured, the app reads and writes shared users, inventory, and buddy data and refreshes it every 10 seconds. Without configuration it continues using browser `localStorage`.

The current custom login is a compatibility bridge and stores passwords in the shared JSON state. Do not use real passwords until the login is migrated to Supabase Auth and the permissive compatibility policy is replaced with authenticated row-level security policies.

## Important note

This is a client-side application. Login accounts and application data are stored in the browser's local storage and are not shared between users or devices. Do not use real passwords or confidential information without adding a secure backend.