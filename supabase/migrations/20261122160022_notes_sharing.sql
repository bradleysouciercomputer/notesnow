-- NotesNow note sharing
-- Applied to the NotesNow Supabase project as migration notes_sharing.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table if not exists public.note_shares (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.notes(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  shared_with_user_id uuid not null references auth.users(id) on delete cascade,
  shared_with_email text not null,
  permission text not null default 'viewer' check (permission in ('viewer', 'editor')),
  created_at timestamptz not null default now(),
  constraint note_shares_unique_recipient unique (note_id, shared_with_user_id),
  constraint note_shares_not_self check (owner_id <> shared_with_user_id)
);

alter table public.note_shares enable row level security;
grant select, insert, update, delete on public.note_shares to authenticated;

drop policy if exists "Users can view note shares they own or receive" on public.note_shares;
create policy "Users can view note shares they own or receive"
on public.note_shares for select to authenticated
using (owner_id = (select auth.uid()) or shared_with_user_id = (select auth.uid()));

drop policy if exists "Note owners can create shares" on public.note_shares;
create policy "Note owners can create shares"
on public.note_shares for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and shared_with_user_id <> (select auth.uid())
  and exists (
    select 1 from public.notes n
    where n.id = note_id and n.user_id = (select auth.uid())
  )
);

drop policy if exists "Note owners can update shares" on public.note_shares;
create policy "Note owners can update shares"
on public.note_shares for update to authenticated
using (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.notes n
    where n.id = note_id and n.user_id = (select auth.uid())
  )
)
with check (
  owner_id = (select auth.uid())
  and shared_with_user_id <> (select auth.uid())
  and exists (
    select 1 from public.notes n
    where n.id = note_id and n.user_id = (select auth.uid())
  )
);

drop policy if exists "Note owners can revoke shares" on public.note_shares;
create policy "Note owners can revoke shares"
on public.note_shares for delete to authenticated
using (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.notes n
    where n.id = note_id and n.user_id = (select auth.uid())
  )
);

create or replace function private.can_view_note(p_note_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and (
        n.user_id = (select auth.uid())
        or exists (
          select 1
          from public.note_shares s
          where s.note_id = n.id
            and s.shared_with_user_id = (select auth.uid())
        )
      )
  );
$$;

create or replace function private.can_edit_note(p_note_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.notes n
    where n.id = p_note_id
      and (
        n.user_id = (select auth.uid())
        or exists (
          select 1
          from public.note_shares s
          where s.note_id = n.id
            and s.shared_with_user_id = (select auth.uid())
            and s.permission = 'editor'
        )
      )
  );
$$;

revoke all on function private.can_view_note(uuid) from public;
revoke all on function private.can_edit_note(uuid) from public;
grant execute on function private.can_view_note(uuid) to authenticated;
grant execute on function private.can_edit_note(uuid) to authenticated;

drop policy if exists "Users can view their own notes" on public.notes;
drop policy if exists "Users can view owned or shared notes" on public.notes;
create policy "Users can view owned or shared notes"
on public.notes for select to authenticated
using (private.can_view_note(id));

drop policy if exists "Users can update their own notes" on public.notes;
drop policy if exists "Owners and editors can update notes" on public.notes;
create policy "Owners and editors can update notes"
on public.notes for update to authenticated
using (private.can_edit_note(id))
with check (private.can_edit_note(id));

revoke update on public.notes from authenticated;
grant update (title, content, attachments) on public.notes to authenticated;

drop policy if exists "Users can view attachments on their own notes" on storage.objects;
create policy "Users can view attachments on owned or shared notes"
on storage.objects for select to authenticated
using (
  bucket_id = 'note-attachments'
  and exists (
    select 1 from public.notes n
    where n.id::text = (storage.foldername(name))[2]
      and n.user_id::text = (storage.foldername(name))[1]
      and private.can_view_note(n.id)
  )
);

drop policy if exists "Users can upload attachments to their own notes" on storage.objects;
create policy "Owners and editors can upload attachments"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'note-attachments'
  and exists (
    select 1 from public.notes n
    where n.id::text = (storage.foldername(name))[2]
      and n.user_id::text = (storage.foldername(name))[1]
      and private.can_edit_note(n.id)
  )
);

drop policy if exists "Users can delete attachments from their own notes" on storage.objects;
create policy "Owners and editors can delete attachments"
on storage.objects for delete to authenticated
using (
  bucket_id = 'note-attachments'
  and exists (
    select 1 from public.notes n
    where n.id::text = (storage.foldername(name))[2]
      and n.user_id::text = (storage.foldername(name))[1]
      and private.can_edit_note(n.id)
  )
);

create or replace function public.lookup_user_id_by_email(p_email text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.id
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;
$$;

revoke all on function public.lookup_user_id_by_email(text) from public, anon, authenticated;
grant execute on function public.lookup_user_id_by_email(text) to service_role;
