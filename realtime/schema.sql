-- VivaLive: MVP público de video P2P con usuarios autenticados y correo confirmado.
-- Ejecutar SOLO en un proyecto Supabase nuevo y exclusivo de VivaLive.
create table public.vl_rooms (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  host_name text not null check (char_length(host_name) between 3 and 40),
  status text not null default 'live' check(status in ('live','ended')),
  created_at timestamptz not null default now(),
  heartbeat_at timestamptz not null default now()
);
create unique index vl_one_active_room_per_host on public.vl_rooms(host_id) where status='live';
create index vl_rooms_active on public.vl_rooms(status,heartbeat_at desc);
alter table public.vl_rooms enable row level security;
create policy "View public active rooms" on public.vl_rooms for select to authenticated
using (status='live' and heartbeat_at > now()-interval '70 seconds' or host_id=(select auth.uid()));
create policy "Create own rooms" on public.vl_rooms for insert to authenticated
with check (host_id=(select auth.uid()) and status='live');
create policy "Update own rooms" on public.vl_rooms for update to authenticated
using (host_id=(select auth.uid())) with check(host_id=(select auth.uid()));
create policy "Delete own rooms" on public.vl_rooms for delete to authenticated using (host_id=(select auth.uid()));
grant select,insert,update,delete on public.vl_rooms to authenticated;
-- Only sessions whose email is confirmed can use public-room signaling.
create policy "VivaLive receive public room signaling" on realtime.messages for select to authenticated
using (
  realtime.topic() like 'vl-room:%'
);
create policy "VivaLive send public room signaling" on realtime.messages for insert to authenticated
with check (
  realtime.topic() like 'vl-room:%'
  and exists (select 1 from auth.users where id=(select auth.uid()) and email_confirmed_at is not null)
);
-- IMPORTANT: This MVP is limited to public, non-adult rooms.
-- Email verification proves mailbox control, NOT legal age or identity.
-- Before enabling adult content, add certified age/identity verification + moderation.
