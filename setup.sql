-- N'fess Bahçe Event: complete database setup/update. Run this file once in Supabase SQL Editor.
-- It preserves application rows, prepares every column used by app.js, and installs role-based RLS.

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

-- ===== Authentication, team management, and access policies =====

-- N'fess Bahçe: personel kaydı, yönetici onayı, ekip yönetimi ve personel silme
-- Supabase SQL Editor'de bir kez çalıştırın.
-- Mevcut admin profilinin rolü/onay durumu korunur. Tablolar silinmez.

-- 1) Her yeni Auth kullanıcısı otomatik olarak bekleyen personel olur.
create or replace function public.nffes_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles as existing_profile
    (id, full_name, role, approval_status, can_add_customers)
  values
    (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), 'staff', 'pending', false)
  on conflict (id) do update
    set full_name = excluded.full_name,
        role = case when existing_profile.role = 'admin' then 'admin' else 'staff' end,
        approval_status = case when existing_profile.role = 'admin' then existing_profile.approval_status else 'pending' end,
        can_add_customers = case when existing_profile.role = 'admin' then existing_profile.can_add_customers else false end;
  return new;
end;
$$;

drop trigger if exists nffes_on_auth_user_created on auth.users;
drop trigger if exists zz_nffes_on_auth_user_created on auth.users;
create trigger zz_nffes_on_auth_user_created
after insert on auth.users
for each row execute procedure public.nffes_handle_new_user();

-- Kurulumdan önce Auth kullanıcısı oluşturulmuşsa eksik profili ekle;
-- var olan admin/personel rollerine dokunma.
insert into public.profiles (id, full_name, role, approval_status, can_add_customers)
select u.id, coalesce(u.raw_user_meta_data->>'full_name', ''), 'staff', 'pending', false
from auth.users u
on conflict (id) do nothing;

-- 2) RLS döngüsü oluşturmadan yönetici kontrolü.
create or replace function public.nffes_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
      and p.approval_status = 'approved'
  );
$$;

-- 3) Personel kendi profilini, admin tüm personel profillerini okuyabilir.
alter table public.profiles enable row level security;

drop policy if exists nffes_profiles_read_self on public.profiles;
create policy nffes_profiles_read_self
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists nffes_profiles_read_admin on public.profiles;
create policy nffes_profiles_read_admin
on public.profiles for select
to authenticated
using (public.nffes_is_admin());

-- 4) Admin personel onayını / reddini değiştirebilir; rol değiştiremez.
create or replace function public.admin_set_staff_status(
  target_user_id uuid,
  new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.nffes_is_admin() then
    raise exception 'Bu işlem yalnızca onaylı yönetici tarafından yapılabilir.';
  end if;

  if new_status is null or new_status not in ('approved', 'rejected') then
    raise exception 'Geçersiz personel durumu.';
  end if;

  if target_user_id is null or target_user_id = auth.uid() then
    raise exception 'Geçersiz personel hesabı.';
  end if;

  update public.profiles
  set approval_status = new_status,
      can_add_customers = case when new_status = 'rejected' then false else can_add_customers end
  where id = target_user_id
    and role = 'staff';

  if not found then
    raise exception 'Personel hesabı bulunamadı veya işlem yapılamaz.';
  end if;
end;
$$;

revoke all on function public.admin_set_staff_status(uuid, text) from public;
grant execute on function public.admin_set_staff_status(uuid, text) to authenticated;

-- 5) Admin, onaylı personele müşteri ekleme izni verebilir / kaldırabilir.
create or replace function public.admin_set_staff_customer_permission(
  target_user_id uuid,
  allow_customer_insert boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.nffes_is_admin() then
    raise exception 'Bu işlem yalnızca onaylı yönetici tarafından yapılabilir.';
  end if;

  update public.profiles
  set can_add_customers = allow_customer_insert
  where id = target_user_id
    and role = 'staff'
    and approval_status = 'approved';

  if not found then
    raise exception 'Onaylı personel hesabı bulunamadı.';
  end if;
end;
$$;

revoke all on function public.admin_set_staff_customer_permission(uuid, boolean) from public;
grant execute on function public.admin_set_staff_customer_permission(uuid, boolean) to authenticated;

-- 6) Müşteri ekleme yetkisi: admin veya izinli/onaylı personel.
create or replace function public.nffes_can_add_customers()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.nffes_is_admin() or exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'staff'
      and p.approval_status = 'approved'
      and p.can_add_customers = true
  );
$$;

-- Customers tablosunda başka isimli INSERT politikaları varsa da kaldır;
-- böylece eski permissive politikalar yeni yetki kuralını aşamaz.
do $$
declare policy_row record;
begin
  for policy_row in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'customers'
      and cmd = 'INSERT'
  loop
    execute format('drop policy if exists %I on public.customers', policy_row.policyname);
  end loop;
end;
$$;

create policy nffes_customers_insert_authorized
on public.customers for insert
to authenticated
with check (public.nffes_can_add_customers());

-- 7) Personeli ekipten kalıcı silme.
-- Önce profil kaydını, ardından Supabase Auth kullanıcısını siler.
-- Böylece aynı e-posta ile ileride yeniden kayıt yapılabilir.
-- Rezervasyon/müşteri/ödeme kayıtları topluca silinmez.
create or replace function public.admin_delete_staff(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.nffes_is_admin() then
    raise exception 'Bu işlem yalnızca onaylı yönetici tarafından yapılabilir.';
  end if;

  if target_user_id is null or target_user_id = auth.uid() then
    raise exception 'Kendi yönetici hesabınızı silemezsiniz.';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = target_user_id and role = 'staff'
  ) then
    raise exception 'Personel hesabı bulunamadı.';
  end if;

  delete from public.profiles
  where id = target_user_id and role = 'staff';

  delete from auth.users
  where id = target_user_id;

  if not found then
    raise exception 'Auth kullanıcı kaydı bulunamadı. İşlem geri alındı.';
  end if;
end;
$$;

revoke all on function public.admin_delete_staff(uuid) from public;
grant execute on function public.admin_delete_staff(uuid) to authenticated;

-- Mevcut admin hesabının role/approval_status değerleri değiştirilmez.

-- 8) Yalnızca onaylı kullanıcılar uygulama verilerine erişebilir.
create or replace function public.nffes_is_approved()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.approval_status = 'approved'
      and p.role in ('admin', 'staff')
  );
$$;

-- 9) Uygulama tablolarındaki eski RLS politikalarını değiştir; permissive
-- politikalar PostgreSQL'de OR ile birleştiği için eski erişimleri bırakmayız.
do $$
declare policy_row record;
begin
  for policy_row in
    select tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles', 'customers', 'packages', 'reservations', 'payments', 'expenses')
  loop
    execute format('drop policy if exists %I on public.%I', policy_row.policyname, policy_row.tablename);
  end loop;
end;
$$;

-- Profiles: kullanıcı kendi durumunu; admin ekip profil listesini görür.
create policy nffes_profiles_read_self
on public.profiles for select to authenticated
using (id = auth.uid());
create policy nffes_profiles_read_admin
on public.profiles for select to authenticated
using (public.nffes_is_admin());

-- Customers: onaylı personel okuyabilir; ekleme admin/izinli personele açıktır.
create policy nffes_customers_read_approved
on public.customers for select to authenticated
using (public.nffes_is_approved());
create policy nffes_customers_insert_authorized
on public.customers for insert to authenticated
with check (public.nffes_can_add_customers());
create policy nffes_customers_update_admin
on public.customers for update to authenticated
using (public.nffes_is_admin()) with check (public.nffes_is_admin());
create policy nffes_customers_delete_admin
on public.customers for delete to authenticated
using (public.nffes_is_admin());

-- Packages: onaylı ekip okuyabilir; içerik ve fiyatları admin yönetir.
create policy nffes_packages_read_approved
on public.packages for select to authenticated
using (public.nffes_is_approved());
create policy nffes_packages_insert_admin
on public.packages for insert to authenticated
with check (public.nffes_is_admin());
create policy nffes_packages_update_admin
on public.packages for update to authenticated
using (public.nffes_is_admin()) with check (public.nffes_is_admin());
create policy nffes_packages_delete_admin
on public.packages for delete to authenticated
using (public.nffes_is_admin());

-- Rezervasyon: onaylı ekip kayıt açabilir; düzenleme/silme admin yetkisindedir.
create policy nffes_reservations_read_approved
on public.reservations for select to authenticated
using (public.nffes_is_approved());
create policy nffes_reservations_insert_approved
on public.reservations for insert to authenticated
with check (public.nffes_is_approved() and (created_by is null or created_by = auth.uid()));
create policy nffes_reservations_update_admin
on public.reservations for update to authenticated
using (public.nffes_is_admin()) with check (public.nffes_is_admin());
create policy nffes_reservations_delete_admin
on public.reservations for delete to authenticated
using (public.nffes_is_admin());

-- Ödemeler ve giderler yalnızca admin tarafından görüntülenip yönetilir.
create policy nffes_payments_read_admin
on public.payments for select to authenticated
using (public.nffes_is_admin());
create policy nffes_payments_insert_admin
on public.payments for insert to authenticated
with check (public.nffes_is_admin() and (received_by is null or received_by = auth.uid()));
create policy nffes_payments_update_admin
on public.payments for update to authenticated
using (public.nffes_is_admin()) with check (public.nffes_is_admin());
create policy nffes_payments_delete_admin
on public.payments for delete to authenticated
using (public.nffes_is_admin());
create policy nffes_expenses_read_admin
on public.expenses for select to authenticated
using (public.nffes_is_admin());
create policy nffes_expenses_insert_admin
on public.expenses for insert to authenticated
with check (public.nffes_is_admin() and (created_by is null or created_by = auth.uid()));
create policy nffes_expenses_update_admin
on public.expenses for update to authenticated
using (public.nffes_is_admin()) with check (public.nffes_is_admin());
create policy nffes_expenses_delete_admin
on public.expenses for delete to authenticated
using (public.nffes_is_admin());

-- RLS'nin yanında tablo izinlerini de açık ve sınırlı tut.
revoke all on public.profiles, public.customers, public.packages,
  public.reservations, public.payments, public.expenses from public, anon;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.customers, public.packages,
  public.reservations, public.payments, public.expenses to authenticated;
revoke all on function public.nffes_is_admin() from public;
revoke all on function public.nffes_is_approved() from public;
revoke all on function public.nffes_can_add_customers() from public;
grant execute on function public.nffes_is_admin() to authenticated;
grant execute on function public.nffes_is_approved() to authenticated;
grant execute on function public.nffes_can_add_customers() to authenticated;
