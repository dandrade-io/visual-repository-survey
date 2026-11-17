# Search satisfaction survey

Survey to compare user satisfaction with the semantic image search engine using
**JinaCLIP v2** vs **SigLIP 2**. Each participant enters their name, institutional
email and career, then evaluates 12 randomly selected images. For each image and
each model they report:

- number of queries needed to find the image (1–100), plus a "couldn't find it" flag
- satisfaction with the results (1 = none … 5 = very satisfied)

Stack: Svelte 5 + Vite (static site on GitHub Pages) and Supabase (free tier) for storage.

## 1. Supabase

1. Create a project at <https://supabase.com>.
2. Apply the schema ([`supabase/migrations/`](supabase/migrations/)) with the CLI:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>   # asks for the DB password
   supabase db push
   ```
   (Or paste the migration file into the dashboard's SQL Editor and run it.)
3. Project Settings → API: copy the **Project URL** and the **anon / publishable key**.

The anon key is public by design. Row Level Security only allows it to *insert*
rows, so nobody can read the answers from the website. You read them in the
dashboard (Table Editor → `results` view → Export CSV).

## 2. Local development

```bash
cp .env.example .env.local   # fill in the two values
npm install
npm run dev
```

Without `.env.local` the app still runs in "test mode" (it shows a banner and saves nothing).

## 3. Deploy to GitHub Pages

1. Create a GitHub repo and push this folder to `main`.
2. Repo → Settings → Secrets and variables → Actions → add the secrets
   `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
3. Repo → Settings → Pages → Source: **GitHub Actions**.
4. Every push to `main` runs [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml),
   which builds the site and publishes it to `https://<user>.github.io/<repo>/`.

## Images

The originals live in `images/` (git-ignored, ~147 MB). `npm run prepare-images`
(macOS, uses `sips`) resizes them to `public/images/img-XXX.jpg` and regenerates
`public/images.json`, which maps each id to its original filename. Both the id
and the original filename are stored with every response.

## Settings

See [`src/config.js`](src/config.js): images per participant, allowed email
domains, model labels, satisfaction labels, and an optional link to the search engine.
