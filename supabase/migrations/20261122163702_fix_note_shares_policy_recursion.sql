-- Prevent recursive RLS checks between public.notes and public.note_shares.
-- Share-management policies call this SECURITY DEFINER helper instead of
-- querying public.notes under its SELECT policy.

create or replace function private.is_current_user_note_owner(p_note_id uuid)
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
      and n.user_id = (select auth.uid())
  );
$$;

revoke all on function private.is_current_user_note_owner(uuid) from public;
grant execute on function private.is_current_user_note_owner(uuid) to authenticated;

drop policy if exists "Note owners can create shares" on public.note_shares;
create policy "Note owners can create shares"
on public.note_shares
for insert
to authenticated
with check (
  owner_id = (select auth.uid())
  and shared_with_user_id <> (select auth.uid())
  and private.is_current_user_note_owner(note_id)
);

drop policy if exists "Note owners can update shares" on public.note_shares;
create policy "Note owners can update shares"
on public.note_shares
for update
to authenticated
using (
  owner_id = (select auth.uid())
  and private.is_current_user_note_owner(note_id)
)
with check (
  owner_id = (select auth.uid())
  and shared_with_user_id <> (select auth.uid())
  and private.is_current_user_note_owner(note_id)
);

drop policy if exists "Note owners can revoke shares" on public.note_shares;
create policy "Note owners can revoke shares"
on public.note_shares
for delete
to authenticated
using (
  owner_id = (select auth.uid())
  and private.is_current_user_note_owner(note_id)
);
