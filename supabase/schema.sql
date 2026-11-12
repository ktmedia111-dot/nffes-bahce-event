-- N'fess Bahçe Event: idempotent application schema.
-- Run this first in Supabase SQL Editor. Existing customer/reservation data is preserved.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'staff',
  approval_status text not null default 'pending',
  can_add_customers boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.profiles add column if not exists full_name text default '';
alter table public.profiles add column if not exists role text default 'staff';
alter table public.profiles add column if not exists approval_status text default 'pending';
alter table public.profiles add column if not exists can_add_customers boolean default false;
alter table public.profiles add column if not exists created_at timestamptz default now();
update public.profiles set full_name = coalesce(full_name, ''),
  role = coalesce(role, 'staff'), approval_status = coalesce(approval_status, 'pending'),
  can_add_customers = coalesce(can_add_customers, false), created_at = coalesce(created_at, now());
alter table public.profiles alter column full_name set default '';
alter table public.profiles alter column full_name set not null;
alter table public.profiles alter column role set default 'staff';
alter table public.profiles alter column role set not null;
alter table public.profiles alter column approval_status set default 'pending';
alter table public.profiles alter column approval_status set not null;
alter table public.profiles alter column can_add_customers set default false;
alter table public.profiles alter column can_add_customers set not null;
alter table public.profiles alter column created_at set default now();
alter table public.profiles alter column created_at set not null;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  address text,
  note text,
  created_at timestamptz not null default now()
);
alter table public.customers add column if not exists phone text;
alter table public.customers add column if not exists email text;
alter table public.customers add column if not exists address text;
alter table public.customers add column if not exists note text;
alter table public.customers add column if not exists created_at timestamptz default now();
update public.customers set created_at = coalesce(created_at, now());
alter table public.customers alter column created_at set default now();
alter table public.customers alter column created_at set not null;

create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(12,2) not null default 0,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.packages add column if not exists price numeric(12,2) default 0;
alter table public.packages add column if not exists description text;
alter table public.packages add column if not exists is_active boolean default true;
alter table public.packages add column if not exists created_at timestamptz default now();
update public.packages set price = coalesce(price, 0), is_active = coalesce(is_active, true),
  created_at = coalesce(created_at, now());
alter table public.packages alter column price set default 0;
alter table public.packages alter column price set not null;
alter table public.packages alter column is_active set default true;
alter table public.packages alter column is_active set not null;
alter table public.packages alter column created_at set default now();
alter table public.packages alter column created_at set not null;

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text,
  phone text,
  email text,
  package_id uuid references public.packages(id) on delete set null,
  event_date date,
  event_type text default 'Düğün',
  status text default 'Beklemede',
  total_price numeric(12,2) default 0,
  deposit numeric(12,2) default 0,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);
alter table public.reservations add column if not exists customer_id uuid references public.customers(id) on delete set null;
alter table public.reservations add column if not exists customer_name text;
alter table public.reservations add column if not exists phone text;
alter table public.reservations add column if not exists email text;
alter table public.reservations add column if not exists package_id uuid references public.packages(id) on delete set null;
alter table public.reservations add column if not exists event_date date;
alter table public.reservations add column if not exists event_type text default 'Düğün';
alter table public.reservations add column if not exists status text default 'Beklemede';
alter table public.reservations add column if not exists total_price numeric(12,2) default 0;
alter table public.reservations add column if not exists deposit numeric(12,2) default 0;
alter table public.reservations add column if not exists note text;
alter table public.reservations add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.reservations add column if not exists created_at timestamptz default now();
update public.reservations r set customer_name = coalesce(
  nullif(btrim(r.customer_name), ''),
  (select nullif(btrim(c.name), '') from public.customers c where c.id = r.customer_id),
  'Eski kayıt'
) where r.customer_name is null or btrim(r.customer_name) = '';
update public.reservations set event_date = coalesce(event_date, created_at::date, current_date),
  event_type = coalesce(nullif(btrim(event_type), ''), 'Düğün'),
  status = coalesce(nullif(btrim(status), ''), 'Beklemede'),
  total_price = coalesce(total_price, 0), deposit = coalesce(deposit, 0), created_at = coalesce(created_at, now());
alter table public.reservations alter column customer_name set not null;
alter table public.reservations alter column event_date set not null;
alter table public.reservations alter column event_type set default 'Düğün';
alter table public.reservations alter column event_type set not null;
alter table public.reservations alter column status set default 'Beklemede';
alter table public.reservations alter column status set not null;
alter table public.reservations alter column total_price set default 0;
alter table public.reservations alter column total_price set not null;
alter table public.reservations alter column deposit set default 0;
alter table public.reservations alter column deposit set not null;
alter table public.reservations alter column created_at set default now();
alter table public.reservations alter column created_at set not null;

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  amount numeric(12,2) not null default 0,
  payment_type text not null default 'Kapora',
  payment_method text not null default 'Nakit',
  payment_date date not null default current_date,
  note text,
  received_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.payments add column if not exists reservation_id uuid references public.reservations(id) on delete cascade;
alter table public.payments add column if not exists amount numeric(12,2) default 0;
alter table public.payments add column if not exists payment_type text default 'Kapora';
alter table public.payments add column if not exists payment_method text default 'Nakit';
alter table public.payments add column if not exists payment_date date default current_date;
alter table public.payments add column if not exists note text;
alter table public.payments add column if not exists received_by uuid references auth.users(id) on delete set null;
alter table public.payments add column if not exists created_at timestamptz default now();
update public.payments set amount = coalesce(amount, 0), payment_type = coalesce(payment_type, 'Kapora'),
  payment_method = coalesce(payment_method, 'Nakit'), payment_date = coalesce(payment_date, current_date),
  created_at = coalesce(created_at, now());
alter table public.payments alter column amount set default 0;
alter table public.payments alter column amount set not null;
alter table public.payments alter column payment_type set default 'Kapora';
alter table public.payments alter column payment_type set not null;
alter table public.payments alter column payment_method set default 'Nakit';
alter table public.payments alter column payment_method set not null;
alter table public.payments alter column payment_date set default current_date;
alter table public.payments alter column payment_date set not null;
alter table public.payments alter column created_at set default now();
alter table public.payments alter column created_at set not null;

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null default current_date,
  title text not null,
  category text,
  amount numeric(12,2) not null default 0,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.expenses add column if not exists expense_date date default current_date;
alter table public.expenses add column if not exists title text;
alter table public.expenses add column if not exists category text;
alter table public.expenses add column if not exists amount numeric(12,2) default 0;
alter table public.expenses add column if not exists note text;
alter table public.expenses add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.expenses add column if not exists created_at timestamptz default now();
update public.expenses set expense_date = coalesce(expense_date, created_at::date, current_date),
  title = coalesce(nullif(btrim(title), ''), 'Eski gider'), amount = coalesce(amount, 0),
  created_at = coalesce(created_at, now());
alter table public.expenses alter column expense_date set default current_date;
alter table public.expenses alter column expense_date set not null;
alter table public.expenses alter column title set not null;
alter table public.expenses alter column amount set default 0;
alter table public.expenses alter column amount set not null;
alter table public.expenses alter column created_at set default now();
alter table public.expenses alter column created_at set not null;

create index if not exists reservations_event_date_idx on public.reservations(event_date);
create index if not exists reservations_customer_id_idx on public.reservations(customer_id);
create index if not exists payments_reservation_id_idx on public.payments(reservation_id);
create index if not exists payments_payment_date_idx on public.payments(payment_date);
create index if not exists expenses_expense_date_idx on public.expenses(expense_date);

alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.packages enable row level security;
alter table public.reservations enable row level security;
alter table public.payments enable row level security;
alter table public.expenses enable row level security;
