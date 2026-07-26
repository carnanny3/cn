# Deploying Car Nanny (GitHub + Railway)

This covers the backend API only — that's the piece that needs a server.
The admin dashboard is a static build (deploy it later, e.g. to Netlify/Vercel,
once the backend URL is live). The mobile app just needs to be rebuilt
pointing at the deployed backend URL (last step below).

Everything here is a step **you** run yourself — account creation and
pushing code needs your own credentials, which Claude can't handle for you.

## 1. Create a GitHub account

Go to [github.com/signup](https://github.com/signup) and create an account
if you don't have one yet.

## 2. Create a new GitHub repository

1. Click **New repository** (top-right `+` menu, or [github.com/new](https://github.com/new)).
2. Name it `car-nanny` (or anything you like).
3. Set visibility to **Public**.
4. **Do not** check "Add a README" / .gitignore / license — this repo
   already has all of that. Click **Create repository**.
5. GitHub will show you a page with a URL like
   `https://github.com/<your-username>/car-nanny.git` — copy it.

## 3. Push this local repo to GitHub

The local repo is already initialized and committed (`git log` shows one
commit: "Initial commit: Car Nanny MVP"). From `D:\MY CLAUDE\car-nanny`, run:

```bash
git remote add origin https://github.com/<your-username>/car-nanny.git
git branch -M main
git push -u origin main
```

Replace `<your-username>` with your actual GitHub username. GitHub will
prompt you to sign in (browser popup or a personal access token) — follow
its prompts.

## 4. Create a Railway account

Go to [railway.app](https://railway.app) and sign up — signing up with your
GitHub account is easiest since Railway needs GitHub access anyway to deploy
from your repo.

## 5. Create a new Railway project

1. From the Railway dashboard, click **New Project**.
2. Choose **Deploy from GitHub repo**.
3. Authorize Railway to access your GitHub account if prompted, then select
   the `car-nanny` repo you just pushed.
4. Railway will create a service and try to build it — **before it finishes**,
   go to that service's **Settings** tab and set:
   - **Root Directory**: `backend`
   - This tells Railway to build/run only the `backend/` folder (this repo
     is a monorepo with backend, mobile, admin, and brand all in one place).
     Railway will detect the `Dockerfile` in `backend/` automatically once
     the root directory is set.
5. Trigger a redeploy if it doesn't happen automatically (Settings usually
   trigger one on save).

## 6. Add a Postgres database

1. In the same Railway project, click **New** → **Database** → **Add PostgreSQL**.
2. Railway provisions a Postgres instance and exposes a `DATABASE_URL`
   variable automatically.
3. Go to your **backend service** → **Variables** tab → **New Variable** →
   use the "reference" option to link `DATABASE_URL` from the Postgres
   service (Railway calls this "Add Reference" or similar — it inserts
   `${{Postgres.DATABASE_URL}}` so the value always matches the current DB).

## 7. Set the remaining environment variables

On the backend service's **Variables** tab, add:

| Variable | Value | Notes |
|---|---|---|
| `NODE_ENV` | `production` | |
| `JWT_ACCESS_SECRET` | *(a long random string — see below)* | **Do not** leave this unset — the code falls back to a hardcoded dev secret (`'dev-access-secret'`) if missing, which is insecure in production. |
| `STRIPE_SECRET_KEY` | *(leave unset)* | Optional — payments run in a safe dev-simulation mode without it. |

`PORT` and `DATABASE_URL` are provided by Railway automatically — don't set
them manually.

**To generate a strong `JWT_ACCESS_SECRET`**, run this yourself in a
terminal you have (PowerShell):

```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
```

Copy the output and paste it as the variable value in Railway. Keep it
private — anyone with this value can forge valid login tokens for your app.

## 8. Verify the deployment

Once Railway finishes building and deploying (watch the **Deployments** tab
for logs — you should see `prisma migrate deploy` run, then `Car Nanny API
listening on...`), Railway gives you a public URL under **Settings** →
**Networking** → **Generate Domain** if one isn't already assigned
(something like `car-nanny-backend-production.up.railway.app`).

Check it works by opening, in a browser:

```
https://<your-railway-domain>/api/docs
```

You should see the Swagger UI for the Car Nanny API. If it doesn't load,
check the **Deployments** → **Logs** tab in Railway for the error.

## 9. Point the mobile app at the live backend

Once you have a working Railway URL, rebuild the Android APK against it
(from `D:\MY CLAUDE\car-nanny\mobile`):

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<your-railway-domain>/api/v1
```

The new APK lands at `mobile/build/app/outputs/flutter-apk/app-release.apk`.

**Also remove the cleartext-traffic workaround** now that the backend is
served over HTTPS: in
`mobile/android/app/src/main/AndroidManifest.xml`, delete the
`android:usesCleartextTraffic="true"` attribute (it was only needed for the
local `http://` testing setup — see `mobile/README.md` for why) — then
rebuild.

## 10. Deploy the admin dashboard (Netlify)

The admin dashboard (`admin/`) is a static site (React + Vite), so it deploys
separately from the backend — Netlify's free tier is a good fit.

A `netlify.toml` at the repo root already declares the build settings
(`base = "admin"`, `command = "npm run build"`, `publish = "dist"`) and the
SPA redirect rule React Router needs (without it, refreshing any page other
than the root 404s). Netlify reads this automatically, so the only manual
steps are creating the site and setting the API URL:

1. Go to [app.netlify.com/signup](https://app.netlify.com/signup) and create
   an account (GitHub sign-in is easiest, same account you used for the
   `cn` repo).
2. From the Netlify dashboard, click **Add new site** → **Import an existing
   project** → **Deploy with GitHub**.
3. Authorize Netlify to access GitHub if prompted, then pick the `cn` repo.
4. On the build settings screen, leave the fields as Netlify auto-fills them
   from `netlify.toml` (base `admin`, publish `dist`) — **do not** set
   Publish directory to `admin/dist` here; since Base directory is already
   `admin`, Netlify resolves Publish directory relative to it, so `admin/dist`
   actually points at the non-existent `admin/admin/dist` and serves
   "Page not found".
5. Before deploying, add an environment variable (there's a "New variable"
   option on that same screen, or under **Site configuration** →
   **Environment variables** after the site is created):
   - `VITE_API_BASE_URL` = `https://cn-production-5a70.up.railway.app/api/v1`
6. Click **Deploy**. Netlify builds it and gives you a URL like
   `https://random-name-123abc.netlify.app` — that's your admin dashboard's
   public link. You can rename it under **Site configuration** → **Change
   site name** for something more memorable, like `car-nanny-admin`.
7. Log in with `admin@carnanny.app` / `CarNanny123!` (the account seeded in
   step 6 above) — **change this password** once you're in, via a real admin
   account-management flow if/when one exists, or ask for a password change
   endpoint to be added.

**If your existing site already shows "Page not found":** go to **Site
configuration** → **Build & deploy** → **Build settings**, check the Publish
directory — if it says `admin/dist`, change it to `dist` — then trigger
**Deploys** → **Trigger deploy** → **Deploy site** (or push any commit).

Every future `git push` to `main` that touches `admin/` will auto-redeploy.
