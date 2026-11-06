# InstantDB backend for G-spend

The Flutter app (`lib/`) talks to the self-hosted InstantDB instance at
`https://api.instantdb.site`. Development and production currently use app ID
`2484bc3c-a671-4b98-b53b-c244f95871d5`. The
server-authoritative schema/perms live at the **repo root** (`instant.schema.ts`,
`instant.perms.ts`) so the CLI/MCP resolve them by default.

## One-time setup

1. Put the runtime configuration in `.env.dev` and `.env.prod` at the repo root:
   ```
   INSTANTDB_APP_ID=2484bc3c-a671-4b98-b53b-c244f95871d5
   INSTANTDB_API_URI=https://api.instantdb.site
   ```
2. Export a valid CLI token in the shell. Never add it to either `.env` file,
   because Flutter bundles those files in the application:
   ```bash
   export INSTANT_CLI_AUTH_TOKEN='your-cli-token'
   ```
3. Push schema + permissions (Node 18+ required):
   ```bash
   INSTANT_CLI_API_URI=https://api.instantdb.site \
   INSTANT_CLI_DASH_URI=https://dash.instantdb.site \
   npx instant-cli@latest push schema --app 2484bc3c-a671-4b98-b53b-c244f95871d5

   INSTANT_CLI_API_URI=https://api.instantdb.site \
   INSTANT_CLI_DASH_URI=https://dash.instantdb.site \
   npx instant-cli@latest push perms --app 2484bc3c-a671-4b98-b53b-c244f95871d5
   ```

## Model notes

- Auth is **passwordless magic-code** (`db.auth.sendMagicCode` / `verifyMagicCode`).
- Every relation is written twice by the client: a scalar id attribute (for
  `where` filtering) and a real link (for permission `data.ref(...)` traversal).
- `categories` with `ownerId == null` are global defaults, readable by everyone.
- Permissions enforce: creator/owner/member visibility on expenses, owner-only
  project + membership management — the server-side replacement for the app's
  former client-side push-authorization gate.

## Expense receipts

Before releasing the receipt UI, push **both** the schema and permissions above.
The existing Storage service alone is not sufficient: `expenseFiles` links
`expenses.files` to `$files.expense`, and `$files` permissions protect downloads.
Uploads use `<user-id>/<expense-id>/<random-id>/<filename>` to avoid overwrites.
The mobile client accepts photos or files up to 10 MiB, opens signed download
URLs, and allows creators/project owners to remove attachments. Members can read
receipts on expenses they can view. Failed linking attempts delete the upload.

The upload flow requires a network connection. Validate camera permissions,
photo-library selection, document selection, and shared-project access on a
real device after deployment. Files are removed through the receipt screen;
expense deletion does not currently clean up its stored files.
