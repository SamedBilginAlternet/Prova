-- ==========================================
-- PROVA SUPABASE SETUP SCRIPT
-- ==========================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('photos', 'photos', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('wardrobe', 'wardrobe', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('garments', 'garments', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('tryon_results', 'tryon_results', true) ON CONFLICT DO NOTHING;

-- 3. Create Tables

-- Garments (System catalog of tryable clothes)
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

-- Wardrobe Items (User's personal clothes)
CREATE TABLE IF NOT EXISTS public.wardrobe_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- Tryon Jobs
CREATE TABLE IF NOT EXISTS public.tryon_jobs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    garment_id uuid REFERENCES public.garments(id) ON DELETE CASCADE,
    mode text DEFAULT 'standard',
    user_photo_path text NOT NULL,
    status text DEFAULT 'pending',
    error_message text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tryon Results
CREATE TABLE IF NOT EXISTS public.tryon_results (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id uuid REFERENCES public.tryon_jobs(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    thumbnail_path text,
    is_saved boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- Stylist Sessions
CREATE TABLE IF NOT EXISTS public.stylist_sessions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    status text DEFAULT 'active',
    context_item_id uuid, -- Can reference wardrobe_item or garment, so no strict foreign key
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Stylist Messages
CREATE TABLE IF NOT EXISTS public.stylist_messages (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id uuid REFERENCES public.stylist_sessions(id) ON DELETE CASCADE,
    role text NOT NULL, -- 'user', 'assistant', 'system'
    content text NOT NULL,
    raw_response jsonb,
    created_at timestamptz DEFAULT now()
);

-- Saved Outfits
CREATE TABLE IF NOT EXISTS public.saved_outfits (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    season text,
    occasion text,
    rating integer DEFAULT 7,
    is_favorite boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- Outfit Items Reference (Join table for outfits to items)
CREATE TABLE IF NOT EXISTS public.outfit_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    outfit_id uuid REFERENCES public.saved_outfits(id) ON DELETE CASCADE,
    item_id uuid NOT NULL,
    item_type text NOT NULL, -- 'wardrobe_item' or 'garment'
    position integer DEFAULT 0
);

-- 4. Set up Row Level Security (RLS) policies

ALTER TABLE public.garments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tryon_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tryon_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stylist_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stylist_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_items ENABLE ROW LEVEL SECURITY;

-- Garments: Everyone can read garments
CREATE POLICY "Garments are readable by everyone" ON public.garments
    FOR SELECT USING (true);

-- Wardrobe: Users can only see and edit their own wardrobe
CREATE POLICY "Users can manage their own wardrobe" ON public.wardrobe_items
    FOR ALL USING (auth.uid() = user_id);

-- Tryon Jobs: Users can manage their own jobs
CREATE POLICY "Users can manage their own tryon jobs" ON public.tryon_jobs
    FOR ALL USING (auth.uid() = user_id);

-- Tryon Results: Associated with jobs
CREATE POLICY "Users can manage their tryon results" ON public.tryon_results
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.tryon_jobs 
            WHERE tryon_jobs.id = tryon_results.job_id AND tryon_jobs.user_id = auth.uid()
        )
    );

-- Stylist Sessions & Messages: Users manage their own sessions
CREATE POLICY "Users can manage their own stylist sessions" ON public.stylist_sessions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own stylist messages" ON public.stylist_messages
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.stylist_sessions 
            WHERE stylist_sessions.id = stylist_messages.session_id AND stylist_sessions.user_id = auth.uid()
        )
    );

-- Saved Outfits: Users manage their own outfits
CREATE POLICY "Users can manage their own outfits" ON public.saved_outfits
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage outfit items" ON public.outfit_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.saved_outfits 
            WHERE saved_outfits.id = outfit_items.outfit_id AND saved_outfits.user_id = auth.uid()
        )
    );

-- Storage Policies
-- Allow public access to all buckets for simplicity in development
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT USING (bucket_id IN ('photos', 'wardrobe', 'garments', 'tryon_results'));
CREATE POLICY "Public Insert Access" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('photos', 'wardrobe', 'garments', 'tryon_results'));
CREATE POLICY "Public Update Access" ON storage.objects FOR UPDATE USING (bucket_id IN ('photos', 'wardrobe', 'garments', 'tryon_results'));
CREATE POLICY "Public Delete Access" ON storage.objects FOR DELETE USING (bucket_id IN ('photos', 'wardrobe', 'garments', 'tryon_results'));
