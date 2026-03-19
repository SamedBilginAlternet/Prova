# Prova — Day-by-Day Setup Guide

## Day 0: Project Bootstrap

### 1. Create Supabase Project
1. Go to supabase.com → New Project
2. Name: `prova-prod`, region: `eu-central-1` (Frankfurt — closest to Turkey)
3. Save your DB password somewhere safe

### 2. Get Credentials
From Supabase Dashboard → Settings → API:
- Copy **Project URL**
- Copy **anon public** key
- Copy **service_role** key (keep secret!)

### 3. Run Migrations
```bash
# Using Supabase CLI
supabase link --project-ref YOUR_PROJECT_REF
supabase db push

# Or paste migration SQL directly in Supabase SQL editor:
# supabase/migrations/001_initial_schema.sql
# supabase/migrations/003_storage_policies.sql
```

### 4. Create Storage Buckets
In Supabase Dashboard → Storage:
- Create `user-photos` (Private)
- Create `garment-images` (Public)
- Create `tryon-results` (Private)

### 5. Deploy Edge Function
```bash
supabase functions deploy trigger-tryon
supabase functions deploy ai-stylist
supabase secrets set HF_TOKEN=hf_your_token_here
supabase secrets set GEMINI_API_KEY=your_gemini_key_here
# Get Gemini key free at: aistudio.google.com/app/apikey
```

Get HF token: huggingface.co → Settings → Access Tokens → New token (read)

### 6. Enable Google Auth (optional for MVP)
Supabase Dashboard → Auth → Providers → Google
- Follow OAuth setup guide

### 7. Enable Realtime
Supabase Dashboard → Database → Replication → Add `tryon_jobs` table

---

## Day 1: Flutter Setup

```bash
# Install Flutter (if needed)
# flutter.dev/docs/get-started/install

# Get dependencies
cd /workspace/prova
flutter pub get

# Generate code (Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# Add font files to assets/fonts/:
# DMSans-Regular.ttf, DMSans-Medium.ttf, DMSans-SemiBold.ttf, DMSans-Bold.ttf
# Download from: fonts.google.com/specimen/DM+Sans

# Run on simulator
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## Day 2: Seed Garments

1. Upload garment images to `garment-images` bucket
   - Path: `{garment_name}/original.jpg` and `{garment_name}/thumb.jpg`
2. Run `002_seed_garments.sql` with correct `storage_path` values
3. Verify garments appear in app

---

## Day 3: Test AI Integration

```bash
# Test Edge Function locally
supabase functions serve trigger-tryon --env-file .env.local

# .env.local content:
# SUPABASE_URL=https://xxx.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=xxx
# HF_TOKEN=hf_xxx

# Test with curl
curl -X POST http://localhost:54321/functions/v1/trigger-tryon \
  -H "Authorization: Bearer YOUR_USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"photo_id": "UUID", "garment_id": "UUID"}'
```

---

## Common Issues

**HF Space not responding:** Space may be sleeping. First request takes 30-60s to wake up. This is normal for free tier Spaces.

**Long queue times:** Peak hours (evenings UTC) have longer queues. Add a friendly waiting message in loading screen.

**Image quality:** IDM-VTON works best with:
- Person: clear, front-facing, plain background, good lighting
- Garment: flat-lay or mannequin, white/neutral background, full garment visible

**CORS errors:** Check that `trigger-tryon` function has correct CORS headers (already included in shared/cors.ts).
