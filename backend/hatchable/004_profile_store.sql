-- NEXO CHANGE 27: live profile ecosystem and SoulChill-inspired store catalog
-- Mirror of Hatchable migrations/004_profile_store.sql.

CREATE TABLE IF NOT EXISTS profile_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  wealth_score BIGINT NOT NULL DEFAULT 0,
  charm_score BIGINT NOT NULL DEFAULT 0,
  points_bank BIGINT NOT NULL DEFAULT 0,
  svip_level INT NOT NULL DEFAULT 0,
  aristocracy_level INT NOT NULL DEFAULT 0,
  couple_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  room_background_id TEXT REFERENCES gifts(id) ON DELETE SET NULL,
  entrance_effect_id TEXT REFERENCES gifts(id) ON DELETE SET NULL,
  bio TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moments (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS connections (
  follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id,following_id)
);

CREATE TABLE IF NOT EXISTS points_bank_claims (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_date DATE NOT NULL,
  points INT NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(user_id,claim_date)
);
