-- Prumo: equipes (ambientes compartilhados, como uma empresa ou família)
-- Cada equipe tem agenda e/ou finanças próprias. Não substitui o Prumo pessoal de ninguém.
-- Cole no SQL Editor do Supabase e clique em Run.

create table if not exists public.teams (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 60),
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  share_fin   boolean not null default true,
  share_agenda boolean not null default true,
  created_at  timestamptz not null default now()
);
create table if not exists public.team_members (
  team_id   uuid not null references public.teams (id) on delete cascade,
  uid       uuid not null references auth.users (id) on delete cascade,
  email     text not null,
  nick      text,
  joined_at timestamptz not null default now(),
  primary key (team_id, uid)
);
create table if not exists public.team_invites (
  team_id    uuid not null references public.teams (id) on delete cascade,
  email      text not null,
  invited_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (team_id, email)
);
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.team_invites enable row level security;

create or replace function public.is_team_member(p_team text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.team_members m where m.team_id::text = p_team and m.uid = auth.uid());
$$;

-- O que cada documento da equipe exige: fin -> finanças ligadas; agenda -> agenda ligada
create or replace function public.team_can(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.teams t join public.team_members m on m.team_id = t.id and m.uid = auth.uid()
    where t.id::text = split_part(p_path, '/', 2)
      and ((split_part(p_path, '/', 3) = 'fin' and t.share_fin)
        or (split_part(p_path, '/', 3) = 'agenda' and t.share_agenda)));
$$;

create policy "equipes: ver" on public.teams for select to authenticated using (public.is_team_member(id::text));
create policy "equipes: ver membros" on public.team_members for select to authenticated using (public.is_team_member(team_id::text));
create policy "equipes: ver convites" on public.team_invites for select to authenticated using (public.is_team_member(team_id::text));
grant select on public.teams, public.team_members, public.team_invites to authenticated;

create policy "dados da equipe" on public.docs for all to authenticated
  using (path like 'teams/%' and public.team_can(path))
  with check (path like 'teams/%' and public.team_can(path));

-- Minhas equipes, com membros e convites pendentes
create or replace function public.my_teams()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'name', t.name, 'owner', t.owner, 'share_fin', t.share_fin, 'share_agenda', t.share_agenda,
    'members', (select coalesce(jsonb_agg(jsonb_build_object('uid', m.uid, 'email', m.email, 'nick', m.nick) order by m.joined_at), '[]'::jsonb)
                from public.team_members m where m.team_id = t.id),
    'invites', (select coalesce(jsonb_agg(i.email order by i.created_at), '[]'::jsonb) from public.team_invites i where i.team_id = t.id)
  ) order by t.created_at), '[]'::jsonb)
  from public.teams t where exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid());
$$;

-- Convites para o meu e-mail
create or replace function public.my_team_invites()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object('team_id', t.id, 'name', t.name,
    'from', (select coalesce(m.nick, m.email) from public.team_members m where m.team_id = t.id and m.uid = i.invited_by))), '[]'::jsonb)
  from public.team_invites i join public.teams t on t.id = i.team_id
  where lower(i.email) = lower((select email from auth.users where id = auth.uid()))
    and not exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid());
$$;

create or replace function public.create_team(p_name text, p_fin boolean, p_agenda boolean, p_nick text)
returns uuid language plpgsql security definer set search_path = public, auth as $$
declare tid uuid; me uuid := auth.uid(); em text;
begin
  if me is null then raise exception 'não autenticado'; end if;
  if (select count(*) from public.teams where owner = me) >= 10 then raise exception 'limite de equipes'; end if;
  select email into em from auth.users where id = me;
  insert into public.teams (name, owner, share_fin, share_agenda) values (trim(p_name), me, coalesce(p_fin, true), coalesce(p_agenda, true)) returning id into tid;
  insert into public.team_members (team_id, uid, email, nick) values (tid, me, em, left(trim(coalesce(p_nick, '')), 40));
  return tid;
end $$;

create or replace function public.update_team(p_team uuid, p_name text, p_fin boolean, p_agenda boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.teams set name = coalesce(nullif(trim(p_name), ''), name), share_fin = coalesce(p_fin, share_fin), share_agenda = coalesce(p_agenda, share_agenda)
   where id = p_team and owner = auth.uid();
  if not found then raise exception 'só quem criou a equipe pode mudar'; end if;
end $$;

create or replace function public.invite_to_team(p_team uuid, p_email text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.teams where id = p_team and owner = auth.uid()) then raise exception 'só quem criou a equipe pode convidar'; end if;
  if p_email !~ '^\S+@\S+\.\S+$' then raise exception 'e-mail inválido'; end if;
  if (select count(*) from public.team_invites where team_id = p_team) >= 30 then raise exception 'limite de convites'; end if;
  insert into public.team_invites (team_id, email, invited_by) values (p_team, lower(trim(p_email)), auth.uid()) on conflict do nothing;
end $$;

create or replace function public.set_team_nick(p_team uuid, p_nick text)
returns void language sql security definer set search_path = public as $$
  update public.team_members set nick = left(trim(coalesce(p_nick, '')), 40) where team_id = p_team and uid = auth.uid();
$$;

grant execute on function public.my_teams(), public.my_team_invites(), public.create_team(text, boolean, boolean, text),
  public.update_team(uuid, text, boolean, boolean), public.invite_to_team(uuid, text),
  public.set_team_nick(uuid, text) to authenticated;

-- Sair, remover e responder convites (sem apagar dados: só marca como inativo)
alter table public.teams add column if not exists archived boolean not null default false;
alter table public.team_members add column if not exists active boolean not null default true;
alter table public.team_invites add column if not exists answered boolean not null default false;

create or replace function public.is_team_member(p_team text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.team_members m join public.teams t on t.id = m.team_id
    where m.team_id::text = p_team and m.uid = auth.uid() and m.active and not t.archived);
$$;

create or replace function public.team_can(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.teams t join public.team_members m on m.team_id = t.id and m.uid = auth.uid() and m.active
    where t.id::text = split_part(p_path, '/', 2) and not t.archived
      and ((split_part(p_path, '/', 3) = 'fin' and t.share_fin)
        or (split_part(p_path, '/', 3) = 'agenda' and t.share_agenda)));
$$;

create or replace function public.my_teams()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'name', t.name, 'owner', t.owner, 'share_fin', t.share_fin, 'share_agenda', t.share_agenda,
    'members', (select coalesce(jsonb_agg(jsonb_build_object('uid', m.uid, 'email', m.email, 'nick', m.nick) order by m.joined_at), '[]'::jsonb)
                from public.team_members m where m.team_id = t.id and m.active),
    'invites', (select coalesce(jsonb_agg(i.email order by i.created_at), '[]'::jsonb) from public.team_invites i where i.team_id = t.id and not i.answered)
  ) order by t.created_at), '[]'::jsonb)
  from public.teams t where not t.archived and exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid() and m.active);
$$;

create or replace function public.my_team_invites()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object('team_id', t.id, 'name', t.name,
    'from', (select coalesce(nullif(m.nick, ''), m.email) from public.team_members m where m.team_id = t.id and m.uid = i.invited_by))), '[]'::jsonb)
  from public.team_invites i join public.teams t on t.id = i.team_id
  where not i.answered and not t.archived
    and lower(i.email) = lower((select email from auth.users where id = auth.uid()))
    and not exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid() and m.active);
$$;

create or replace function public.invite_to_team(p_team uuid, p_email text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.teams where id = p_team and owner = auth.uid() and not archived) then raise exception 'só quem criou a equipe pode convidar'; end if;
  if p_email !~ '^\S+@\S+\.\S+$' then raise exception 'e-mail inválido'; end if;
  if (select count(*) from public.team_invites where team_id = p_team and not answered) >= 30 then raise exception 'limite de convites'; end if;
  insert into public.team_invites (team_id, email, invited_by) values (p_team, lower(trim(p_email)), auth.uid())
    on conflict (team_id, email) do update set answered = false, invited_by = excluded.invited_by, created_at = now();
end $$;

create or replace function public.cancel_team_invite(p_team uuid, p_email text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.team_invites set answered = true where team_id = p_team and lower(email) = lower(p_email)
    and exists (select 1 from public.teams where id = p_team and owner = auth.uid());
end $$;

create or replace function public.answer_team_invite(p_team uuid, p_accept boolean, p_nick text)
returns void language plpgsql security definer set search_path = public, auth as $$
declare me uuid := auth.uid(); em text;
begin
  select email into em from auth.users where id = me;
  if not exists (select 1 from public.team_invites where team_id = p_team and lower(email) = lower(em) and not answered) then raise exception 'convite não encontrado'; end if;
  if p_accept then
    insert into public.team_members (team_id, uid, email, nick) values (p_team, me, em, left(trim(coalesce(p_nick, '')), 40))
      on conflict (team_id, uid) do update set active = true, nick = excluded.nick;
  end if;
  update public.team_invites set answered = true where team_id = p_team and lower(email) = lower(em);
end $$;

create or replace function public.leave_team(p_team uuid, p_uid uuid)
returns void language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); own uuid;
begin
  select owner into own from public.teams where id = p_team;
  if own is null then return; end if;
  if coalesce(p_uid, me) = me then
    if own = me then update public.teams set archived = true where id = p_team;
    else update public.team_members set active = false where team_id = p_team and uid = me; end if;
  elsif own = me then update public.team_members set active = false where team_id = p_team and uid = p_uid;
  else raise exception 'sem permissão'; end if;
end $$;

grant execute on function public.cancel_team_invite(uuid, text), public.answer_team_invite(uuid, boolean, text), public.leave_team(uuid, uuid) to authenticated;

-- Módulos escolhidos por equipe (o criador liga e desliga quando quiser)
alter table public.teams add column if not exists features jsonb not null default '{}'::jsonb;
create or replace function public.team_feat(f jsonb, k text)
returns boolean language sql immutable as $$ select coalesce((f ->> k)::boolean, false) $$;
create or replace function public.team_can(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.teams t join public.team_members m on m.team_id = t.id and m.uid = auth.uid() and m.active
    where t.id::text = split_part(p_path, '/', 2) and not t.archived
      and case
        when split_part(p_path, '/', 3) = 'agenda' then public.team_feat(t.features, 'agenda') or public.team_feat(t.features, 'tasks')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'quotes' then public.team_feat(t.features, 'quotes')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'vaq' then public.team_feat(t.features, 'vaq')
        when split_part(p_path, '/', 3) = 'fin' then public.team_feat(t.features, 'fin')
        else false end);
$$;
create or replace function public.my_teams()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'name', t.name, 'owner', t.owner, 'features', t.features,
    'members', (select coalesce(jsonb_agg(jsonb_build_object('uid', m.uid, 'email', m.email, 'nick', m.nick) order by m.joined_at), '[]'::jsonb)
                from public.team_members m where m.team_id = t.id and m.active),
    'invites', (select coalesce(jsonb_agg(i.email order by i.created_at), '[]'::jsonb) from public.team_invites i where i.team_id = t.id and not i.answered)
  ) order by t.created_at), '[]'::jsonb)
  from public.teams t where not t.archived and exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid() and m.active);
$$;
create or replace function public.team_clean_features(p jsonb)
returns jsonb language sql immutable as $$
  select jsonb_build_object('agenda', public.team_feat(p, 'agenda'), 'tasks', public.team_feat(p, 'tasks'),
    'fin', public.team_feat(p, 'fin'), 'quotes', public.team_feat(p, 'quotes'), 'vaq', public.team_feat(p, 'vaq'));
$$;
create or replace function public.team_create(p_name text, p_features jsonb, p_nick text)
returns uuid language plpgsql security definer set search_path = public, auth as $$
declare tid uuid; me uuid := auth.uid(); em text;
begin
  if me is null then raise exception 'não autenticado'; end if;
  if (select count(*) from public.teams where owner = me and not archived) >= 10 then raise exception 'limite de equipes'; end if;
  select email into em from auth.users where id = me;
  insert into public.teams (name, owner, features) values (trim(p_name), me, public.team_clean_features(p_features)) returning id into tid;
  insert into public.team_members (team_id, uid, email, nick) values (tid, me, em, left(trim(coalesce(p_nick, '')), 40));
  return tid;
end $$;
create or replace function public.team_update(p_team uuid, p_name text, p_features jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.teams set name = coalesce(nullif(trim(p_name), ''), name),
    features = case when p_features is null then features else public.team_clean_features(p_features) end
   where id = p_team and owner = auth.uid() and not archived;
  if not found then raise exception 'só quem criou a equipe pode mudar'; end if;
end $$;
grant execute on function public.team_create(text, jsonb, text), public.team_update(uuid, text, jsonb) to authenticated;

-- Módulo Projetos (fica no mesmo documento da agenda da equipe)
create or replace function public.team_clean_features(p jsonb)
returns jsonb language sql immutable as $$
  select jsonb_build_object('agenda', public.team_feat(p, 'agenda'), 'tasks', public.team_feat(p, 'tasks'),
    'fin', public.team_feat(p, 'fin'), 'quotes', public.team_feat(p, 'quotes'), 'vaq', public.team_feat(p, 'vaq'),
    'proj', public.team_feat(p, 'proj'));
$$;
create or replace function public.team_can(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.teams t join public.team_members m on m.team_id = t.id and m.uid = auth.uid() and m.active
    where t.id::text = split_part(p_path, '/', 2) and not t.archived
      and case
        when split_part(p_path, '/', 3) = 'agenda' then public.team_feat(t.features, 'agenda') or public.team_feat(t.features, 'tasks') or public.team_feat(t.features, 'proj')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'quotes' then public.team_feat(t.features, 'quotes')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'vaq' then public.team_feat(t.features, 'vaq')
        when split_part(p_path, '/', 3) = 'fin' then public.team_feat(t.features, 'fin')
        else false end);
$$;

-- Módulo Desafios (check-ins com foto, estilo GymRats)
create or replace function public.team_clean_features(p jsonb)
returns jsonb language sql immutable set search_path = public as $$
  select jsonb_build_object('agenda', public.team_feat(p, 'agenda'), 'tasks', public.team_feat(p, 'tasks'),
    'fin', public.team_feat(p, 'fin'), 'quotes', public.team_feat(p, 'quotes'), 'vaq', public.team_feat(p, 'vaq'),
    'proj', public.team_feat(p, 'proj'), 'desafios', public.team_feat(p, 'desafios'));
$$;
create or replace function public.team_can(p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.teams t join public.team_members m on m.team_id = t.id and m.uid = auth.uid() and m.active
    where t.id::text = split_part(p_path, '/', 2) and not t.archived
      and case
        when split_part(p_path, '/', 3) = 'agenda' then public.team_feat(t.features, 'agenda') or public.team_feat(t.features, 'tasks') or public.team_feat(t.features, 'proj')
        when split_part(p_path, '/', 3) = 'chal' then public.team_feat(t.features, 'desafios')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'quotes' then public.team_feat(t.features, 'quotes')
        when split_part(p_path, '/', 3) = 'fin' and split_part(p_path, '/', 4) = 'vaq' then public.team_feat(t.features, 'vaq')
        when split_part(p_path, '/', 3) = 'fin' then public.team_feat(t.features, 'fin')
        else false end);
$$;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('checkins', 'checkins', false, 300000, array['image/jpeg', 'image/webp']) on conflict (id) do nothing;
create policy "desafios: ver fotos da equipe" on storage.objects for select to authenticated
  using (bucket_id = 'checkins' and public.team_can('teams/' || (storage.foldername(name))[1] || '/chal'));
create policy "desafios: enviar minha foto" on storage.objects for insert to authenticated
  with check (bucket_id = 'checkins' and public.team_can('teams/' || (storage.foldername(name))[1] || '/chal')
              and (storage.foldername(name))[3] = (select auth.uid())::text);
create policy "desafios: apagar minha foto" on storage.objects for delete to authenticated
  using (bucket_id = 'checkins' and (storage.foldername(name))[3] = (select auth.uid())::text);

-- Porquinho de cada membro (só aparência: roupinhas, humor e se usa mascote)
alter table public.team_members add column if not exists pig jsonb;
create or replace function public.set_my_pig(p jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'não autenticado'; end if;
  if p is not null and octet_length(p::text) > 2000 then raise exception 'grande demais'; end if;
  update public.team_members set pig = p where uid = auth.uid();
end $$;
create or replace function public.my_teams()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'name', t.name, 'owner', t.owner, 'features', t.features,
    'members', (select coalesce(jsonb_agg(jsonb_build_object('uid', m.uid, 'email', m.email, 'nick', m.nick, 'pig', m.pig) order by m.joined_at), '[]'::jsonb)
                from public.team_members m where m.team_id = t.id and m.active),
    'invites', (select coalesce(jsonb_agg(i.email order by i.created_at), '[]'::jsonb) from public.team_invites i where i.team_id = t.id and not i.answered)
  ) order by t.created_at), '[]'::jsonb)
  from public.teams t where not t.archived and exists (select 1 from public.team_members m where m.team_id = t.id and m.uid = auth.uid() and m.active);
$$;
grant execute on function public.set_my_pig(jsonb) to authenticated;

-- E-mail profissional por equipe (avisos de tarefas e projetos por e-mail)
alter table public.team_members add column if not exists work_email text;
create or replace function public.my_work_email(p_team uuid) returns text
language sql security definer set search_path=public as $$
  select coalesce(work_email,'~') from team_members where team_id=p_team and uid=auth.uid() and active
$$;
create or replace function public.set_my_work_email(p_team uuid, p_email text) returns boolean
language plpgsql security definer set search_path=public as $$
declare e text := lower(trim(coalesce(p_email,'')));
begin
  if e <> '' and (length(e) > 120 or e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') then raise exception 'e-mail inválido'; end if;
  update team_members set work_email = e where team_id=p_team and uid=auth.uid() and active;
  return found;
end $$;
revoke all on function public.my_work_email(uuid) from public, anon;
revoke all on function public.set_my_work_email(uuid,text) from public, anon;
grant execute on function public.my_work_email(uuid) to authenticated;
grant execute on function public.set_my_work_email(uuid,text) to authenticated;

-- Fotos e áudios dos desafios: até 1 MB por arquivo (fotos são reduzidas no aparelho; áudios de até 60 s)
update storage.buckets set file_size_limit=1048576, allowed_mime_types=array['image/jpeg','image/webp','audio/webm','audio/mp4','audio/ogg','audio/mpeg','audio/aac','audio/x-m4a'] where id='checkins';
