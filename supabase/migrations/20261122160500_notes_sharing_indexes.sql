-- Cover foreign-key lookups on the note_shares table.
create index if not exists note_shares_owner_id_idx
  on public.note_shares (owner_id);

create index if not exists note_shares_shared_with_user_id_idx
  on public.note_shares (shared_with_user_id);
