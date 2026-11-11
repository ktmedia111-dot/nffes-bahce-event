-- NFFES Bahçe Event: Supabase başlangıç şeması
-- SQL Editor içinde çalıştırın. RLS varsayılan olarak etkinleştirilmiştir.
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  note text,
  created_at timestamptz not null default now()
);
create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(12,2) not null default 0,
  description text,
  created_at timestamptz not null default now()
);
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text not null,
  phone text,
  email text,
  event_date date not null,
  event_type text not null,
  status text not null default 'Beklemede',
  total_price numeric(12,2) not null default 0,
  deposit numeric(12,2) not null default 0,
  note text,
  created_at timestamptz not null default now()
);
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null,
  title text not null,
  amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);
alter table public.customers enable row level security;
alter table public.packages enable row level security;
alter table public.reservations enable row level security;
alter table public.expenses enable row level security;
-- Güvenli varsayılan: RLS açık, erişim politikası yok.
-- Uygulamayı personele açmadan önce Supabase Auth tabanlı,
-- yalnızca yetkili kullanıcılara izin veren politikalar ekleyin.
