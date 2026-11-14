-- Guest presence keeps disconnected devices from occupying one of the three seats forever.
alter table public.vl_guest_invites add column if not exists guest_heartbeat_at timestamptz;

create or replace function public.vl_guest_heartbeat(invite_uuid uuid)
returns boolean language plpgsql security definer set search_path='' as $fn$
begin
 update public.vl_guest_invites set guest_heartbeat_at=now()
 where id=invite_uuid and guest_id=auth.uid() and status='accepted';
 return found;
end $fn$;
revoke all on function public.vl_guest_heartbeat(uuid) from public,anon;
grant execute on function public.vl_guest_heartbeat(uuid) to authenticated;

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
 perform pg_advisory_xact_lock(hashtext(invitation.room_id::text));
 if invitation.status='accepted' and invitation.guest_id=caller then
  update public.vl_guest_invites set guest_heartbeat_at=now() where id=invitation.id;
  return invitation.room_id;
 end if;
 if invitation.status<>'pending' or invitation.created_at<now()-interval '30 minutes' then raise exception 'Invitación vencida o utilizada'; end if;
 if (select count(*) from public.vl_guest_invites where room_id=invitation.room_id and status='accepted' and guest_heartbeat_at>now()-interval '70 seconds') >=3
 then raise exception 'Este live ya tiene tres invitados'; end if;
 update public.vl_guest_invites set guest_id=caller,status='accepted',accepted_at=now(),guest_heartbeat_at=now() where id=invite_uuid;
 return invitation.room_id;
end $fn$;
revoke all on function public.vl_accept_guest_invite(uuid) from public,anon;
grant execute on function public.vl_accept_guest_invite(uuid) to authenticated;
