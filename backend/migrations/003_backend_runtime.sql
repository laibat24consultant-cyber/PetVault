ALTER TABLE users
  ADD COLUMN IF NOT EXISTS failed_login_attempts integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS locked_until timestamptz,
  ADD COLUMN IF NOT EXISTS token_version integer NOT NULL DEFAULT 0;

ALTER TABLE order_items
  ADD COLUMN IF NOT EXISTS vendor_status text NOT NULL DEFAULT 'Processing'
  CHECK (vendor_status IN ('Processing', 'Shipped', 'Delivered'));

CREATE UNIQUE INDEX IF NOT EXISTS users_active_email_lower_unique
  ON users (lower(email))
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS users_active_phone_unique
  ON users (phone)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS listing_reports_one_open_per_user_idx
  ON listing_reports (listing_id, reporter_id)
  WHERE status = 'open';

CREATE UNIQUE INDEX IF NOT EXISTS reviews_one_per_author_subject_idx
  ON reviews (author_id, subject_type, subject_id);

CREATE TABLE IF NOT EXISTS listing_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL UNIQUE REFERENCES listings(id) ON DELETE RESTRICT,
  buyer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  seller_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  commission_amount numeric(12, 2) NOT NULL DEFAULT 0
    CHECK (commission_amount >= 0),
  status text NOT NULL DEFAULT 'initiated'
    CHECK (status IN (
      'initiated', 'held', 'handover_pending', 'released',
      'disputed', 'refunded', 'cancelled'
    )),
  provider_reference text,
  handover_confirmed_at timestamptz,
  auto_release_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS listing_transactions_buyer_idx
  ON listing_transactions (buyer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS listing_transactions_seller_idx
  ON listing_transactions (seller_id, created_at DESC);

CREATE TABLE IF NOT EXISTS disputes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opened_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  target_type text NOT NULL
    CHECK (target_type IN ('listing_transaction', 'order', 'booking', 'appointment')),
  target_id uuid NOT NULL,
  reason text NOT NULL CHECK (length(reason) BETWEEN 1 AND 2000),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_review', 'resolved', 'dismissed')),
  resolution text,
  resolved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);
CREATE INDEX IF NOT EXISTS disputes_status_created_idx
  ON disputes (status, created_at DESC);

CREATE TABLE IF NOT EXISTS sitter_check_ins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES sitter_bookings(id) ON DELETE CASCADE,
  sitter_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  note text NOT NULL CHECK (length(note) BETWEEN 1 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sitter_check_ins_booking_idx
  ON sitter_check_ins (booking_id, created_at DESC);

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category text NOT NULL
    CHECK (category IN ('care', 'messages', 'marketplace', 'orders')),
  enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, category)
);

CREATE TABLE IF NOT EXISTS listing_search_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  species text,
  breed text,
  city text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS listing_search_events_user_idx
  ON listing_search_events (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(name) BETWEEN 1 AND 120),
  price numeric(12, 2) NOT NULL CHECK (price > 0),
  stock integer NOT NULL CHECK (stock >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_id, name)
);
