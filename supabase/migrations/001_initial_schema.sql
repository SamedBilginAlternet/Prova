-- =============================================
-- Prova App — Initial Schema Migration
-- =============================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_cron";  -- for job timeout cleanup

-- =============================================
-- PROFILES
-- =============================================
create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  username    text unique,
  full_name   text,
  avatar_url  text,
  locale      text not null default 'tr',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);


-- =============================================
-- USER_PHOTOS
-- =============================================
create table public.user_photos (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles on delete cascade,
  storage_path  text not null,
  is_active     boolean not null default true,
  width         integer,
  height        integer,
  created_at    timestamptz not null default now()
);

create index user_photos_user_active_idx on public.user_photos (user_id, is_active);

-- RLS
alter table public.user_photos enable row level security;

create policy "Users own their photos"
  on public.user_photos for all using (auth.uid() = user_id);


-- =============================================
-- GARMENTS
-- =============================================
create table public.garments (
  id              uuid primary key default uuid_generate_v4(),
  name_tr         text not null,
  name_en         text,
  brand           text,
  category        text not null check (category in ('top', 'bottom', 'dress', 'outerwear')),
  color           text,
  storage_path    text not null,
  thumbnail_path  text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

create index garments_category_active_idx on public.garments (category, is_active);

-- RLS — read only for authenticated users, admin manages via service role
alter table public.garments enable row level security;

create policy "Anyone can view active garments"
  on public.garments for select using (is_active = true);


-- =============================================
-- TRYON_JOBS
-- =============================================
create table public.tryon_jobs (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles on delete cascade,
  photo_id    uuid not null references public.user_photos on delete restrict,
  garment_id  uuid not null references public.garments on delete restrict,
  status      text not null default 'pending'
                check (status in ('pending', 'processing', 'completed', 'failed')),
  error_msg   text,
  hf_job_id   text,  -- HuggingFace job reference
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index tryon_jobs_user_status_idx on public.tryon_jobs (user_id, status, created_at desc);

create trigger set_tryon_jobs_updated_at
  before update on public.tryon_jobs
  for each row execute procedure public.set_updated_at();

-- RLS
alter table public.tryon_jobs enable row level security;

create policy "Users own their jobs"
  on public.tryon_jobs for all using (auth.uid() = user_id);


-- =============================================
-- TRYON_RESULTS
-- =============================================
create table public.tryon_results (
  id            uuid primary key default uuid_generate_v4(),
  job_id        uuid not null unique references public.tryon_jobs on delete cascade,
  user_id       uuid not null references public.profiles on delete cascade,
  storage_path  text not null,
  is_favorite   boolean not null default false,
  created_at    timestamptz not null default now()
);

create index tryon_results_user_idx on public.tryon_results (user_id, created_at desc);
create index tryon_results_favorites_idx on public.tryon_results (user_id, is_favorite) where is_favorite = true;

-- RLS
alter table public.tryon_results enable row level security;

create policy "Users own their results"
  on public.tryon_results for all using (auth.uid() = user_id);


-- =============================================
-- FAVORITES (denormalized from tryon_results.is_favorite for flexibility)
-- =============================================
create table public.favorites (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles on delete cascade,
  result_id  uuid not null references public.tryon_results on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, result_id)
);

alter table public.favorites enable row level security;

create policy "Users own their favorites"
  on public.favorites for all using (auth.uid() = user_id);


-- =============================================
-- STORAGE BUCKETS
-- =============================================
-- Run these separately via Supabase dashboard or CLI
-- supabase storage create user-photos --private
-- supabase storage create garment-images --public
-- supabase storage create tryon-results --private


-- =============================================
-- REALTIME
-- Enable realtime on tryon_jobs for live job status updates
-- =============================================
alter publication supabase_realtime add table public.tryon_jobs;


-- =============================================
-- JOB TIMEOUT CLEANUP (optional cron)
-- Mark jobs stuck in processing for > 5 minutes as failed
-- =============================================
-- select cron.schedule(
--   'cleanup-stuck-jobs',
--   '*/5 * * * *',  -- every 5 minutes
--   $$
--     update public.tryon_jobs
--     set status = 'failed', error_msg = 'Zaman aşımı (timeout)'
--     where status = 'processing'
--       and updated_at < now() - interval '5 minutes'
--   $$
-- );
