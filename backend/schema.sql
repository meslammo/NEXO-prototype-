CREATE SCHEMA IF NOT EXISTS nexo;
CREATE TABLE IF NOT EXISTS nexo.users (
  id UUID PRIMARY KEY, username TEXT NOT NULL UNIQUE, email TEXT UNIQUE, password_hash TEXT,
  display_name TEXT NOT NULL, avatar TEXT NOT NULL DEFAULT '001.jpg',
  gems BIGINT NOT NULL DEFAULT 1000 CHECK (gems >= 0), energy INT NOT NULL DEFAULT 50 CHECK (energy BETWEEN 0 AND 100),
  level INT NOT NULL DEFAULT 1, experience BIGINT NOT NULL DEFAULT 0, reputation INT NOT NULL DEFAULT 0,
  vip_level TEXT NOT NULL DEFAULT 'Base', name_color TEXT NOT NULL DEFAULT '#54d6ff', glow BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), last_active TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.gifts (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, rarity TEXT NOT NULL, gems INT NOT NULL CHECK (gems > 0),
  tradeable BOOLEAN NOT NULL DEFAULT TRUE, image TEXT NOT NULL, tagline TEXT NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS nexo.inventory (
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES nexo.gifts(id), quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  PRIMARY KEY (user_id,item_id)
);
CREATE TABLE IF NOT EXISTS nexo.wallet_ledger (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL, amount BIGINT NOT NULL, balance_after BIGINT NOT NULL, reference_id TEXT,
  idempotency_key TEXT UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.energy_ledger (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL, amount INT NOT NULL, balance_after INT NOT NULL, reference_id TEXT,
  idempotency_key TEXT UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.messages (
  id UUID PRIMARY KEY, sender_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE, kind TEXT NOT NULL DEFAULT 'text',
  body TEXT, gift_id TEXT REFERENCES nexo.gifts(id), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_messages_pair_idx ON nexo.messages(sender_id,recipient_id,created_at DESC);
CREATE TABLE IF NOT EXISTS nexo.trades (
  id UUID PRIMARY KEY, from_user_id UUID NOT NULL REFERENCES nexo.users(id), to_user_id UUID NOT NULL REFERENCES nexo.users(id),
  status TEXT NOT NULL DEFAULT 'locked', from_items JSONB NOT NULL DEFAULT '[]', to_items JSONB NOT NULL DEFAULT '[]',
  from_gems BIGINT NOT NULL DEFAULT 0 CHECK (from_gems >= 0), to_gems BIGINT NOT NULL DEFAULT 0 CHECK (to_gems >= 0),
  fee_gems BIGINT NOT NULL DEFAULT 0 CHECK (fee_gems >= 0), from_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
  to_confirmed BOOLEAN NOT NULL DEFAULT FALSE, dispute_reason TEXT, resolution TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), expires_at TIMESTAMPTZ NOT NULL
);
CREATE TABLE IF NOT EXISTS nexo.notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_notifications_user_idx ON nexo.notifications(user_id,read,created_at DESC);

CREATE TABLE IF NOT EXISTS nexo.game_rooms (
  id UUID PRIMARY KEY,
  game_id TEXT NOT NULL,
  host_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  guest_id UUID REFERENCES nexo.users(id) ON DELETE SET NULL,
  host_ready BOOLEAN NOT NULL DEFAULT FALSE,
  guest_ready BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'waiting',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_game_rooms_waiting_idx ON nexo.game_rooms(game_id,status,created_at);

CREATE TABLE IF NOT EXISTS nexo.game_room_scores (
  room_id UUID NOT NULL REFERENCES nexo.game_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  score INT NOT NULL CHECK (score >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id,user_id)
);

CREATE TABLE IF NOT EXISTS nexo.payment_orders (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  package_id TEXT NOT NULL, gems BIGINT NOT NULL, amount_minor BIGINT NOT NULL, currency TEXT NOT NULL,
  provider TEXT NOT NULL, provider_transaction_id TEXT UNIQUE, status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), completed_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS nexo.payment_orders (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  package_id TEXT NOT NULL, gems BIGINT NOT NULL, amount_minor BIGINT NOT NULL, currency TEXT NOT NULL,
  provider TEXT NOT NULL, provider_transaction_id TEXT UNIQUE, status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), completed_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS nexo.purchase_tokens (
  purchase_token TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  order_id UUID NOT NULL REFERENCES nexo.payment_orders(id) ON DELETE CASCADE,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS nexo.presence (
  user_id UUID PRIMARY KEY REFERENCES nexo.users(id) ON DELETE CASCADE,
  online BOOLEAN NOT NULL DEFAULT FALSE, last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.daily_claims (
  user_id UUID PRIMARY KEY REFERENCES nexo.users(id) ON DELETE CASCADE,
  claim_date DATE NOT NULL,
  streak INT NOT NULL DEFAULT 1 CHECK (streak >= 1)
);
CREATE TABLE IF NOT EXISTS nexo.game_events (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  game_id TEXT NOT NULL, cost_energy INT NOT NULL, reward_gems INT NOT NULL,
  idempotency_key TEXT UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.treasury_ledger (
  id UUID PRIMARY KEY, trade_id UUID, kind TEXT NOT NULL, amount BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.trade_locks (
  trade_id UUID NOT NULL REFERENCES nexo.trades(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES nexo.gifts(id),
  quantity INT NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (trade_id,user_id,item_id)
);

INSERT INTO nexo.users(id,username,email,password_hash,display_name,avatar,gems,energy) VALUES
('00000000-0000-0000-0000-000000000101','shadoww',NULL,NULL,'Shadoww','002.jpg',1000,50),
('00000000-0000-0000-0000-000000000102','galaxygirl',NULL,NULL,'GalaxyGirl','003.jpg',1000,50),
('00000000-0000-0000-0000-000000000103','prince',NULL,NULL,'Prince_X','004.jpg',1000,50),
('00000000-0000-0000-0000-000000000104','ahmed',NULL,NULL,'Ahmed','005.jpg',1000,50),
('00000000-0000-0000-0000-000000000105','mdark',NULL,NULL,'M:Dark','006.jpg',1000,50)
ON CONFLICT (username) DO NOTHING;

INSERT INTO nexo.gifts(id,name,rarity,gems,tradeable,image,tagline) VALUES
('neon-heart','Neon Heart','Common',15,true,'neon_heart.png','نبضة نيون لطيفة للشات'),
('shadow-flame','Shadow Flame','Rare',80,true,'shadow_flame.png','لهب مظلم للغرف الليلية'),
('name-glow','Name Glow','Rare',120,true,'name_glow_ticket.png','وهج مميز للاسم'),
('diamond-glow','Diamond Glow','Epic',220,true,'diamond_glow.png','لمعة ماسية عند الإرسال'),
('galaxy-aura','Galaxy Aura','Epic',280,true,'galaxy_aura.png','هالة مجرية حول الرسالة'),
('rainbow-aura','Rainbow Aura','Epic',350,true,'rainbow_ticket.png','أثر طيفي مميز'),
('fire-wings','Fire Wings','Legendary',650,true,'fire_wings.png','دخول ناري قوي'),
('crown-shine','Crown Shine','Legendary',900,true,'crown_shine.png','تاج لامع للغرف'),
('vip-emblem','VIP Emblem','NEXO Exclusive',1800,false,'vip_emblem.png','شارة NEXO حصرية')
ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name,rarity=EXCLUDED.rarity,gems=EXCLUDED.gems,tradeable=EXCLUDED.tradeable,image=EXCLUDED.image,tagline=EXCLUDED.tagline;
