-- NEXO CHANGE 67: expand D1 core contract to match the live PostgreSQL API.
-- Safe additive migration. Does not enable traffic by itself.

ALTER TABLE users ADD COLUMN svip_active INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN svip_expires_at TEXT;
ALTER TABLE users ADD COLUMN aristocracy_level INTEGER NOT NULL DEFAULT 0;

ALTER TABLE catalog_items ADD COLUMN featured INTEGER NOT NULL DEFAULT 0;
ALTER TABLE catalog_items ADD COLUMN limited INTEGER NOT NULL DEFAULT 0;
ALTER TABLE catalog_items ADD COLUMN tags_json TEXT NOT NULL DEFAULT '[]';
ALTER TABLE catalog_items ADD COLUMN metadata_json TEXT NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_catalog_market
  ON catalog_items(active,market_visible,item_type,sort_order,gems);

CREATE INDEX IF NOT EXISTS idx_inventory_user
  ON inventory(user_id,item_id);
