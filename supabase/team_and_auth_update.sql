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
