-- ============================================================
-- تسجيل (Tasjeel) - Supabase schema
-- نفّذ هذا الملف كاملاً في Supabase SQL Editor لمشروعك
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------
-- 1. players
-- ---------------------------------------------------------------
create table if not exists players (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  normalized_name text not null,
  avatar_path text,
  wins integer not null default 0,
  losses integer not null default 0,
  draws integer not null default 0,
  total_matches integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_players_normalized_name on players (normalized_name);

-- ---------------------------------------------------------------
-- 2. matches
-- ---------------------------------------------------------------
create table if not exists matches (
  id uuid primary key default uuid_generate_v4(),
  game_type text not null check (game_type in ('cards', 'domino')),
  team_a_name text not null,
  team_b_name text not null,
  team_a_player_ids text,   -- CSV من player ids
  team_b_player_ids text,
  team_a_score integer not null default 0,
  team_b_score integer not null default 0,
  team_a_knocks integer not null default 0,
  team_b_knocks integer not null default 0,
  knock_value integer not null default 25,
  win_score integer not null default 101,
  status text not null default 'in_progress' check (status in ('in_progress','finished','cancelled')),
  winner text check (winner in ('A','B','draw')),
  created_at timestamptz not null default now(),
  finished_at timestamptz
);
create index if not exists idx_matches_status on matches (status);
create index if not exists idx_matches_game_type on matches (game_type);
create index if not exists idx_matches_created_at on matches (created_at desc);

-- ---------------------------------------------------------------
-- 3. match_players (ربط اللاعبين بالمباريات ونقاطهم الفردية إن استُخدمت)
-- ---------------------------------------------------------------
create table if not exists match_players (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches(id) on delete cascade,
  player_id uuid not null references players(id) on delete cascade,
  team text not null check (team in ('A','B')),
  individual_score integer not null default 0,
  unique (match_id, player_id)
);
create index if not exists idx_match_players_match on match_players (match_id);
create index if not exists idx_match_players_player on match_players (player_id);

-- ---------------------------------------------------------------
-- 4. leaderboard_stats (ملخص سريع، يُحدَّث تلقائياً بواسطة trigger)
-- ---------------------------------------------------------------
create table if not exists leaderboard_stats (
  player_id uuid primary key references players(id) on delete cascade,
  wins integer not null default 0,
  losses integer not null default 0,
  draws integer not null default 0,
  total_matches integer not null default 0,
  win_rate numeric generated always as (
    case when total_matches = 0 then 0
    else round((wins::numeric / total_matches) * 100, 1) end
  ) stored,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- 5. app_settings (صف واحد فقط - إعدادات عامة)
-- ---------------------------------------------------------------
create table if not exists app_settings (
  id integer primary key default 1,
  home_title text default 'شنو راح تلعب اليوم؟',
  default_domino_win_score integer default 101,
  default_card_knock_value integer default 25,
  maintenance_mode boolean default false,
  maintenance_message text default 'التطبيق تحت الصيانة حالياً، حاول لاحقاً',
  card_image_url text,
  domino_image_url text,
  check (id = 1)
);
insert into app_settings (id) values (1) on conflict (id) do nothing;

-- ---------------------------------------------------------------
-- 6. announcements (إعلانات / تحديثات / رسائل)
-- ---------------------------------------------------------------
create table if not exists announcements (
  id uuid primary key default uuid_generate_v4(),
  type text not null check (type in ('ad','update','message')),
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_announcements_type on announcements (type);

-- ---------------------------------------------------------------
-- 7. admin_settings (صف واحد - كلمة المرور مخزّنة كـ hash فقط)
-- ---------------------------------------------------------------
create table if not exists admin_settings (
  id integer primary key default 1,
  password_hash text not null,
  updated_at timestamptz not null default now(),
  check (id = 1)
);
-- كلمة المرور الأولية AaSsDd2006 مشفّرة بـ SHA-256
-- (استبدلها فوراً من لوحة الأدمن بعد أول تشغيل)
insert into admin_settings (id, password_hash)
values (1, encode(digest('AaSsDd2006', 'sha256'), 'hex'))
on conflict (id) do nothing;

-- ---------------------------------------------------------------
-- 8. match_rounds (تفاصيل كل عملية تسجيل نقاط/طرقة - لدعم التراجع والتدقيق)
-- ---------------------------------------------------------------
create table if not exists match_rounds (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches(id) on delete cascade,
  team text not null check (team in ('A','B')),
  action_type text not null check (action_type in ('points','knock')),
  value integer not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_match_rounds_match on match_rounds (match_id);

-- ============================================================
-- Trigger: تحديث leaderboard_stats تلقائياً عند انتهاء مباراة
-- ============================================================
create or replace function update_leaderboard_on_match_finish()
returns trigger as $$
declare
  p_id uuid;
begin
  if new.status = 'finished' and (old.status is distinct from 'finished') then
    -- تحديث كل لاعب في الفريق A
    for p_id in
      select unnest(string_to_array(coalesce(new.team_a_player_ids, ''), ','))::uuid
      where new.team_a_player_ids is not null and new.team_a_player_ids <> ''
    loop
      insert into leaderboard_stats (player_id, wins, losses, draws, total_matches)
      values (
        p_id,
        case when new.winner = 'A' then 1 else 0 end,
        case when new.winner = 'B' then 1 else 0 end,
        case when new.winner = 'draw' then 1 else 0 end,
        1
      )
      on conflict (player_id) do update set
        wins = leaderboard_stats.wins + (case when new.winner = 'A' then 1 else 0 end),
        losses = leaderboard_stats.losses + (case when new.winner = 'B' then 1 else 0 end),
        draws = leaderboard_stats.draws + (case when new.winner = 'draw' then 1 else 0 end),
        total_matches = leaderboard_stats.total_matches + 1,
        updated_at = now();
    end loop;

    -- تحديث كل لاعب في الفريق B
    for p_id in
      select unnest(string_to_array(coalesce(new.team_b_player_ids, ''), ','))::uuid
      where new.team_b_player_ids is not null and new.team_b_player_ids <> ''
    loop
      insert into leaderboard_stats (player_id, wins, losses, draws, total_matches)
      values (
        p_id,
        case when new.winner = 'B' then 1 else 0 end,
        case when new.winner = 'A' then 1 else 0 end,
        case when new.winner = 'draw' then 1 else 0 end,
        1
      )
      on conflict (player_id) do update set
        wins = leaderboard_stats.wins + (case when new.winner = 'B' then 1 else 0 end),
        losses = leaderboard_stats.losses + (case when new.winner = 'A' then 1 else 0 end),
        draws = leaderboard_stats.draws + (case when new.winner = 'draw' then 1 else 0 end),
        total_matches = leaderboard_stats.total_matches + 1,
        updated_at = now();
    end loop;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_update_leaderboard on matches;
create trigger trg_update_leaderboard
  after update on matches
  for each row
  execute function update_leaderboard_on_match_finish();

-- ============================================================
-- Row Level Security
-- ============================================================
alter table players enable row level security;
alter table matches enable row level security;
alter table match_players enable row level security;
alter table leaderboard_stats enable row level security;
alter table app_settings enable row level security;
alter table announcements enable row level security;
alter table admin_settings enable row level security;
alter table match_rounds enable row level security;

-- قراءة عامة: أي مستخدم (حتى غير مسجّل) يمكنه قراءة اللاعبين، المباريات،
-- لوحة المتصدرين، الإعدادات العامة، والإعلانات (كلها بيانات غير حساسة)
create policy "public read players" on players for select using (true);
create policy "public read matches" on matches for select using (true);
create policy "public read match_players" on match_players for select using (true);
create policy "public read leaderboard" on leaderboard_stats for select using (true);
create policy "public read app_settings" on app_settings for select using (true);
create policy "public read announcements" on announcements for select using (true);
create policy "public read match_rounds" on match_rounds for select using (true);

-- كتابة عامة محدودة: يُسمح لأي مستخدم بإدخال/تحديث نتائج مبارياته الخاصة
-- (لا يوجد تسجيل دخول للمستخدم العادي حسب المواصفات، لذلك الحماية الحقيقية
-- من التلاعب تُطبَّق عبر منطق التطبيق + يمكن تشديدها لاحقاً بإضافة Supabase Auth
-- للمستخدمين وربط كل مباراة بـ user_id عند الحاجة لحماية أعلى)
create policy "public insert players" on players for insert with check (true);
create policy "public update players" on players for update using (true);

create policy "public insert matches" on matches for insert with check (true);
create policy "public update own match" on matches for update using (true);

create policy "public insert match_players" on match_players for insert with check (true);
create policy "public insert match_rounds" on match_rounds for insert with check (true);

-- admin_settings: لا قراءة عامة إطلاقاً لعمود كلمة المرور (حتى عن طريق anon key).
-- التحقق وتغيير كلمة المرور يتمّان فقط عبر دالتي RPC أدناه (SECURITY DEFINER)
-- اللتان تقارنان/تحدّثان الهاش داخل قاعدة البيانات دون كشف العمود مطلقاً للتطبيق.
revoke select, insert, update, delete on admin_settings from anon, authenticated;
create policy "no public access admin_settings" on admin_settings for all using (false);

create or replace function verify_admin_password(plain_password text)
returns boolean as $$
  select password_hash = encode(digest(plain_password, 'sha256'), 'hex')
  from admin_settings where id = 1;
$$ language sql security definer;

create or replace function change_admin_password(new_password text)
returns void as $$
  update admin_settings
  set password_hash = encode(digest(new_password, 'sha256'), 'hex'), updated_at = now()
  where id = 1;
$$ language sql security definer;

-- يسمح لأي عميل anon باستدعاء الدالتين فقط (لا جدول نفسه)
grant execute on function verify_admin_password(text) to anon, authenticated;
grant execute on function change_admin_password(text) to anon, authenticated;
