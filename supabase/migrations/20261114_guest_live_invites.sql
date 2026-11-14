-- Additive guest invitation support. Existing rooms, lives and battles are untouched.
create table if not exists public.vl_guest_invites (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.vl_rooms(id),
  host_id uuid not null,
  guest_id uuid,
  status text not null default 'pending' check (status in ('pending','accepted','ended')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  ended_at timestamptz
);
create index if not exists vl_guest_invites_room_status_idx on public.vl_guest_invites(room_id,status);
create index if not exists vl_guest_invites_guest_idx on public.vl_guest_invites(guest_id,status);
alter table public.vl_guest_invites enable row level security;

create policy "Guest invitations visible to involved users" on public.vl_guest_invites
 for select to authenticated using (host_id=(select auth.uid()) or guest_id=(select auth.uid()));
grant select on public.vl_guest_invites to authenticated;

create or replace function public.vl_create_guest_invite(target_room uuid)
returns uuid language plpgsql security definer set search_path='' as $fn$
declare result uuid; caller uuid := auth.uid();
begin
 if caller is null then raise exception 'Inicia sesión'; end if;
 if not exists (select 1 from public.vl_rooms where id=target_room and host_id=caller and status='live' and heartbeat_at>now()-interval '70 seconds')
 then raise exception 'Debes estar transmitiendo tu propio live'; end if;
 insert into public.vl_guest_invites(room_id,host_id) values (target_room,caller) returning id into result;
 return result;
end $fn$;

create or replace function public.vl_accept_guest_invite(invite_uuid uuid)
returns uuid language plpgsql security definer set search_path='' as $fn$
declare invitation public.vl_guest_invites%rowtype; caller uuid:=auth.uid();
begin
 if caller is null then raise exception 'Inicia sesión'; end if;
 select * into invitation from public.vl_guest_invites where id=invite_uuid for update;
 if invitation.id is null then raise exception 'Invitación no encontrada'; end if;
 if invitation.host_id=caller then raise exception 'El anfitrión no puede ser invitado'; end if;
 if not exists(select 1 from public.vl_rooms where id=invitation.room_id and status='live' and heartbeat_at>now()-interval '70 seconds')
 then raise exception 'Este live ya terminó'; end if;
 if invitation.status='accepted' and invitation.guest_id=caller then return invitation.room_id; end if;
 if invitation.status<>'pending' or invitation.created_at<now()-interval '30 minutes' then raise exception 'Invitación vencida o utilizada'; end if;
 if (select count(*) from public.vl_guest_invites where room_id=invitation.room_id and status='accepted') >=3
 then raise exception 'Este live ya tiene tres invitados'; end if;
 update public.vl_guest_invites set guest_id=caller,status='accepted',accepted_at=now() where id=invite_uuid;
 return invitation.room_id;
end $fn$;

create or replace function public.vl_end_guest_invite(invite_uuid uuid)
returns void language plpgsql security definer set search_path='' as $fn$
declare invitation public.vl_guest_invites%rowtype; caller uuid:=auth.uid();
begin
 select * into invitation from public.vl_guest_invites where id=invite_uuid for update;
 if caller is null or invitation.id is null or (caller<>invitation.host_id and caller is distinct from invitation.guest_id)
 then raise exception 'No autorizado'; end if;
 update public.vl_guest_invites set status='ended',ended_at=now() where id=invite_uuid and status<>'ended';
end $fn$;

revoke all on function public.vl_create_guest_invite(uuid) from public,anon;
revoke all on function public.vl_accept_guest_invite(uuid) from public,anon;
revoke all on function public.vl_end_guest_invite(uuid) from public,anon;
grant execute on function public.vl_create_guest_invite(uuid),public.vl_accept_guest_invite(uuid),public.vl_end_guest_invite(uuid) to authenticated;
