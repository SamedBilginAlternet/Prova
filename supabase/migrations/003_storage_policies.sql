-- =============================================
-- Prova App — Storage RLS Policies
-- Run after creating the buckets via CLI or dashboard
-- =============================================

-- Buckets should be created first:
-- INSERT INTO storage.buckets (id, name, public) VALUES
--   ('user-photos', 'user-photos', false),
--   ('garment-images', 'garment-images', true),
--   ('tryon-results', 'tryon-results', false);


-- =============================================
-- user-photos (PRIVATE)
-- Users can upload/read their own photos only
-- =============================================

create policy "Users can upload their own photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'user-photos' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can read their own photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'user-photos' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete their own photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'user-photos' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Service role (Edge Functions) can access all user photos
-- (Handled via service role key, no additional policy needed)


-- =============================================
-- garment-images (PUBLIC)
-- Anyone can read, only service role can write
-- =============================================

create policy "Anyone can view garment images"
  on storage.objects for select
  to public
  using (bucket_id = 'garment-images');


-- =============================================
-- tryon-results (PRIVATE)
-- Users can only read their own results
-- Edge Functions (service role) write results
-- =============================================

create policy "Users can read their own results"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'tryon-results' and
    (storage.foldername(name))[1] = auth.uid()::text
  );
