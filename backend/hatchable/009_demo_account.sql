-- NEXO demo account for QA/login verification.
INSERT INTO users(id,username,email,password_hash,display_name,gems,energy)
VALUES(gen_random_uuid(),'nexo_demo','nexo_demo@nexo.local','pbkdf2sha256$120000$4af0f39392f3f85c6161fb0b19a4cefc$16186f5f53d0e23bdcccbd5f9623ee5596e3eaf962a4f1cffd3f69f010d79009','NEXO Demo',10000,100)
ON CONFLICT(username) DO UPDATE SET password_hash=EXCLUDED.password_hash,email=EXCLUDED.email,display_name=EXCLUDED.display_name,gems=GREATEST(users.gems,10000),energy=100;

INSERT INTO user_preferences(user_id)
SELECT id FROM users WHERE username='nexo_demo'
ON CONFLICT(user_id) DO NOTHING;

INSERT INTO user_memberships(user_id)
SELECT id FROM users WHERE username='nexo_demo'
ON CONFLICT(user_id) DO NOTHING;

INSERT INTO profile_stats(user_id,wealth_score,charm_score)
SELECT id,gems,0 FROM users WHERE username='nexo_demo'
ON CONFLICT(user_id) DO NOTHING;

INSERT INTO inventory(user_id,item_id,quantity)
SELECT u.id,g.id,1 FROM users u JOIN gifts g ON g.id='power_chat_spark'
WHERE u.username='nexo_demo'
ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=GREATEST(inventory.quantity,1);

INSERT INTO inventory(user_id,item_id,quantity)
SELECT u.id,g.id,1 FROM users u JOIN gifts g ON g.id='power_glow_frame'
WHERE u.username='nexo_demo'
ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=GREATEST(inventory.quantity,1);

INSERT INTO inventory(user_id,item_id,quantity)
SELECT u.id,g.id,1 FROM users u JOIN gifts g ON g.id='power_vip_aura'
WHERE u.username='nexo_demo'
ON CONFLICT(user_id,item_id) DO UPDATE SET quantity=GREATEST(inventory.quantity,1);

INSERT INTO user_equipped(user_id,slot,item_id)
SELECT u.id,'power','power_chat_spark' FROM users u
JOIN inventory i ON i.user_id=u.id AND i.item_id='power_chat_spark' AND i.quantity>0
WHERE u.username='nexo_demo'
ON CONFLICT(user_id,slot) DO UPDATE SET item_id=EXCLUDED.item_id,updated_at=NOW();
