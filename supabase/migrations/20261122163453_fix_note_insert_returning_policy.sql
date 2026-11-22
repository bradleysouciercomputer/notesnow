-- Avoid querying public.notes again from its own SELECT policy.
-- This is important for INSERT ... RETURNING: the just-inserted row is not
-- visible to a second query from inside a policy helper during that statement.

drop policy if exists "Users can view owned or shared notes" on public.notes;

create policy "Users can view owned or shared notes"
on public.notes
for select
to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.note_shares s
    where s.note_id = notes.id
      and s.shared_with_user_id = (select auth.uid())
  )
);
