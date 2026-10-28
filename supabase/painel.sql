-- Prumo: painel do administrador
-- Cole tudo no SQL Editor do Supabase e clique em Run. Pode rodar mais de uma vez.
-- Mostra números gerais do app e a lista de contas (e-mail e datas).
-- O perfil completo de uma pessoa só aparece se ela autorizou no app (Perfil > Dicas personalizadas).

-- Quem é administrador (troque o e-mail se for outro)
create table if not exists public.admins (email text primary key);
alter table public.admins enable row level security; -- ninguém lê esta tabela pelo app
insert into public.admins (email) values ('mateuslealpsi@gmail.com') on conflict do nothing;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (
    select 1 from public.admins a join auth.users u on lower(u.email) = lower(a.email)
    where u.id = auth.uid() and u.email_confirmed_at is not null);
$$;

create or replace function public.prumo_has(j jsonb)
returns boolean language sql immutable as $$
  select j is not null and jsonb_typeof(j) = 'object' and j <> '{}'::jsonb;
$$;

-- Números gerais
create or replace function public.admin_stats()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare r jsonb;
begin
  if not public.is_admin() then raise exception 'acesso negado'; end if;
  with u as (select id, created_at, email_confirmed_at from auth.users),
  app as (select data, updated_at from public.docs where path like 'data/users/%/app'),
  fmeta as (select data from public.docs where path like 'data/users/%/fin-meta' or path like 'households/%/fin/meta'),
  fmon as (select distinct split_part(path, '/', 3) uid from public.docs where path ~ '^data/users/[^/]+/fin-m[0-9]{6}$')
  select jsonb_build_object(
    'users',      (select count(*) from u),
    'confirmed',  (select count(*) from u where email_confirmed_at is not null),
    'new7',       (select count(*) from u where created_at > now() - interval '7 days'),
    'new30',      (select count(*) from u where created_at > now() - interval '30 days'),
    'active1',    (select count(*) from app where updated_at > now() - interval '1 day'),
    'active7',    (select count(*) from app where updated_at > now() - interval '7 days'),
    'active30',   (select count(*) from app where updated_at > now() - interval '30 days'),
    'onboarded',  (select count(*) from app where data -> 'profile' ->> 'created' is not null),
    'pet',        (select count(*) from app where data -> 'profile' ->> 'pet' = 'true'),
    'prayer',     (select count(*) from app where data -> 'profile' ->> 'prayer' = 'true'),
    'study',      (select count(*) from app where public.prumo_has(data -> 'study' -> 'logs')),
    'exercise',   (select count(*) from app where public.prumo_has(data -> 'ex' -> 'logs')),
    'food',       (select count(*) from app where public.prumo_has(data -> 'food' -> 'logs')),
    'tasks',      (select count(*) from app where public.prumo_has(data -> 'tasks' -> 'items')),
    'finance',    (select count(*) from fmon),
    'cards',      (select count(*) from fmeta where public.prumo_has(data -> 'cards')),
    'debts',      (select count(*) from fmeta where public.prumo_has(data -> 'debts')),
    'households', (select count(distinct code) from public.household_members),
    'signups',    (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
                   from (select created_at::date d, count(*) n from u
                         where created_at > now() - interval '30 days' group by 1) s),
    'focus',      (select coalesce(jsonb_object_agg(f, n), '{}'::jsonb)
                   from (select jsonb_array_elements_text(data -> 'profile' -> 'focus') f, count(*) n
                         from app where jsonb_typeof(data -> 'profile' -> 'focus') = 'array' group by 1) s)
  ) into r;
  return r;
end $$;

-- Lista de contas: e-mail, datas e se a pessoa autorizou o perfil completo
drop function if exists public.admin_users();
create or replace function public.admin_users()
returns table (email text, created_at timestamptz, last_sign_in_at timestamptz, confirmed boolean, last_activity timestamptz, onboarded boolean, shared boolean)
language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'acesso negado'; end if;
  return query
    select u.email::text, u.created_at, u.last_sign_in_at, u.email_confirmed_at is not null,
           d.updated_at, coalesce(d.data -> 'profile' ->> 'created' is not null, false),
           coalesce(d.data -> 'profile' ->> 'shareAdmin' = 'true', false)
    from auth.users u
    left join public.docs d on d.path = 'data/users/' || u.id::text || '/app'
    order by u.created_at desc;
end $$;

-- Perfil de uma pessoa: só o que ela liberou em Perfil > Dicas personalizadas
create or replace function public.admin_user_detail(p_email text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare uid uuid; full_app jsonb; ar jsonb; appd jsonb; prof jsonb; fin jsonb := '{}'::jsonb;
begin
  if not public.is_admin() then raise exception 'acesso negado'; end if;
  select id into uid from auth.users where lower(email) = lower(p_email);
  if uid is null then raise exception 'conta não encontrada'; end if;
  select data into full_app from public.docs where path = 'data/users/' || uid::text || '/app';
  if coalesce(full_app -> 'profile' ->> 'shareAdmin', 'false') <> 'true' then raise exception 'sem autorização'; end if;
  ar := coalesce(full_app -> 'profile' -> 'shareAreas',
                 '{"fin":true,"saude":true,"estudo":true,"rotina":true,"fe":true}'::jsonb);
  -- sempre: perfil básico e uso do app
  prof := (full_app -> 'profile') - 'weight' - 'height' - 'level' - 'parq' - 'cleared' - 'prayer' - 'household';
  appd := jsonb_build_object('profile', prof, 'activity', full_app -> 'activity', 'learn', full_app -> 'learn',
                             'pet', full_app -> 'pet', 'missionDays', full_app -> 'missionDays');
  if (ar ->> 'saude') = 'true' then
    appd := appd || jsonb_build_object('ex', full_app -> 'ex', 'food', full_app -> 'food', 'weight', full_app -> 'weight')
                 || jsonb_build_object('profile', prof || jsonb_build_object('weight', full_app -> 'profile' -> 'weight',
                      'height', full_app -> 'profile' -> 'height', 'level', full_app -> 'profile' -> 'level'));
  end if;
  if (ar ->> 'estudo') = 'true' then appd := appd || jsonb_build_object('study', full_app -> 'study'); end if;
  if (ar ->> 'rotina') = 'true' then appd := appd || jsonb_build_object('tasks', full_app -> 'tasks', 'agenda', full_app -> 'agenda'); end if;
  if (ar ->> 'fe') = 'true' then
    appd := appd || jsonb_build_object('prayer', full_app -> 'prayer');
    appd := jsonb_set(appd, '{profile,prayer}', coalesce(full_app -> 'profile' -> 'prayer', 'false'::jsonb), true);
  end if;
  if (ar ->> 'fin') = 'true' then
    select coalesce(jsonb_object_agg(split_part(path, '/fin-', 2), data), '{}'::jsonb) into fin
      from public.docs where path like 'data/users/' || uid::text || '/fin-%';
  end if;
  return jsonb_build_object('app', appd, 'fin', fin, 'areas', ar);
end $$;

revoke all on function public.is_admin() from public, anon;
revoke all on function public.admin_stats() from public, anon;
revoke all on function public.admin_users() from public, anon;
revoke all on function public.admin_user_detail(text) from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.admin_stats() to authenticated;
grant execute on function public.admin_users() to authenticated;
grant execute on function public.admin_user_detail(text) to authenticated;

-- Mensagens do Prumo para os usuários (enviadas pelo painel do administrador)
create table if not exists public.messages (
  id         uuid primary key default gen_random_uuid(),
  uid        uuid not null references auth.users (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index if not exists messages_uid_idx on public.messages (uid, created_at desc);
alter table public.messages enable row level security;
drop policy if exists "ver minhas mensagens" on public.messages;
create policy "ver minhas mensagens" on public.messages for select to authenticated using (uid = auth.uid());
revoke all on public.messages from anon;
revoke insert, update, delete on public.messages from authenticated;
grant select on public.messages to authenticated;

create or replace function public.mark_message_read(p_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.messages set read_at = coalesce(read_at, now()) where id = p_id and uid = auth.uid();
$$;

create or replace function public.admin_send_message(p_email text, p_body text)
returns uuid language plpgsql security definer set search_path = public, auth as $$
declare target uuid; new_id uuid;
begin
  if not public.is_admin() then raise exception 'acesso negado'; end if;
  select id into target from auth.users where lower(email) = lower(p_email);
  if target is null then raise exception 'conta não encontrada'; end if;
  insert into public.messages (uid, body) values (target, trim(p_body)) returning id into new_id;
  return new_id;
end $$;

create or replace function public.admin_user_messages(p_email text)
returns table (id uuid, body text, created_at timestamptz, read_at timestamptz)
language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'acesso negado'; end if;
  return query select m.id, m.body, m.created_at, m.read_at from public.messages m
    join auth.users u on u.id = m.uid where lower(u.email) = lower(p_email) order by m.created_at desc limit 30;
end $$;

revoke all on function public.mark_message_read(uuid) from public, anon;
revoke all on function public.admin_send_message(text, text) from public, anon;
revoke all on function public.admin_user_messages(text) from public, anon;
grant execute on function public.mark_message_read(uuid) to authenticated;
grant execute on function public.admin_send_message(text, text) to authenticated;
grant execute on function public.admin_user_messages(text) to authenticated;

-- Orçamentos enviados por link (o cliente abre e aprova sem precisar de conta)
create table if not exists public.quotes_public (
  id            uuid primary key,
  uid           uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data          jsonb not null check (octet_length(data::text) < 500000),
  status        text not null default 'pendente' check (status in ('pendente', 'aprovado', 'recusado')),
  approved_at   timestamptz,
  approved_name text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
alter table public.quotes_public enable row level security;
drop policy if exists "meus orcamentos" on public.quotes_public;
create policy "meus orcamentos" on public.quotes_public for all to authenticated
  using (uid = auth.uid()) with check (uid = auth.uid());
revoke all on public.quotes_public from anon;
grant select, insert, update, delete on public.quotes_public to authenticated;

-- O cliente abre o orçamento pelo código do link
create or replace function public.get_public_quote(p_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('data', data, 'status', status, 'approved_at', approved_at, 'approved_name', approved_name)
  from public.quotes_public where id = p_id;
$$;

-- O cliente aprova (só se estiver pendente e dentro da validade)
create or replace function public.approve_public_quote(p_id uuid, p_name text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  update public.quotes_public
     set status = 'aprovado', approved_at = now(), approved_name = left(trim(coalesce(p_name, '')), 80)
   where id = p_id and status = 'pendente'
     and (data ->> 'validUntil' is null or (data ->> 'validUntil')::date >= (now() at time zone 'America/Sao_Paulo')::date);
  return public.get_public_quote(p_id);
end $$;

grant execute on function public.get_public_quote(uuid) to anon, authenticated;
grant execute on function public.approve_public_quote(uuid, text) to anon, authenticated;

-- Apoios por Pix (a pessoa avisa, o administrador confirma) — ver também equipes.sql

-- Desempenho e segurança (27/10/2026)
create index if not exists team_members_uid_idx on public.team_members (uid);
create index if not exists teams_owner_idx on public.teams (owner);
create index if not exists team_invites_invited_by_idx on public.team_invites (invited_by);
create index if not exists household_members_uid_idx on public.household_members (uid);
alter policy "dados proprios" on public.docs
  using (path like 'data/users/' || (select auth.uid())::text || '/%')
  with check (path like 'data/users/' || (select auth.uid())::text || '/%' and parent = 'data/users/' || (select auth.uid())::text);
alter policy "ver meus apoios" on public.support_claims using (uid = (select auth.uid()));
