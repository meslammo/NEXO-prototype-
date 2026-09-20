CREATE SCHEMA IF NOT EXISTS nexo;
CREATE TABLE IF NOT EXISTS nexo.users (
  id UUID PRIMARY KEY, username TEXT NOT NULL UNIQUE, email TEXT UNIQUE, password_hash TEXT,
  display_name TEXT NOT NULL, avatar TEXT NOT NULL DEFAULT '001.jpg',
  gems BIGINT NOT NULL DEFAULT 1000 CHECK (gems >= 0), energy INT NOT NULL DEFAULT 50 CHECK (energy BETWEEN 0 AND 100),
  level INT NOT NULL DEFAULT 1, experience BIGINT NOT NULL DEFAULT 0, reputation INT NOT NULL DEFAULT 0,
  vip_level TEXT NOT NULL DEFAULT 'Base', name_color TEXT NOT NULL DEFAULT '#54d6ff', glow BOOLEAN NOT NULL DEFAULT TRUE,
  role TEXT NOT NULL DEFAULT 'user', banned BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), last_active TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE nexo.users ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';
ALTER TABLE nexo.users ADD COLUMN IF NOT EXISTS banned BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS nexo_users_role_idx ON nexo.users(role,banned);

CREATE TABLE IF NOT EXISTS nexo.gifts (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, rarity TEXT NOT NULL, gems INT NOT NULL CHECK (gems >= 0),
  tradeable BOOLEAN NOT NULL DEFAULT TRUE, image TEXT NOT NULL, tagline TEXT NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
  item_type TEXT NOT NULL DEFAULT 'gift', category TEXT NOT NULL DEFAULT 'gifts',
  description TEXT NOT NULL DEFAULT '', animation TEXT NOT NULL DEFAULT 'pulse',
  market_visible BOOLEAN NOT NULL DEFAULT TRUE, sort_order INT NOT NULL DEFAULT 0,
  tags JSONB NOT NULL DEFAULT '[]'::jsonb, metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS item_type TEXT NOT NULL DEFAULT 'gift';
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'gifts';
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS animation TEXT NOT NULL DEFAULT 'pulse';
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS market_visible BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0;
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE nexo.gifts ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
CREATE INDEX IF NOT EXISTS nexo_gifts_market_idx ON nexo.gifts(active,market_visible,item_type,sort_order,gems);

CREATE TABLE IF NOT EXISTS nexo.inventory (
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES nexo.gifts(id), quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  PRIMARY KEY (user_id,item_id)
);
CREATE TABLE IF NOT EXISTS nexo.user_equipped (
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  slot TEXT NOT NULL, item_id TEXT REFERENCES nexo.gifts(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), PRIMARY KEY (user_id,slot)
);
CREATE INDEX IF NOT EXISTS nexo_user_equipped_item_idx ON nexo.user_equipped(item_id);

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
CREATE TABLE IF NOT EXISTS nexo.security_events (
  id UUID PRIMARY KEY, user_id UUID REFERENCES nexo.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL, severity TEXT NOT NULL DEFAULT 'info', ip TEXT,
  details JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_security_events_user_idx ON nexo.security_events(user_id,created_at DESC);
CREATE TABLE IF NOT EXISTS nexo.notifications (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb, read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_notifications_user_idx ON nexo.notifications(user_id,read,created_at DESC);

CREATE TABLE IF NOT EXISTS nexo.game_rooms (
  id UUID PRIMARY KEY, game_id TEXT NOT NULL, host_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  guest_id UUID REFERENCES nexo.users(id) ON DELETE SET NULL, host_ready BOOLEAN NOT NULL DEFAULT FALSE,
  guest_ready BOOLEAN NOT NULL DEFAULT FALSE, status TEXT NOT NULL DEFAULT 'waiting',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_game_rooms_waiting_idx ON nexo.game_rooms(game_id,status,created_at);
CREATE TABLE IF NOT EXISTS nexo.game_room_scores (
  room_id UUID NOT NULL REFERENCES nexo.game_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  score INT NOT NULL CHECK (score >= 0), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id,user_id)
);

CREATE TABLE IF NOT EXISTS nexo.payment_orders (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  package_id TEXT NOT NULL, gems BIGINT NOT NULL, amount_minor BIGINT NOT NULL, currency TEXT NOT NULL,
  provider TEXT NOT NULL, provider_transaction_id TEXT UNIQUE, status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), completed_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS nexo.purchase_tokens (
  purchase_token TEXT PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL, order_id UUID NOT NULL REFERENCES nexo.payment_orders(id) ON DELETE CASCADE,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.presence (
  user_id UUID PRIMARY KEY REFERENCES nexo.users(id) ON DELETE CASCADE,
  online BOOLEAN NOT NULL DEFAULT FALSE, last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.daily_claims (
  user_id UUID PRIMARY KEY REFERENCES nexo.users(id) ON DELETE CASCADE,
  claim_date DATE NOT NULL, streak INT NOT NULL DEFAULT 1 CHECK (streak >= 1)
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
  item_id TEXT NOT NULL REFERENCES nexo.gifts(id), quantity INT NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (trade_id,user_id,item_id)
);
CREATE TABLE IF NOT EXISTS nexo.admin_actions (
  id UUID PRIMARY KEY, admin_subject TEXT NOT NULL, action TEXT NOT NULL,
  target_id TEXT, details JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS nexo.device_tokens (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES nexo.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL, token TEXT NOT NULL UNIQUE, active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nexo_device_tokens_user_idx ON nexo.device_tokens(user_id,active);
CREATE TABLE IF NOT EXISTS nexo.app_settings (
  key TEXT PRIMARY KEY, value JSONB NOT NULL DEFAULT '{}'::jsonb, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO nexo.users(id,username,email,password_hash,display_name,avatar,gems,energy) VALUES
('00000000-0000-0000-0000-000000000101','shadoww',NULL,NULL,'Shadoww','002.jpg',1000,50),
('00000000-0000-0000-0000-000000000102','galaxygirl',NULL,NULL,'GalaxyGirl','003.jpg',1000,50),
('00000000-0000-0000-0000-000000000103','prince',NULL,NULL,'Prince_X','004.jpg',1000,50),
('00000000-0000-0000-0000-000000000104','ahmed',NULL,NULL,'Ahmed','005.jpg',1000,50),
('00000000-0000-0000-0000-000000000105','mdark',NULL,NULL,'M:Dark','006.jpg',1000,50)
ON CONFLICT (username) DO NOTHING;

INSERT INTO nexo.gifts(id,name,rarity,gems,tradeable,image,tagline,item_type,category,description,animation,market_visible,sort_order) VALUES
('neon-heart','Neon Heart','Common',15,true,'neon_heart.png','نبضة نيون لطيفة للشات','gift','gifts','هدية نيون سريعة للإرسال في الشات.','pulse',true,10),
('shadow-flame','Shadow Flame','Rare',80,true,'shadow_flame.png','لهب مظلم للغرف الليلية','gift','gifts','لهب غامض مع أثر مضيء.','float',true,11),
('name-glow','Name Glow','Rare',120,true,'name_glow_ticket.png','وهج مميز للاسم','gift','identity','تأثير اسم قابل للاستخدام في الهوية والشات.','shine',true,12),
('diamond-glow','Diamond Glow','Epic',220,true,'diamond_glow.png','لمعة ماسية عند الإرسال','gift','gifts','هدية ماسية بتأثير لمعان.','shine',true,13),
('galaxy-aura','Galaxy Aura','Epic',280,true,'galaxy_aura.png','هالة مجرية حول الرسالة','gift','effects','هالة فضائية تظهر حول الرسالة والصورة.','orbit',true,14),
('rainbow-aura','Rainbow Aura','Epic',350,true,'rainbow_ticket.png','أثر طيفي مميز','gift','effects','طيف لوني نابض.','rainbow',true,15),
('fire-wings','Fire Wings','Legendary',650,true,'fire_wings.png','دخول ناري قوي','gift','gifts','أجنحة نارية بهالة قوية.','float',true,16),
('crown-shine','Crown Shine','Legendary',900,true,'crown_shine.png','تاج لامع للغرف','gift','gifts','تاج ملكي متوهج.','shine',true,17),
('vip-emblem','VIP Emblem','NEXO Exclusive',1800,false,'vip_emblem.png','شارة NEXO حصرية','gift','vip','شارة خاصة غير قابلة للتداول.','pulse',true,18),
('dragon','Dragon','Legendary',12000,true,'assets/nexo/gifts/dragon.svg','تنين NEXO الأسطوري','gift','legendary','تنين طاقة بوهج ناري.','float',true,20),
('unicorn','Unicorn','Legendary',9000,true,'assets/nexo/gifts/unicorn.svg','اليونيكورن المتوهج','gift','legendary','يونيكورن سماوي بتدرجات مضيئة.','shine',true,21),
('phoenix','Phoenix','Legendary',15000,true,'assets/nexo/gifts/phoenix.svg','بعث الفينيكس','gift','legendary','طائر العنقاء بنبض ناري.','float',true,22),
('nexo-car','NEXO Car','Epic',3500,true,'assets/nexo/gifts/nexo-car.svg','السيارة النيون','gift','vehicles','سيارة NEXO الرياضية.','pulse',true,23),
('al-hurra','Al-Hurra','NEXO Exclusive',75000,false,'assets/nexo/gifts/al-hurra.svg','الحُرّة','gift','exclusive','رمز حرية حصري.','orbit',true,24),
('purity','Purity','Epic',1800,true,'assets/nexo/gifts/purity.svg','النقاء','gift','gifts','قطرة نقاء مضيئة.','shine',true,25),
('moon-wolf','Moon Wolf','Epic',2400,true,'assets/nexo/gifts/moon-wolf.svg','ذئب القمر','gift','gifts','ذئب سماوي بتأثير قمري.','pulse',true,26),
('crystal-rose','Crystal Rose','Rare',450,true,'assets/nexo/gifts/crystal-rose.svg','وردة كريستالية','gift','gifts','وردة بلورية ملونة.','shine',true,27),
('thunder-core','Thunder Core','Rare',700,true,'assets/nexo/gifts/thunder-core.svg','قلب البرق','gift','effects','نواة برق بنبض سريع.','pulse',true,28),
('royal-chest','Royal Chest','Legendary',6000,true,'assets/nexo/gifts/royal-chest.svg','الصندوق الملكي','gift','featured','صندوق جوائز ذهبي.','shine',true,29),
('ocean-serpent','Ocean Serpent','Epic',3200,true,'assets/nexo/gifts/ocean-serpent.svg','ثعبان المحيط','gift','gifts','ثعبان مائي طيفي.','float',true,30),
('cosmic-orb','Cosmic Orb','Rare',550,true,'assets/nexo/gifts/cosmic-orb.svg','الكرة الكونية','gift','effects','طاقة كونية دورانية.','orbit',true,31),

('frame-cyan','Cyan Orbit Frame','Rare',900,true,'assets/nexo/frames/cyan-orbit.svg','إطار مدار سماوي','frame','frames','إطار دائري أزرق متوهج.','orbit',true,100),
('frame-violet','Violet Pulse Frame','Epic',1800,true,'assets/nexo/frames/violet-pulse.svg','نبض بنفسجي','frame','frames','إطار نبضي بنفسجي.','pulse',true,101),
('frame-royal','Royal Gold Frame','Legendary',4200,true,'assets/nexo/frames/royal-gold.svg','إطار ذهبي ملكي','frame','frames','حلقة ذهبية للـProfile.','shine',true,102),
('frame-fire','Inferno Frame','Legendary',6000,true,'assets/nexo/frames/fire-ring.svg','حلقة نارية','frame','frames','إطار ناري قوي.','orbit',true,103),
('frame-galaxy','Galaxy Ring Frame','Epic',3000,true,'assets/nexo/frames/galaxy-ring.svg','مدار مجري','frame','frames','إطار فضائي متحرك.','orbit',true,104),
('frame-exclusive','NEXO Exclusive Frame','NEXO Exclusive',55000,false,'assets/nexo/frames/nexo-exclusive.svg','إطار حصري','frame','frames','إطار محدود.','shine',true,105),
('asset-cosmic','Cosmic Aura Asset','Epic',1200,true,'assets/nexo/assets/cosmic-aura.svg','هالة كونية','asset','assets','هالة خلفية للهوية.','orbit',true,120),
('asset-inferno','Inferno Wings Asset','Legendary',4500,true,'assets/nexo/assets/inferno-wings.svg','أجنحة لهب','asset','assets','أجنحة هوية متوهجة.','float',true,121),
('asset-halo','Royal Halo Asset','Legendary',5200,true,'assets/nexo/assets/royal-halo.svg','الهالة الملكية','asset','assets','هالة حول الصورة.','shine',true,122),
('asset-shield','NEXO Shield Asset','Rare',800,true,'assets/nexo/assets/nexo-shield.svg','درع NEXO','asset','assets','رمز حماية للهوية.','pulse',true,123),
('asset-comet','Star Comet Asset','Epic',2200,true,'assets/nexo/assets/star-comet.svg','ذيل نجمي','asset','assets','مؤثر سريع.','float',true,124),
('asset-prism','Prism Burst Asset','NEXO Exclusive',28000,false,'assets/nexo/assets/prism-burst.svg','انفجار طيفي','asset','assets','أصل بصري حصري.','rainbow',true,125),
('emoji-laugh','Laugh Burst','Common',25,true,'assets/nexo/emoji/laugh.svg','ضحكة نيون','emoji','emoji','إيموجي متحرك.','pulse',true,140),
('emoji-fire','Fire Emoji','Rare',60,true,'assets/nexo/emoji/fire.svg','لهب سريع','emoji','emoji','إيموجي لهب.','float',true,141),
('emoji-heart','Purple Heart','Common',30,true,'assets/nexo/emoji/purple-heart.svg','قلب بنفسجي','emoji','emoji','إيموجي قلب.','pulse',true,142),
('emoji-crown','Crown Emoji','Rare',75,true,'assets/nexo/emoji/crown.svg','تاج لامع','emoji','emoji','إيموجي تاج.','shine',true,143),
('emoji-wow','Wow Emoji','Epic',120,true,'assets/nexo/emoji/wow.svg','دهشة','emoji','emoji','إيموجي دهشة.','pulse',true,144),
('emoji-love','Love Emoji','Rare',90,true,'assets/nexo/emoji/love.svg','حب','emoji','emoji','إيموجي حب.','shine',true,145),
('emoji-rocket','Rocket Emoji','Epic',150,true,'assets/nexo/emoji/rocket.svg','انطلق','emoji','emoji','إيموجي صاروخ.','float',true,146),
('emoji-snow','Snow Emoji','Rare',65,true,'assets/nexo/emoji/snow.svg','ثلج نيون','emoji','emoji','إيموجي ثلجي.','orbit',true,147),
('crafted-shadow-mask','Shadow Mask','Epic',1,true,'assets/nexo/crafted/shadow-mask.svg','مصنوع بالـWorkshop','crafted','crafted','قطعة تصنيع.','pulse',false,200),
('crafted-phoenix-seal','Phoenix Seal','Legendary',1,true,'assets/nexo/crafted/phoenix-seal.svg','ختم الفينيكس','crafted','crafted','قطعة تصنيع نادرة.','shine',false,201),
('crafted-prism-token','Prism Token','Rare',1,true,'assets/nexo/crafted/prism-token.svg','توكن طيفي','crafted','crafted','قطعة مصنعة.','rainbow',false,202),
('crafted-nebula-core','Nebula Core','Epic',1,true,'assets/nexo/crafted/nebula-core.svg','نواة سديم','crafted','crafted','نواة مصنعة.','orbit',false,203),
('crafted-golden-signet','Golden Signet','Legendary',1,true,'assets/nexo/crafted/golden-signet.svg','خاتم ذهبي مصنوع','crafted','crafted','ختم ملكي مصنوع.','shine',false,204),
('crafted-arcana','NEXO Arcana','NEXO Exclusive',1,false,'assets/nexo/crafted/nexo-arcana.svg','أركانا NEXO','crafted','crafted','قطعة تصنيع حصرية.','orbit',false,205)
ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name,rarity=EXCLUDED.rarity,gems=EXCLUDED.gems,tradeable=EXCLUDED.tradeable,image=EXCLUDED.image,
  tagline=EXCLUDED.tagline,item_type=EXCLUDED.item_type,category=EXCLUDED.category,description=EXCLUDED.description,
  animation=EXCLUDED.animation,market_visible=EXCLUDED.market_visible,sort_order=EXCLUDED.sort_order;

UPDATE nexo.gifts SET description=COALESCE(NULLIF(description,''),tagline) WHERE description='';

-- NEXO catalog seed: populate the production catalog without overwriting admin edits.
INSERT INTO nexo.gifts
(id,name,rarity,gems,tradeable,image,tagline,active,item_type,category,description,animation,market_visible,sort_order,tags,metadata)
VALUES
('neon-heart','Neon Heart','Common',15,TRUE,'neon_heart.png','نبضة نيون لطيفة للشات',TRUE,'gift','gifts','هدية نيون خفيفة وسريعة للإرسال في الشات.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('shadow-flame','Shadow Flame','Rare',80,TRUE,'shadow_flame.png','لهب مظلم للغرف الليلية',TRUE,'gift','gifts','لهب غامض مع أثر مضيء عند الإرسال.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('name-glow','Name Glow','Rare',120,TRUE,'name_glow_ticket.png','وهج مميز للاسم',TRUE,'gift','identity','تأثير اسم قابل للاستخدام في الهوية والشات.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('diamond-glow','Diamond Glow','Epic',220,TRUE,'diamond_glow.png','لمعة ماسية عند الإرسال',TRUE,'gift','gifts','هدية ماسية بتأثير لمعان متدرج.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('galaxy-aura','Galaxy Aura','Epic',280,TRUE,'galaxy_aura.png','هالة مجرية حول الرسالة',TRUE,'gift','effects','هالة فضائية تظهر حول الرسالة والصورة.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('rainbow-aura','Rainbow Aura','Epic',350,TRUE,'rainbow_ticket.png','أثر طيفي مميز',TRUE,'gift','effects','طيف لوني نابض مناسب للعروض الخاصة.','rainbow',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('fire-wings','Fire Wings','Legendary',650,TRUE,'fire_wings.png','دخول ناري قوي',TRUE,'gift','gifts','أجنحة نارية بهالة قوية عند الإرسال.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('crown-shine','Crown Shine','Legendary',900,TRUE,'crown_shine.png','تاج لامع للغرف',TRUE,'gift','gifts','تاج ملكي متوهج يظهر عند الإهداء.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('vip-emblem','VIP Emblem','NEXO Exclusive',1800,FALSE,'vip_emblem.png','شارة NEXO حصرية',TRUE,'gift','vip','شارة خاصة غير قابلة للتداول.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('dragon','Dragon','Legendary',12000,TRUE,'assets/nexo/gifts/dragon.svg','تنين NEXO الأسطوري',TRUE,'gift','legendary','تنين طاقة بوهج ناري.','float',TRUE,20,'[]'::jsonb,'{}'::jsonb),
('unicorn','Unicorn','Legendary',9000,TRUE,'assets/nexo/gifts/unicorn.svg','اليونيكورن المتوهج',TRUE,'gift','legendary','يونيكورن سماوي بتدرجات مضيئة.','shine',TRUE,21,'[]'::jsonb,'{}'::jsonb),
('phoenix','Phoenix','Legendary',15000,TRUE,'assets/nexo/gifts/phoenix.svg','بعث الفينيكس',TRUE,'gift','legendary','طائر العنقاء بنبض ناري.','float',TRUE,22,'[]'::jsonb,'{}'::jsonb),
('nexo-car','NEXO Car','Epic',3500,TRUE,'assets/nexo/gifts/nexo-car.svg','السيارة النيون',TRUE,'gift','vehicles','سيارة NEXO الرياضية.','pulse',TRUE,23,'[]'::jsonb,'{}'::jsonb),
('al-hurra','Al-Hurra','NEXO Exclusive',75000,FALSE,'assets/nexo/gifts/al-hurra.svg','الحُرّة',TRUE,'gift','exclusive','رمز حرية حصري.','orbit',TRUE,24,'[]'::jsonb,'{}'::jsonb),
('purity','Purity','Epic',1800,TRUE,'assets/nexo/gifts/purity.svg','النقاء',TRUE,'gift','gifts','قطرة نقاء مضيئة.','shine',TRUE,25,'[]'::jsonb,'{}'::jsonb),
('moon-wolf','Moon Wolf','Epic',2400,TRUE,'assets/nexo/gifts/moon-wolf.svg','ذئب القمر',TRUE,'gift','gifts','ذئب سماوي بتأثير قمري.','pulse',TRUE,26,'[]'::jsonb,'{}'::jsonb),
('crystal-rose','Crystal Rose','Rare',450,TRUE,'assets/nexo/gifts/crystal-rose.svg','وردة كريستالية',TRUE,'gift','gifts','وردة بلورية ملونة.','shine',TRUE,27,'[]'::jsonb,'{}'::jsonb),
('thunder-core','Thunder Core','Rare',700,TRUE,'assets/nexo/gifts/thunder-core.svg','قلب البرق',TRUE,'gift','effects','نواة برق بنبض سريع.','pulse',TRUE,28,'[]'::jsonb,'{}'::jsonb),
('royal-chest','Royal Chest','Legendary',6000,TRUE,'assets/nexo/gifts/royal-chest.svg','الصندوق الملكي',TRUE,'gift','featured','صندوق جوائز ذهبي.','shine',TRUE,29,'[]'::jsonb,'{}'::jsonb),
('ocean-serpent','Ocean Serpent','Epic',3200,TRUE,'assets/nexo/gifts/ocean-serpent.svg','ثعبان المحيط',TRUE,'gift','gifts','ثعبان مائي طيفي.','float',TRUE,30,'[]'::jsonb,'{}'::jsonb),
('cosmic-orb','Cosmic Orb','Rare',550,TRUE,'assets/nexo/gifts/cosmic-orb.svg','الكرة الكونية',TRUE,'gift','effects','طاقة كونية دورانية.','orbit',TRUE,31,'[]'::jsonb,'{}'::jsonb),
('frame-cyan','Cyan Orbit Frame','Rare',900,TRUE,'assets/nexo/frames/cyan-orbit.svg','إطار مدار سماوي',TRUE,'frame','frames','إطار دائري أزرق متوهج.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('frame-violet','Violet Pulse Frame','Epic',1800,TRUE,'assets/nexo/frames/violet-pulse.svg','نبض بنفسجي',TRUE,'frame','frames','إطار نبضي بنفسجي.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('frame-royal','Royal Gold Frame','Legendary',4200,TRUE,'assets/nexo/frames/royal-gold.svg','إطار ذهبي ملكي',TRUE,'frame','frames','حلقة ذهبية للـProfile.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('frame-fire','Inferno Frame','Legendary',6000,TRUE,'assets/nexo/frames/fire-ring.svg','حلقة نارية',TRUE,'frame','frames','إطار ناري قوي.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('frame-galaxy','Galaxy Ring Frame','Epic',3000,TRUE,'assets/nexo/frames/galaxy-ring.svg','مدار مجري',TRUE,'frame','frames','إطار فضائي متحرك.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('frame-exclusive','NEXO Exclusive Frame','NEXO Exclusive',55000,FALSE,'assets/nexo/frames/nexo-exclusive.svg','إطار حصري',TRUE,'frame','frames','إطار محدود.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-cosmic','Cosmic Aura Asset','Epic',1200,TRUE,'assets/nexo/assets/cosmic-aura.svg','هالة كونية',TRUE,'asset','assets','هالة خلفية للهوية.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-inferno','Inferno Wings Asset','Legendary',4500,TRUE,'assets/nexo/assets/inferno-wings.svg','أجنحة لهب',TRUE,'asset','assets','أجنحة هوية متوهجة.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-halo','Royal Halo Asset','Legendary',5200,TRUE,'assets/nexo/assets/royal-halo.svg','الهالة الملكية',TRUE,'asset','assets','هالة حول الصورة.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-shield','NEXO Shield Asset','Rare',800,TRUE,'assets/nexo/assets/nexo-shield.svg','درع NEXO',TRUE,'asset','assets','رمز حماية للهوية.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-comet','Star Comet Asset','Epic',2200,TRUE,'assets/nexo/assets/star-comet.svg','ذيل نجمي',TRUE,'asset','assets','مؤثر سريع.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('asset-prism','Prism Burst Asset','NEXO Exclusive',28000,FALSE,'assets/nexo/assets/prism-burst.svg','انفجار طيفي',TRUE,'asset','assets','أصل بصري حصري.','rainbow',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-laugh','Laugh Burst','Common',25,TRUE,'assets/nexo/emoji/laugh.svg','ضحكة نيون',TRUE,'emoji','emoji','إيموجي متحرك.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-fire','Fire Emoji','Rare',60,TRUE,'assets/nexo/emoji/fire.svg','لهب سريع',TRUE,'emoji','emoji','إيموجي لهب.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-heart','Purple Heart','Common',30,TRUE,'assets/nexo/emoji/purple-heart.svg','قلب بنفسجي',TRUE,'emoji','emoji','إيموجي قلب.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-crown','Crown Emoji','Rare',75,TRUE,'assets/nexo/emoji/crown.svg','تاج لامع',TRUE,'emoji','emoji','إيموجي تاج.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-wow','Wow Emoji','Epic',120,TRUE,'assets/nexo/emoji/wow.svg','دهشة',TRUE,'emoji','emoji','إيموجي دهشة.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-love','Love Emoji','Rare',90,TRUE,'assets/nexo/emoji/love.svg','حب',TRUE,'emoji','emoji','إيموجي حب.','shine',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-rocket','Rocket Emoji','Epic',150,TRUE,'assets/nexo/emoji/rocket.svg','انطلق',TRUE,'emoji','emoji','إيموجي صاروخ.','float',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-snow','Snow Emoji','Rare',65,TRUE,'assets/nexo/emoji/snow.svg','ثلج نيون',TRUE,'emoji','emoji','إيموجي ثلجي.','orbit',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-shadow-mask','Shadow Mask','Epic',1,TRUE,'assets/nexo/crafted/shadow-mask.svg','مصنوع بالـWorkshop',TRUE,'crafted','crafted','قطعة تصنيع.','pulse',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-phoenix-seal','Phoenix Seal','Legendary',1,TRUE,'assets/nexo/crafted/phoenix-seal.svg','ختم الفينيكس',TRUE,'crafted','crafted','قطعة تصنيع نادرة.','shine',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-prism-token','Prism Token','Rare',1,TRUE,'assets/nexo/crafted/prism-token.svg','توكن طيفي',TRUE,'crafted','crafted','قطعة مصنعة.','rainbow',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-nebula-core','Nebula Core','Epic',1,TRUE,'assets/nexo/crafted/nebula-core.svg','نواة سديم',TRUE,'crafted','crafted','نواة مصنعة.','orbit',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-golden-signet','Golden Signet','Legendary',1,TRUE,'assets/nexo/crafted/golden-signet.svg','خاتم ذهبي مصنوع',TRUE,'crafted','crafted','ختم ملكي مصنوع.','shine',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('crafted-arcana','NEXO Arcana','NEXO Exclusive',1,FALSE,'assets/nexo/crafted/nexo-arcana.svg','أركانا NEXO',TRUE,'crafted','crafted','قطعة تصنيع حصرية.','orbit',FALSE,0,'[]'::jsonb,'{}'::jsonb),
('asset-sky-plane','NEXO Sky Plane','Rare',1600,TRUE,'assets/nexo/assets/sky-plane.svg','طائرة NEXO النيون',TRUE,'asset','assets','طائرة نيون تحلق حول الهوية.','float',TRUE,15,'[]'::jsonb,'{}'::jsonb),
('asset-galaxy','Galaxy','Epic',3200,TRUE,'assets/nexo/assets/galaxy.svg','مجرة NEXO',TRUE,'asset','assets','مجرة طيفية تدور حول الهوية.','orbit',TRUE,16,'[]'::jsonb,'{}'::jsonb),
('emoji-grinning','Grinning','Common',20,TRUE,'emoji:😀','Grinning',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-joy','Joy','Common',25,TRUE,'emoji:😂','Joy',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-heart-eyes','Heart Eyes','Common',30,TRUE,'emoji:😍','Heart Eyes',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-cool','Cool','Rare',35,TRUE,'emoji:😎','Cool',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-cry','Crying','Common',20,TRUE,'emoji:😭','Crying',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-angry','Angry','Rare',30,TRUE,'emoji:😡','Angry',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-scream','Scream','Rare',35,TRUE,'emoji:😱','Scream',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-thinking','Thinking','Common',30,TRUE,'emoji:🤔','Thinking',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-party','Party','Rare',35,TRUE,'emoji:🥳','Party',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-devil','Devil','Rare',40,TRUE,'emoji:😈','Devil',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-thumbs-up','Thumbs Up','Common',20,TRUE,'emoji:👍','Thumbs Up',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-thumbs-down','Thumbs Down','Common',20,TRUE,'emoji:👎','Thumbs Down',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-wave','Wave','Common',20,TRUE,'emoji:👋','Wave',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-pray','Pray','Common',25,TRUE,'emoji:🙏','Pray',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-clap','Clap','Common',25,TRUE,'emoji:👏','Clap',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-red-heart','Red Heart','Common',25,TRUE,'emoji:❤️','Red Heart',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-purple-heart','Purple Heart','Common',30,TRUE,'emoji:💜','Purple Heart',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-blue-heart','Blue Heart','Common',30,TRUE,'emoji:💙','Blue Heart',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-green-heart','Green Heart','Common',30,TRUE,'emoji:💚','Green Heart',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-yellow-heart','Yellow Heart','Common',30,TRUE,'emoji:💛','Yellow Heart',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-fire','Fire','Rare',60,TRUE,'emoji:🔥','Fire',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-sparkles','Sparkles','Rare',40,TRUE,'emoji:✨','Sparkles',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-party-popper','Party Popper','Rare',40,TRUE,'emoji:🎉','Party Popper',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-rocket','Rocket','Epic',75,TRUE,'emoji:🚀','Rocket',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-gem','Gem','Epic',80,TRUE,'emoji:💎','Gem',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-crown','Crown','Epic',80,TRUE,'emoji:👑','Crown',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-lightning','Lightning','Rare',55,TRUE,'emoji:⚡','Lightning',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-star','Star','Rare',45,TRUE,'emoji:🌟','Star',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-check','Check','Common',20,TRUE,'emoji:✅','Check',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-x','Cross','Common',20,TRUE,'emoji:❌','Cross',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-hundred','Hundred','Rare',50,TRUE,'emoji:💯','Hundred',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-handshake','Handshake','Common',30,TRUE,'emoji:🤝','Handshake',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb),
('emoji-hearts','Heart Hands','Rare',40,TRUE,'emoji:🫶','Heart Hands',TRUE,'emoji','emoji','Standard emoji for chat and collection.','pulse',TRUE,0,'[]'::jsonb,'{}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- NEXO FRAMES 36: unified frame pricing
INSERT INTO nexo.gifts (id,name,rarity,gems,tradeable,image,tagline,active,item_type,category,description,animation,market_visible,sort_order,tags,metadata) VALUES
('frame-01-sunrise','Sunrise Frame','Common',100,TRUE,'assets/nexo/frames/original_30/frame-01-sunrise.png','Sunrise Frame',TRUE,'frame','frames','Sunrise Frame','shine',TRUE,100,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-02-simple-gold','Simple Gold','Common',150,TRUE,'assets/nexo/frames/original_30/frame-02-simple-gold.png','Simple Gold',TRUE,'frame','frames','Simple Gold','shine',TRUE,101,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-03-ocean-wave','Ocean Wave','Common',200,TRUE,'assets/nexo/frames/original_30/frame-03-ocean-wave.png','Ocean Wave',TRUE,'frame','frames','Ocean Wave','float',TRUE,102,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-04-papyrus-ring','Papyrus Ring','Common',250,TRUE,'assets/nexo/frames/original_30/frame-04-papyrus-ring.png','Papyrus Ring',TRUE,'frame','frames','Papyrus Ring','pulse',TRUE,103,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-cyan','Cyan Orbit Frame','Common',250,TRUE,'assets/nexo/frames/cyan-orbit.svg','Legacy Cyan Orbit Frame',TRUE,'frame','frames','Cyan Orbit Frame','shine',TRUE,104,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-05-desert-oasis','Desert Oasis','Uncommon',400,TRUE,'assets/nexo/frames/original_30/frame-05-desert-oasis.png','Desert Oasis',TRUE,'frame','frames','Desert Oasis','float',TRUE,105,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-06-balloon-party','Balloon Party','Uncommon',500,TRUE,'assets/nexo/frames/original_30/frame-06-balloon-party.png','Balloon Party',TRUE,'frame','frames','Balloon Party','pulse',TRUE,106,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-07-zodiac','Zodiac Frame','Uncommon',650,TRUE,'assets/nexo/frames/original_30/frame-07-zodiac.png','Zodiac Frame',TRUE,'frame','frames','Zodiac Frame','orbit',TRUE,107,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-08-bronze-lv10','Bronze Frame (Lv.10)','Uncommon',800,TRUE,'assets/nexo/frames/original_30/frame-08-bronze-lv10.png','Bronze Frame (Lv.10)',TRUE,'frame','frames','Bronze Frame (Lv.10)','shine',TRUE,108,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-09-bonded-hearts','Bonded Hearts Frame','Uncommon',1000,TRUE,'assets/nexo/frames/original_30/frame-09-bonded-hearts.png','Bonded Hearts Frame',TRUE,'frame','frames','Bonded Hearts Frame','pulse',TRUE,109,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-violet','Violet Pulse Frame','Uncommon',1000,TRUE,'assets/nexo/frames/violet-pulse.svg','Legacy Violet Pulse Frame',TRUE,'frame','frames','Violet Pulse Frame','shine',TRUE,110,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-10-crystal-ring','Crystal Ring','Rare',1500,TRUE,'assets/nexo/frames/original_30/frame-10-crystal-ring.png','Crystal Ring',TRUE,'frame','frames','Crystal Ring','shine',TRUE,111,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-11-warrior','Warrior Frame','Rare',2000,TRUE,'assets/nexo/frames/original_30/frame-11-warrior.png','Warrior Frame',TRUE,'frame','frames','Warrior Frame','float',TRUE,112,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-12-love-bloom','Love Bloom','Rare',2500,TRUE,'assets/nexo/frames/original_30/frame-12-love-bloom.png','Love Bloom',TRUE,'frame','frames','Love Bloom','pulse',TRUE,113,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-13-silver-lv25','Silver Frame (Lv.25)','Rare',3000,TRUE,'assets/nexo/frames/original_30/frame-13-silver-lv25.png','Silver Frame (Lv.25)',TRUE,'frame','frames','Silver Frame (Lv.25)','shine',TRUE,114,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-14-ramadan-lantern','Ramadan Lantern Frame','Rare',4000,TRUE,'assets/nexo/frames/original_30/frame-14-ramadan-lantern.png','Ramadan Lantern Frame',TRUE,'frame','frames','Ramadan Lantern Frame','shine',TRUE,115,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-galaxy','Galaxy Ring Frame','Rare',3000,TRUE,'assets/nexo/frames/galaxy-ring.svg','Legacy Galaxy Ring Frame',TRUE,'frame','frames','Galaxy Ring Frame','shine',TRUE,116,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-15-fire-lion','Fire Lion','Epic',6000,TRUE,'assets/nexo/frames/original_30/frame-15-fire-lion.png','Fire Lion',TRUE,'frame','frames','Fire Lion','float',TRUE,117,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-16-diamond-princess','Diamond Princess','Epic',7500,TRUE,'assets/nexo/frames/original_30/frame-16-diamond-princess.png','Diamond Princess',TRUE,'frame','frames','Diamond Princess','shine',TRUE,118,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-17-golden-wings','Golden Wings','Epic',9000,TRUE,'assets/nexo/frames/original_30/frame-17-golden-wings.png','Golden Wings',TRUE,'frame','frames','Golden Wings','float',TRUE,119,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-18-gold-lv50','Gold Frame (Lv.50)','Epic',11000,TRUE,'assets/nexo/frames/original_30/frame-18-gold-lv50.png','Gold Frame (Lv.50)',TRUE,'frame','frames','Gold Frame (Lv.50)','shine',TRUE,120,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-19','Frame 19','Epic',13000,TRUE,'assets/nexo/frames/original_30/frame-19-frame-19.png','Frame 19',TRUE,'frame','frames','Frame 19','pulse',TRUE,121,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-20-eternal-bond','Eternal Bond Frame','Epic',15000,TRUE,'assets/nexo/frames/original_30/frame-20-eternal-bond.png','Eternal Bond Frame',TRUE,'frame','frames','Eternal Bond Frame','pulse',TRUE,122,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-royal','Royal Gold Frame','Epic',11000,TRUE,'assets/nexo/frames/royal-gold.svg','Legacy Royal Gold Frame',TRUE,'frame','frames','Royal Gold Frame','shine',TRUE,123,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-21-noble','Noble Frame (Rank 1/6)','Legendary',20000,TRUE,'assets/nexo/frames/original_30/frame-21-noble.png','Noble Frame (Rank 1/6)',TRUE,'frame','frames','Noble Frame (Rank 1/6)','shine',TRUE,124,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-22-scribe','Scribe Frame (Rank 2/6)','Legendary',25000,TRUE,'assets/nexo/frames/original_30/frame-22-scribe.png','Scribe Frame (Rank 2/6)',TRUE,'frame','frames','Scribe Frame (Rank 2/6)','shine',TRUE,125,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-23-vizier','Vizier Frame (Rank 3/6)','Legendary',30000,TRUE,'assets/nexo/frames/original_30/frame-23-vizier.png','Vizier Frame (Rank 3/6)',TRUE,'frame','frames','Vizier Frame (Rank 3/6)','shine',TRUE,126,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-24-platinum-lv100','Platinum Frame (Lv.100)','Legendary',40000,TRUE,'assets/nexo/frames/original_30/frame-24-platinum-lv100.png','Platinum Frame (Lv.100)',TRUE,'frame','frames','Platinum Frame (Lv.100)','shine',TRUE,127,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-25-anniversary','Anniversary Frame','Legendary',50000,TRUE,'assets/nexo/frames/original_30/frame-25-anniversary.png','Anniversary Frame',TRUE,'frame','frames','Anniversary Frame','pulse',TRUE,128,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-fire','Inferno Frame','Legendary',50000,TRUE,'assets/nexo/frames/fire-ring.svg','Legacy Inferno Frame',TRUE,'frame','frames','Inferno Frame','shine',TRUE,129,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-26-high-priest','High Priest Frame (Rank 4/6)','Mythic',75000,TRUE,'assets/nexo/frames/original_30/frame-26-high-priest.png','High Priest Frame (Rank 4/6)',TRUE,'frame','frames','High Priest Frame (Rank 4/6)','shine',TRUE,130,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-27-nomarch','Nomarch Frame (Rank 5/6)','Mythic',100000,TRUE,'assets/nexo/frames/original_30/frame-27-nomarch.png','Nomarch Frame (Rank 5/6)',TRUE,'frame','frames','Nomarch Frame (Rank 5/6)','shine',TRUE,131,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-28-pharaoh','Pharaoh Frame (Rank 6/6)','Mythic',150000,TRUE,'assets/nexo/frames/original_30/frame-28-pharaoh.png','Pharaoh Frame (Rank 6/6)',TRUE,'frame','frames','Pharaoh Frame (Rank 6/6)','shine',TRUE,132,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-29-mythic-lv200','Mythic Frame (Lv.200)','Mythic',200000,TRUE,'assets/nexo/frames/original_30/frame-29-mythic-lv200.png','Mythic Frame (Lv.200)',TRUE,'frame','frames','Mythic Frame (Lv.200)','shine',TRUE,133,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-30-new-year','New Year Frame','Mythic',250000,TRUE,'assets/nexo/frames/original_30/frame-30-new-year.png','New Year Frame',TRUE,'frame','frames','New Year Frame','orbit',TRUE,134,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb),
('frame-exclusive','NEXO Exclusive Frame','Mythic',150000,FALSE,'assets/nexo/frames/nexo-exclusive.svg','Legacy NEXO Exclusive Frame',TRUE,'frame','frames','NEXO Exclusive Frame','shine',TRUE,135,'[]'::jsonb,'{"source":"legacy_six","group":"frames36"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name,rarity=EXCLUDED.rarity,gems=EXCLUDED.gems,tradeable=EXCLUDED.tradeable,image=EXCLUDED.image,tagline=EXCLUDED.tagline,active=EXCLUDED.active,item_type=EXCLUDED.item_type,category=EXCLUDED.category,description=EXCLUDED.description,animation=EXCLUDED.animation,market_visible=EXCLUDED.market_visible,sort_order=EXCLUDED.sort_order,tags=EXCLUDED.tags,metadata=EXCLUDED.metadata;
