CREATE TABLE IF NOT EXISTS app_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS nexo_users_device_idx ON users(device_id) WHERE device_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS nexo_app_sessions_user_idx ON app_sessions(user_id,expires_at);
CREATE TABLE IF NOT EXISTS gift_transactions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gift_id TEXT NOT NULL REFERENCES gifts(id),
  idempotency_key TEXT NOT NULL UNIQUE,
  source TEXT NOT NULL DEFAULT 'gems',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS signals (
  id UUID PRIMARY KEY,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  consumed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS nexo_signals_poll_idx ON signals(to_user_id,consumed_at,created_at);
INSERT INTO app_settings(key,value) VALUES
('trade.feePercent','5'::jsonb),
('economy.dailyFreeEnergy','50'::jsonb),
('economy.maxEnergy','100'::jsonb),
('economy.voicePerMinute','1'::jsonb),
('economy.videoPerMinute','4'::jsonb)
ON CONFLICT(key) DO NOTHING;