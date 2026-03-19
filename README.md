# Prova — AI Fashion Try-On App

Turkey-focused AI virtual try-on app. Users upload a photo and see how clothing items look on them.

## Stack
- **Frontend**: Flutter + Riverpod + go_router
- **Backend**: Supabase (Auth, DB, Storage, Edge Functions)
- **AI**: HuggingFace IDM-VTON Space (free tier)

## Quick Start

### 1. Supabase Setup
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Init and start local (optional)
supabase init
supabase start

# Or link to your existing project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push

# Create storage buckets
supabase storage create user-photos --private
supabase storage create garment-images --public
supabase storage create tryon-results --private

# Deploy Edge Functions
supabase functions deploy trigger-tryon

# Set Edge Function secrets
supabase secrets set HF_TOKEN=your_hf_token_here
```

### 2. Flutter Setup
```bash
flutter pub get

# Run with your Supabase credentials
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### 3. Generate Riverpod/Freezed code
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure
```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp + theme + router
├── core/
│   ├── constants/         # Colors, text styles, spacing
│   ├── theme/             # AppTheme
│   ├── router/            # go_router setup
│   └── supabase/          # Supabase client init
├── features/
│   ├── auth/              # Login, onboarding, auth provider
│   ├── home/              # Home screen with garment browse
│   ├── garments/          # Garment model, repo, browser screen
│   ├── photo/             # Upload photo feature
│   ├── tryon/             # Job trigger, loading, result
│   ├── history/           # Past try-on results
│   └── profile/           # User profile & settings
└── shared/
    └── widgets/           # Reusable UI components
```

## AI Integration

The app uses **IDM-VTON** (Improving Diffusion Models for Authentic Virtual Try-on) via HuggingFace Spaces.

- Space: `yisol/IDM-VTON`
- Called from Supabase Edge Function (`trigger-tryon`)
- Results stored in private Supabase Storage bucket
- Job status updated via Realtime subscription

**Free tier limitations:**
- ~1000 free requests/month with HF token
- Queue wait times: 15-90 seconds depending on load
- Results are AI visual previews, not physics-accurate

## Environment Variables

### Flutter
| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon public key |

### Edge Functions (Supabase Secrets)
| Secret | Description |
|---|---|
| `HF_TOKEN` | HuggingFace API token (optional, increases rate limits) |
| `SUPABASE_URL` | Auto-set by Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set by Supabase |

## Development Roadmap

### MVP (Current)
- [x] Auth (email + Google)
- [x] User photo upload
- [x] Garment browser with categories
- [x] AI try-on job trigger
- [x] Real-time job status
- [x] Result display
- [x] History / saved looks
- [x] Profile screen

### Phase 2
- [ ] Social sharing (share_plus)
- [ ] Merchant product links
- [ ] Better result comparison (before/after slider)
- [ ] Push notifications for job completion

### Phase 3
- [ ] Body measurements
- [ ] Size recommendations
- [ ] Outfit suggestions
- [ ] Brand/merchant portal

## Notes

- **AI disclaimer**: All try-on results are clearly labeled "AI Önizleme" (AI Preview)
- **Turkish first**: UI copy is in Turkish, English localization planned for Phase 2
- **No code-gen outputs committed**: Run `build_runner` locally after cloning
