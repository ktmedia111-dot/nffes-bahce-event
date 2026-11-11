-- N'fess Bahçe: personel kayıt/onay ve ekip yönetimi güncellemesi
-- Supabase SQL Editor'de bir kez çalıştırın. Mevcut admin profiline dokunmaz.

-- 1) Yeni Auth kayıtları otomatik olarak bekleyen personel profili alır.
create or replace function public.nffes_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles as current_profile (id, full_name, role, approval_status, can_add_customers)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'staff',
    'pending',
    false
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        role = case when current_profile.role = 'admin' then 'admin' else 'staff' end,
        approval_status = case when current_profile.role = 'admin' then current_profile.approval_status else 'pending' end,
        can_add_customers = case when current_profile.role = 'admin' then current_profile.can_add_customers else false end;
  return new;
end;
$$;

drop trigger if exists nffes_on_auth_user_created on auth.users;
drop trigger if exists zz_nffes_on_auth_user_created on auth.users;
create trigger zz_nffes_on_auth_user_created
after insert on auth.users
for each row execute procedure public.nffes_handle_new_user();

-- 2) Admin kontrolü: profiles tablosunda kendi satırını okuyarak sonsuz RLS döngüsü oluşturmaz.
create or replace function public.nffes_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
      and p.approval_status = 'approved'
  );
$$;

-- 3) Personel kendi profilini; admin ise tüm ekip profillerini görebilir.
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

-- 4) Admin sadece personel onay durumunu değiştirebilen RPC kullanır.
-- Kullanıcı rolü ve admin hesabı bu fonksiyonla değiştirilemez.
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

  if new_status not in ('approved', 'rejected') then
    raise exception 'Geçersiz personel durumu.';
  end if;

  update public.profiles
  set approval_status = new_status
  where id = target_user_id
    and role = 'staff';

  if not found then
    raise exception 'Personel hesabı bulunamadı veya işlem yapılamaz.';
  end if;
end;
$$;

revoke all on function public.admin_set_staff_status(uuid, text) from public;
grant execute on function public.admin_set_staff_status(uuid, text) to authenticated;

-- Mevcut admin hesabının role/approval_status değerleri değiştirilmez.

-- 5) Yönetici, onaylı personele ayrıca müşteri ekleme izni verebilir.
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

-- 6) Müşteri ekleme RLS: admin veya adminin ayrıca izin verdiği onaylı personel.
create or replace function public.nffes_can_add_customers()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.nffes_is_admin() or exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'staff'
      and p.approval_status = 'approved'
      and p.can_add_customers = true
  );
$$;

drop policy if exists customers_insert on public.customers;
drop policy if exists nffes_customers_insert_authorized on public.customers;
create policy nffes_customers_insert_authorized
on public.customers for insert
to authenticated
with check (public.nffes_can_add_customers());
