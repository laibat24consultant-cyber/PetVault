<<<<<<< HEAD
CREATE TABLE IF NOT EXISTS visit_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  buyer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  scheduled_at timestamptz NOT NULL,
  message text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'requested'
    CHECK (status IN ('requested', 'confirmed', 'declined', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (length(message) <= 2000)
);

CREATE INDEX IF NOT EXISTS visit_requests_buyer_idx
  ON visit_requests (buyer_id, scheduled_at DESC);
CREATE INDEX IF NOT EXISTS visit_requests_listing_idx
  ON visit_requests (listing_id, status, scheduled_at);
=======
CREATE TABLE IF NOT EXISTS visit_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  buyer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  scheduled_at timestamptz NOT NULL,
  message text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'requested'
    CHECK (status IN ('requested', 'confirmed', 'declined', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (length(message) <= 2000)
);

CREATE INDEX IF NOT EXISTS visit_requests_buyer_idx
  ON visit_requests (buyer_id, scheduled_at DESC);
CREATE INDEX IF NOT EXISTS visit_requests_listing_idx
  ON visit_requests (listing_id, status, scheduled_at);
>>>>>>> 24ecb6467fbec18fd7e609611217a71dd686272b
