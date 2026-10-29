-- Run in Supabase SQL Editor.
create table if not exists public.tournament_state (id integer primary key check (id = 1), state jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
insert into public.tournament_state (id, state) values (1, '{}'::jsonb) on conflict (id) do nothing;
create table if not exists public.tournament_admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
alter table public.tournament_state enable row level security;
alter table public.tournament_admins enable row level security;
create or replace function public.is_tournament_admin() returns boolean language sql stable security definer set search_path = '' as $$ select exists (select 1 from public.tournament_admins a where a.user_id = (select auth.uid())); $$;
revoke all on function public.is_tournament_admin() from public;
grant execute on function public.is_tournament_admin() to anon, authenticated;
drop policy if exists "Anyone can read tournament" on public.tournament_state;
create policy "Anyone can read tournament" on public.tournament_state for select to anon, authenticated using (true);
drop policy if exists "Only tournament admin can update" on public.tournament_state;
create policy "Only tournament admin can update" on public.tournament_state for update to authenticated using (public.is_tournament_admin()) with check (public.is_tournament_admin());
drop policy if exists "Admins can read own admin status" on public.tournament_admins;
create policy "Admins can read own admin status" on public.tournament_admins for select to authenticated using (user_id = (select auth.uid()));
grant select on public.tournament_state to anon, authenticated;
grant update on public.tournament_state to authenticated;
grant select on public.tournament_admins to authenticated;
