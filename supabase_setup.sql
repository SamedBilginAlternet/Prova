-- ==========================================
-- PROVA SUPABASE SETUP SCRIPT
-- Generated from actual Dart repository code
-- ==========================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 2. Create Storage Buckets
-- Names must match Dart code exactly
-- ==========================================

-- garment-images: PUBLIC (garment_repository.dart uses getPublicUrl)
INSERT INTO storage.buckets (id, name, public)
VALUES ('garment-images', 'garment-images', true)
ON CONFLICT (id) DO NOTHING;

-- user-photos: PRIVATE (photo_repository.dart uses createSignedUrl)
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-photos', 'user-photos', false)
ON CONFLICT (id) DO NOTHING;

-- wardrobe-items: PRIVATE (wardrobe_repository.dart uses createSignedUrl)
INSERT INTO storage.buckets (id, name, public)
VALUES ('wardrobe-items', 'wardrobe-items', false)
ON CONFLICT (id) DO NOTHING;

-- tryon-results: PRIVATE (tryon_repository.dart uses createSignedUrl)
INSERT INTO storage.buckets (id, name, public)
VALUES ('tryon-results', 'tryon-results', false)
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 3. Create Tables
-- Column names must match Dart model @JsonKey annotations
-- ==========================================

-- garments: System catalog of tryable clothes
-- garment_repository.dart: selects id, name_tr, name_en, brand, category, color,
--   storage_path, thumbnail_path, is_active, created_at
CREATE TABLE IF NOT EXISTS public.garments (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_tr text NOT NULL,
    name_en text,
    brand text,
    category text NOT NULL,
    color text,
    storage_path text NOT NULL,
    thumbnail_path text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- user_photos: User's profile/try-on photos
-- photo_repository.dart: inserts user_id, storage_path, is_active, width, height
--   deactivates old photos with is_active=false
CREATE TABLE IF NOT EXISTS public.user_photos (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    is_active boolean DEFAULT true,
    width integer,
    height integer,
    created_at timestamptz DEFAULT now()
);

-- wardrobe_items: User's personal clothes
-- wardrobe_repository.dart: inserts id, user_id, category, storage_path,
--   name, color, color_hex, pattern, season, occasion, brand, notes
--   toggles is_favorite
CREATE TABLE IF NOT EXISTS public.wardrobe_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name text,
    category text NOT NULL,
    color text,
    color_hex text,
    pattern text,
    season text,
    occasion text,
    brand text,
    storage_path text NOT NULL,
    thumbnail_path text,
    is_favorite boolean DEFAULT false,
    notes text,
    created_at timestamptz DEFAULT now()
);

-- tryon_jobs: Virtual try-on async jobs
-- tryon_repository.dart: selects id, user_id, garment_id, mode,
--   user_photo_path, status, error_message, created_at, updated_at
CREATE TABLE IF NOT EXISTS public.tryon_jobs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    garment_id uuid REFERENCES public.garments(id) ON DELETE CASCADE,
    mode text DEFAULT 'standard',
    user_photo_path text NOT NULL,
    status text DEFAULT 'pending',  -- pending | processing | completed | failed
    error_message text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- tryon_results: Output images from try-on jobs
-- tryon_repository.dart: selects id, job_id, storage_path, thumbnail_path,
--   is_saved, is_favorite, created_at
--   toggles is_favorite
CREATE TABLE IF NOT EXISTS public.tryon_results (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id uuid REFERENCES public.tryon_jobs(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    thumbnail_path text,
    is_saved boolean DEFAULT false,
    is_favorite boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- stylist_sessions: AI stylist chat sessions
-- stylist_repository.dart: inserts title; orders by updated_at
-- StylistSession model: id, user_id, title, created_at, updated_at
CREATE TABLE IF NOT EXISTS public.stylist_sessions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- stylist_messages: Chat messages in a session
-- stylist_repository.dart:
--   user messages: inserts session_id, user_id, role, content, wardrobe_snapshot
--   assistant messages: inserts session_id, user_id, role, content, structured_data
-- StylistMessage model: id, session_id, user_id, role, content, structured_data, created_at
CREATE TABLE IF NOT EXISTS public.stylist_messages (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id uuid REFERENCES public.stylist_sessions(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role text NOT NULL,  -- 'user' | 'assistant'
    content text NOT NULL,
    structured_data jsonb,        -- AI structured response (outfit suggestions, tips, etc.)
    wardrobe_snapshot text[],     -- snapshot of wardrobe item IDs sent with user message
    created_at timestamptz DEFAULT now()
);

-- outfits: AI-generated or manually saved outfit combinations
-- stylist_repository.dart: uses table name 'outfits' (NOT saved_outfits)
--   inserts user_id, name, ai_generated, occasion, season, ai_reasoning, session_id
-- SavedOutfit model: id, user_id, name, occasion, season, ai_generated, ai_reasoning,
--   notes, cover_path, created_at
CREATE TABLE IF NOT EXISTS public.outfits (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name text NOT NULL,
    occasion text,
    season text,
    ai_generated boolean DEFAULT false,
    ai_reasoning text,
    notes text,
    cover_path text,
    session_id uuid REFERENCES public.stylist_sessions(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now()
);

-- outfit_items: Junction table linking outfits to wardrobe items or garments
-- stylist_repository.dart: inserts outfit_id, wardrobe_item_id, position
--   OR outfit_id, garment_id, position
-- OutfitItemRef model: id, outfit_id, wardrobe_item_id, garment_id, position
CREATE TABLE IF NOT EXISTS public.outfit_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    outfit_id uuid REFERENCES public.outfits(id) ON DELETE CASCADE NOT NULL,
    wardrobe_item_id uuid REFERENCES public.wardrobe_items(id) ON DELETE CASCADE,
    garment_id uuid REFERENCES public.garments(id) ON DELETE CASCADE,
    position integer DEFAULT 0,
    -- At least one of wardrobe_item_id or garment_id must be set
    CONSTRAINT outfit_items_has_item CHECK (
        wardrobe_item_id IS NOT NULL OR garment_id IS NOT NULL
    )
);

-- ==========================================
-- 4. Realtime (for live job status updates)
-- ==========================================

ALTER publication supabase_realtime ADD TABLE public.tryon_jobs;
ALTER publication supabase_realtime ADD TABLE public.stylist_messages;
ALTER publication supabase_realtime ADD TABLE public.outfits;

-- ==========================================
-- 5. Row Level Security
-- ==========================================

ALTER TABLE public.garments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tryon_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tryon_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stylist_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stylist_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_items ENABLE ROW LEVEL SECURITY;

-- garments: public read (system catalog)
CREATE POLICY "Garments readable by everyone"
    ON public.garments FOR SELECT USING (true);

-- user_photos: own rows only
CREATE POLICY "Users manage own photos"
    ON public.user_photos FOR ALL USING (auth.uid() = user_id);

-- wardrobe_items: own rows only
CREATE POLICY "Users manage own wardrobe"
    ON public.wardrobe_items FOR ALL USING (auth.uid() = user_id);

-- tryon_jobs: own rows only
CREATE POLICY "Users manage own tryon jobs"
    ON public.tryon_jobs FOR ALL USING (auth.uid() = user_id);

-- tryon_results: via job ownership
CREATE POLICY "Users manage own tryon results"
    ON public.tryon_results FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.tryon_jobs
            WHERE tryon_jobs.id = tryon_results.job_id
              AND tryon_jobs.user_id = auth.uid()
        )
    );

-- stylist_sessions: own rows only
CREATE POLICY "Users manage own stylist sessions"
    ON public.stylist_sessions FOR ALL USING (auth.uid() = user_id);

-- stylist_messages: via session ownership
CREATE POLICY "Users manage own stylist messages"
    ON public.stylist_messages FOR ALL USING (auth.uid() = user_id);

-- outfits: own rows only
CREATE POLICY "Users manage own outfits"
    ON public.outfits FOR ALL USING (auth.uid() = user_id);

-- outfit_items: via outfit ownership
CREATE POLICY "Users manage own outfit items"
    ON public.outfit_items FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.outfits
            WHERE outfits.id = outfit_items.outfit_id
              AND outfits.user_id = auth.uid()
        )
    );

-- ==========================================
-- 6. Storage Policies
-- ==========================================

-- garment-images: public read, admin insert (no user uploads)
CREATE POLICY "Public read garment images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'garment-images');

-- user-photos: authenticated users manage own folder (userId/...)
CREATE POLICY "Users manage own user-photos"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'user-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'user-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- wardrobe-items: authenticated users manage own folder
CREATE POLICY "Users manage own wardrobe-items"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'wardrobe-items'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'wardrobe-items'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- tryon-results: authenticated users manage own folder
CREATE POLICY "Users manage own tryon-results"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'tryon-results'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'tryon-results'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ==========================================
-- 7. Indexes (performance)
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_user_photos_user_active
    ON public.user_photos (user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user
    ON public.wardrobe_items (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tryon_jobs_user_status
    ON public.tryon_jobs (user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tryon_results_job
    ON public.tryon_results (job_id);

CREATE INDEX IF NOT EXISTS idx_stylist_sessions_user
    ON public.stylist_sessions (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_stylist_messages_session
    ON public.stylist_messages (session_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_outfits_user
    ON public.outfits (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outfit_items_outfit
    ON public.outfit_items (outfit_id, position ASC);

-- ==========================================
-- 8. Auto-update updated_at triggers
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tryon_jobs_updated_at
    BEFORE UPDATE ON public.tryon_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER stylist_sessions_updated_at
    BEFORE UPDATE ON public.stylist_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
