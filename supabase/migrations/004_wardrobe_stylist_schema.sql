-- =============================================
-- Prova App — Wardrobe + AI Stylist Schema
-- =============================================

-- =============================================
-- WARDROBE_ITEMS
-- User's personally owned clothing items
-- =============================================
create table public.wardrobe_items (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles on delete cascade,
  name          text,                    -- user-given label, optional
  category      text not null
                  check (category in ('top','bottom','dress','outerwear','shoes','bag','accessory','other')),
  color         text,                    -- primary color in Turkish: "kırmızı", "siyah" etc.
  color_hex     text,                    -- optional #rrggbb for color swatch display
  pattern       text
                  check (pattern in ('solid','striped','floral','checkered','graphic','other') or pattern is null),
  season        text
                  check (season in ('spring','summer','autumn','winter','all') or season is null),
  occasion      text
                  check (occasion in ('casual','formal','sport','evening','work','all') or occasion is null),
  brand         text,
  storage_path  text not null,           -- in wardrobe-items bucket
  thumbnail_path text,
  is_favorite   boolean not null default false,
  notes         text,                    -- user's own notes
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index wardrobe_items_user_idx     on public.wardrobe_items (user_id, created_at desc);
create index wardrobe_items_category_idx on public.wardrobe_items (user_id, category);
create index wardrobe_items_season_idx   on public.wardrobe_items (user_id, season);

create trigger set_wardrobe_items_updated_at
  before update on public.wardrobe_items
  for each row execute procedure public.set_updated_at();

alter table public.wardrobe_items enable row level security;

create policy "Users own their wardrobe"
  on public.wardrobe_items for all using (auth.uid() = user_id);


-- =============================================
-- OUTFITS
-- Saved outfit combinations (AI-generated or user-curated)
-- =============================================
create table public.outfits (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles on delete cascade,
  name          text,
  occasion      text,
  season        text,
  ai_generated  boolean not null default false,
  session_id    uuid,                    -- FK to stylist_sessions (set after table created)
  ai_reasoning  text,                    -- AI's explanation for this outfit
  notes         text,
  cover_path    text,                    -- optional composite image
  created_at    timestamptz not null default now()
);

create index outfits_user_idx on public.outfits (user_id, created_at desc);

alter table public.outfits enable row level security;

create policy "Users own their outfits"
  on public.outfits for all using (auth.uid() = user_id);


-- =============================================
-- OUTFIT_ITEMS
-- Junction: outfits ↔ wardrobe items or catalog garments
-- =============================================
create table public.outfit_items (
  id                uuid primary key default uuid_generate_v4(),
  outfit_id         uuid not null references public.outfits on delete cascade,
  wardrobe_item_id  uuid references public.wardrobe_items on delete set null,
  garment_id        uuid references public.garments on delete set null,    -- catalog item
  position          integer not null default 0,          -- ordering for display
  note              text,
  check (wardrobe_item_id is not null or garment_id is not null)
);

create index outfit_items_outfit_idx on public.outfit_items (outfit_id, position);

alter table public.outfit_items enable row level security;

create policy "Users can manage their outfit items"
  on public.outfit_items for all
  using (
    exists (
      select 1 from public.outfits o
      where o.id = outfit_id and o.user_id = auth.uid()
    )
  );


-- =============================================
-- STYLIST_SESSIONS
-- Each conversation thread with the AI stylist
-- =============================================
create table public.stylist_sessions (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles on delete cascade,
  title       text,                      -- auto-set from first message
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index stylist_sessions_user_idx on public.stylist_sessions (user_id, updated_at desc);

create trigger set_stylist_sessions_updated_at
  before update on public.stylist_sessions
  for each row execute procedure public.set_updated_at();

alter table public.stylist_sessions enable row level security;

create policy "Users own their sessions"
  on public.stylist_sessions for all using (auth.uid() = user_id);

-- Now add FK from outfits → stylist_sessions
alter table public.outfits
  add constraint outfits_session_id_fkey
  foreign key (session_id) references public.stylist_sessions (id) on delete set null;


-- =============================================
-- STYLIST_MESSAGES
-- Individual messages in a session (user + AI)
-- =============================================
create table public.stylist_messages (
  id                  uuid primary key default uuid_generate_v4(),
  session_id          uuid not null references public.stylist_sessions on delete cascade,
  user_id             uuid not null references public.profiles on delete cascade,
  role                text not null check (role in ('user', 'assistant')),
  content             text not null,         -- human-readable display text
  structured_data     jsonb,                 -- parsed AI response (outfit suggestions etc.)
  wardrobe_snapshot   jsonb,                 -- wardrobe item ids used as context
  created_at          timestamptz not null default now()
);

create index stylist_messages_session_idx on public.stylist_messages (session_id, created_at asc);

alter table public.stylist_messages enable row level security;

create policy "Users own their messages"
  on public.stylist_messages for all using (auth.uid() = user_id);


-- =============================================
-- STORAGE: wardrobe-items bucket
-- (Create bucket via CLI or dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('wardrobe-items', 'wardrobe-items', false);
-- =============================================

-- Storage RLS for wardrobe-items
create policy "Users can upload their wardrobe items"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'wardrobe-items' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can read their wardrobe items"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'wardrobe-items' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete their wardrobe items"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'wardrobe-items' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================
-- REALTIME: enable for stylist_messages (live typing feel)
-- =============================================
alter publication supabase_realtime add table public.stylist_messages;
alter publication supabase_realtime add table public.outfits;
