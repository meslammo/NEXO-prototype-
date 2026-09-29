CREATE TABLE IF NOT EXISTS nexo.app_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL
);
ALTER TABLE nexo.users ADD COLUMN IF NOT EXISTS device_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS nexo_users_device_idx ON nexo.users(device_id) WHERE device_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS nexo_app_sessions_user_idx ON nexo.app_sessions(user_id,expires_at);
CREATE TABLE IF NOT EXISTS nexo.gift_transactions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  gift_id TEXT NOT NULL REFERENCES nexo.gifts(id),
  idempotency_key TEXT NOT NULL UNIQUE,
  source TEXT NOT NULL DEFAULT 'gems',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.signals (
  id UUID PRIMARY KEY,
  to_user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  consumed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS nexo_signals_poll_idx ON nexo.signals(to_user_id,consumed_at,created_at);
INSERT INTO nexo.app_settings(key,value) VALUES
('trade.feePercent','5'::jsonb),
('economy.dailyFreeEnergy','50'::jsonb),
('economy.maxEnergy','100'::jsonb),
('economy.voicePerMinute','1'::jsonb),
('economy.videoPerMinute','4'::jsonb)
ON CONFLICT(key) DO NOTHING;