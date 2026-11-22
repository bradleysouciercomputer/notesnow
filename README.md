# NotesNow

A simple cloud-based notes website built with Google's official Material Web components.

## What it does

- Create notes with a title and written content
- Open an existing note to edit it
- Delete a note after confirming in a Material 3 confirmation dialog
- View note details, including word, character, and line counts
- See when each note was created or last edited, with full timestamps in Note details
- Attach multiple files to a note, download them later, or remove them when editing
- Sign up and sign in with an email address and password
- Reset a forgotten password by email
- Store notes in Supabase so they are available across devices
- Keep each account's notes private with PostgreSQL Row Level Security
- Switch between light and dark Material 3 themes

## GitHub Pages

In the repository, open **Settings → Pages** and choose:

- **Source:** Deploy from a branch
- **Branch:** `main`
- **Folder:** `/(root)`

The website is available at:

https://bradleysouciercomputer.github.io/notesnow/

## Supabase setup

The app connects to the **NotesNow** Supabase project using its project URL and publishable key. The publishable key is intended for browser apps; the database enforces note ownership with Row Level Security. Never put a Supabase secret or service-role key in this repository.

The `public.notes` table stores:

- `id`, `user_id`, `title`, and `content`
- `attachments` metadata for files belonging to each note
- `created_at` and `updated_at`

Attachments are stored in the private `note-attachments` Storage bucket. Each file is limited to 50 MB. Storage Row Level Security checks the signed-in user ID and the note ID in the object path before allowing upload, download, or deletion. Deleting a note also removes its stored attachments.

Row Level Security is enabled. Authenticated users can select, insert, update, and delete only rows where `user_id` matches their authenticated user ID.

### Configure authentication redirects

In the Supabase Dashboard, open **Authentication → URL Configuration** and set:

- **Site URL:** `https://bradleysouciercomputer.github.io/notesnow/`
- **Redirect URLs:** add `https://bradleysouciercomputer.github.io/notesnow/`

Email confirmation is enabled by default for hosted Supabase projects. New users need to confirm the email address before signing in when that setting is enabled.

The built-in Supabase email sender is intended for testing: it only sends to project-organization team members and is limited to 2 emails per hour. For general users, configure a custom SMTP provider in Supabase. For a personal prototype where email verification is not needed, you can instead turn off **Confirm email** under **Authentication → Sign In / Providers → Email**. Turning this off allows sign-in without proving ownership of the email address.

## Existing browser notes

When you first sign in, NotesNow checks for notes left by the previous local-storage version. If your new cloud account has no notes yet, it imports those notes into your account once. If the account already contains cloud notes, the older browser notes are left on that device rather than being silently mixed into the account.

## Design and dependencies

The interface uses Google's official `@material/web` components, Roboto, and Material Symbols. Supabase JS is pinned to version `2.119.0`. These dependencies load from public CDNs, so an internet connection is required.
