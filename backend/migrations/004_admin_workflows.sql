ALTER TABLE users
  ADD COLUMN IF NOT EXISTS account_status text NOT NULL DEFAULT 'active';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'users_account_status_check'
       AND conrelid = 'users'::regclass
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_account_status_check
      CHECK (account_status IN ('active', 'suspended'));
  END IF;
END
$$;

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS moderation_note text,
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;

CREATE INDEX IF NOT EXISTS users_account_status_created_idx
  ON users (account_status, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS listings_status_updated_idx
  ON listings (status, updated_at DESC);

CREATE INDEX IF NOT EXISTS vet_appointments_status_created_idx
  ON vet_appointments (status, created_at DESC);

CREATE INDEX IF NOT EXISTS orders_status_created_idx
  ON orders (status, created_at DESC);

CREATE INDEX IF NOT EXISTS disputes_status_created_id_idx
  ON disputes (status, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS reviews_created_id_idx
  ON reviews (created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS notifications_created_id_idx
  ON notifications (created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS audit_events_created_id_idx
  ON audit_events (created_at DESC, id DESC);
