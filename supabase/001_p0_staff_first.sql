-- Smart Table OS — schema P0 Staff-First
-- Eseguire su Supabase SQL Editor (pilota Ardea)
-- Idempotente dove possibile

-- 1) Estensione chiamate: presa in carico + chiusura
alter table if exists public.calls
  add column if not exists claimed_by text,
  add column if not exists claimed_at timestamptz,
  add column if not exists closed_at timestamptz,
  add column if not exists venue_id text default 'ardea';

-- status ammessi: pending | claimed | done | cancelled
comment on column public.calls.claimed_by is 'Nome/id cameriere che ha preso in carico';

-- 2) Staff: pausa protetta
alter table if exists public.staff_status
  add column if not exists on_break boolean default false,
  add column if not exists break_until timestamptz,
  add column if not exists covering_for integer,
  add column if not exists device_id text,
  add column if not exists venue_id text default 'ardea';

-- 3) Stati tavolo (ciclo vita)
create table if not exists public.tables (
  id uuid primary key default gen_random_uuid(),
  venue_id text not null default 'ardea',
  table_number text not null,
  status text not null default 'free'
    check (status in ('free','reserved','occupied','bill','reset')),
  seats int default 2,
  zone text,
  updated_at timestamptz default now(),
  unique (venue_id, table_number)
);

-- 4) Eventi audit (se non esiste)
create table if not exists public.audit_events (
  id bigserial primary key,
  event_type text not null,
  table_id text,
  staff_id text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- 5) Pulsanti quick action (se non esiste)
create table if not exists public.config_buttons (
  id serial primary key,
  label text not null,
  action_type text not null,
  is_active boolean default true,
  sort_order int default 0,
  venue_id text default 'ardea'
);

insert into public.config_buttons (label, action_type, is_active, sort_order)
select * from (values
  ('💧 Acqua', 'water', true, 1),
  ('🍞 Pane', 'bread', true, 2),
  ('🍴 Posate', 'cutlery', true, 3),
  ('🧹 Pulizia', 'clean', true, 4),
  ('🧾 Conto', 'bill', true, 5)
) as v(label, action_type, is_active, sort_order)
where not exists (select 1 from public.config_buttons limit 1);

-- 6) Seed tavoli 1-20 se vuoti
insert into public.tables (table_number, zone, status)
select lpad(g::text, 2, '0'), 'sala', 'free'
from generate_series(1, 20) g
where not exists (select 1 from public.tables limit 1);

-- 7) Realtime (eseguire se non già abilitato in Dashboard > Replication)
-- alter publication supabase_realtime add table public.calls;
-- alter publication supabase_realtime add table public.staff_status;
-- alter publication supabase_realtime add table public.tables;

-- 8) RLS base (anon può inserire chiamate e leggere bottoni; staff update via anon per MVP — stringere con auth dopo)
alter table public.calls enable row level security;
alter table public.config_buttons enable row level security;
alter table public.staff_status enable row level security;
alter table public.tables enable row level security;
alter table public.audit_events enable row level security;

do $$ begin
  create policy "anon_read_buttons" on public.config_buttons for select using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_insert_calls" on public.calls for insert with check (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_select_calls" on public.calls for select using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_update_calls" on public.calls for update using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_all_staff" on public.staff_status for all using (true) with check (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_all_tables" on public.tables for all using (true) with check (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "anon_insert_audit" on public.audit_events for insert with check (true);
exception when duplicate_object then null; end $$;

-- Self-check query (eseguire a mano):
-- select 'calls' as t, count(*) from calls
-- union all select 'staff', count(*) from staff_status
-- union all select 'tables', count(*) from tables
-- union all select 'buttons', count(*) from config_buttons;
