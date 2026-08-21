# Office Inventory Management

A browser-based office inventory, recruitment, and buddy reward management application.

## Run locally

Open `index.html` in a browser. The application uses browser storage for its local data and loads third-party libraries from public CDNs.

The default local compatibility account is `admin` / `admin123` when no shared users have been created yet. Change or remove this account before using the application with real data.

## User access management

Administrators can open **User Management** and edit **Accessible Pages** in two steps:

1. Select the user's main tabs, such as Liquor and Beverages, Buddy System Reward, or Recruitment.
2. Select the subfolders belonging to a chosen main tab, then use **Back** to choose another main tab if needed.

Permissions are stored as stable page IDs in the user's `permissions` JSON array. The two-step editor changes the interface only; it remains compatible with existing local storage and the `shared_app_state` Supabase record.

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

Once configured, the app reads the latest shared users, inventory, and buddy data when the web page loads and writes changes to the database. It does not automatically refresh while the page is open; manually refresh the browser page to load updates made by other users. Without configuration it continues using browser `localStorage`.

The browser client uses the `shared_app_state` table for this compatibility bridge. Run the complete [database.sql](database.sql) script before enabling cloud sync. The SQL script enables permissive policies for this prototype; replace them with authenticated Supabase Auth and least-privilege row-level security policies before production use.

The current custom login is a compatibility bridge and stores passwords in the shared JSON state. Do not use real passwords until the login is migrated to Supabase Auth and the permissive compatibility policy is replaced with authenticated row-level security policies.

`supabase-config.js` contains only the browser-safe publishable/anon key. Never place a Supabase service-role key or any other secret in that file.

## Important note

This is a client-side application. Login accounts and application data are stored in the browser's local storage and are not shared between users or devices. Do not use real passwords or confidential information without adding a secure backend.
