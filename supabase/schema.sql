-- ════════════════════════════════════════════════════════════════════════
-- PawVault — Supabase schema
-- Idempotent: safe to re-run. Paste this whole file into the Supabase
-- SQL Editor (Dashboard → SQL Editor → New query → Run).
-- ════════════════════════════════════════════════════════════════════════

-- ── Tables ───────────────────────────────────────────────────────────────

create table if not exists pets (
  id                text primary key,
  user_id           uuid references auth.users on delete cascade not null,
  name              text not null,
  species           text not null,
  breed             text default '',
  date_of_birth     timestamptz not null,
  gender            text,
  weight_kg         numeric,
  photo_url         text,
  mood              text default 'idle',
  microchip_number  text,
  primary_vet       text,
  is_neutered       boolean default false,
  is_insured        boolean default false,
  allergies         text[] default '{}',
  about             text,
  created_at        timestamptz default now()
);

create table if not exists vaccines (
  id          text primary key,
  pet_id      text references pets on delete cascade not null,
  name        text not null,
  description text,
  last_given  timestamptz not null,
  next_due    timestamptz not null,
  clinic      text,
  vet         text,
  cost        numeric,
  created_at  timestamptz default now()
);

create table if not exists medications (
  id              text primary key,
  pet_id          text references pets on delete cascade not null,
  name            text not null,
  category        text,
  frequency       text not null,
  dosage          text not null,
  remaining_count integer,
  next_dose_at    timestamptz,
  is_active       boolean default true,
  start_date      timestamptz not null,
  end_date        timestamptz,
  created_at      timestamptz default now()
);

create table if not exists dose_logs (
  id            uuid primary key default gen_random_uuid(),
  medication_id text references medications on delete cascade not null,
  given_at      timestamptz not null
);

create table if not exists health_records (
  id            text primary key,
  pet_id        text references pets on delete cascade not null,
  type          text not null,
  title         text not null,
  clinic        text,
  vet           text,
  cost          numeric,
  date          timestamptz not null,
  notes         text,
  document_urls text[] default '{}',
  created_at    timestamptz default now()
);

create table if not exists documents (
  id              text primary key,
  pet_id          text references pets on delete cascade not null,
  type            text not null,          -- vaccine_card | lab_report | prescription | insurance | receipt | other
  title           text not null,
  document_url    text not null,
  thumbnail_url   text,
  notes           text,
  captured_text   text,                   -- raw OCR/Vision output
  captured_data   jsonb default '{}'::jsonb,  -- structured: dates, meds, clinic, etc.
  is_image        boolean default true,
  created_at      timestamptz default now()
);

create index if not exists idx_documents_pet on documents(pet_id);
create index if not exists idx_documents_type on documents(type);

create table if not exists user_preferences (
  user_id              uuid primary key references auth.users on delete cascade,
  display_name         text,
  primary_species      text,
  pet_count            text,
  priorities           text[] default '{}',
  care_time            text,
  referral_source      text,
  notifications_enabled boolean default false,
  extra                jsonb default '{}'::jsonb,
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

create table if not exists care_events (
  id           text primary key,
  pet_id       text references pets on delete cascade not null,
  type         text not null,
  title        text not null,
  subtitle     text,
  scheduled_at timestamptz not null,
  is_done      boolean default false,
  created_at   timestamptz default now()
);

create index if not exists idx_pets_user    on pets(user_id);
create index if not exists idx_vaccines_pet on vaccines(pet_id);
create index if not exists idx_meds_pet     on medications(pet_id);
create index if not exists idx_records_pet  on health_records(pet_id);
create index if not exists idx_events_pet   on care_events(pet_id);

-- ── Row Level Security ───────────────────────────────────────────────────

alter table user_preferences enable row level security;

drop policy if exists "Users own their prefs" on user_preferences;
create policy "Users own their prefs" on user_preferences
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table documents enable row level security;

drop policy if exists "Pets own their documents" on documents;
create policy "Pets own their documents" on documents
  for all using (exists (
    select 1 from pets where pets.id = documents.pet_id and pets.user_id = auth.uid()
  ));

alter table pets           enable row level security;
alter table vaccines       enable row level security;
alter table medications    enable row level security;
alter table dose_logs      enable row level security;
alter table health_records enable row level security;
alter table care_events    enable row level security;

drop policy if exists "Users own their pets" on pets;
create policy "Users own their pets" on pets
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Pets own their vaccines" on vaccines;
create policy "Pets own their vaccines" on vaccines
  for all using (exists (
    select 1 from pets where pets.id = vaccines.pet_id and pets.user_id = auth.uid()
  ));

drop policy if exists "Pets own their meds" on medications;
create policy "Pets own their meds" on medications
  for all using (exists (
    select 1 from pets where pets.id = medications.pet_id and pets.user_id = auth.uid()
  ));

drop policy if exists "Pets own their dose logs" on dose_logs;
create policy "Pets own their dose logs" on dose_logs
  for all using (exists (
    select 1 from medications m
    join pets p on p.id = m.pet_id
    where m.id = dose_logs.medication_id and p.user_id = auth.uid()
  ));

drop policy if exists "Pets own their records" on health_records;
create policy "Pets own their records" on health_records
  for all using (exists (
    select 1 from pets where pets.id = health_records.pet_id and pets.user_id = auth.uid()
  ));

drop policy if exists "Pets own their events" on care_events;
create policy "Pets own their events" on care_events
  for all using (exists (
    select 1 from pets where pets.id = care_events.pet_id and pets.user_id = auth.uid()
  ));

-- ── Realtime: add tables to the supabase_realtime publication ────────────
-- Lets the Flutter app subscribe via `.stream()` for live updates.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'pets'
  ) then
    alter publication supabase_realtime add table pets, vaccines, medications,
      dose_logs, health_records, care_events, user_preferences, documents;
  end if;
end $$;

-- ── Storage bucket for pet photos ────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('pet-photos', 'pet-photos', true)
on conflict (id) do nothing;

drop policy if exists "Anyone can read pet photos" on storage.objects;
drop policy if exists "Authed users upload photos" on storage.objects;
drop policy if exists "Owners update their photos" on storage.objects;
drop policy if exists "Owners delete their photos" on storage.objects;

create policy "Anyone can read pet photos" on storage.objects
  for select using (bucket_id = 'pet-photos');

create policy "Authed users upload photos" on storage.objects
  for insert with check (bucket_id = 'pet-photos' and auth.uid() is not null);

create policy "Owners update their photos" on storage.objects
  for update using (bucket_id = 'pet-photos' and auth.uid() = owner);

create policy "Owners delete their photos" on storage.objects
  for delete using (bucket_id = 'pet-photos' and auth.uid() = owner);
