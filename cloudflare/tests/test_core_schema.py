"""Local-only contract tests for the initial D1 schema.

These tests use an in-memory SQLite database and never create users/data in production.
They validate storage constraints; they do not claim that D1-native HTTP auth/economy routes
have been implemented yet (those routes still proxy to Railway).
"""
import sqlite3
import unittest
from pathlib import Path

MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0001_init.sql"


class NexoCoreSchemaTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.db.row_factory = sqlite3.Row
        self.db.execute("PRAGMA foreign_keys = ON")
        self.db.executescript(MIGRATION.read_text(encoding="utf-8"))

    def tearDown(self):
        self.db.close()

    def create_user(self, user_id="u-test-1", username="local-ci-user"):
        self.db.execute(
            """INSERT INTO users (id, username, email, password_hash, display_name)
               VALUES (?, ?, ?, ?, ?)""",
            (user_id, username, username + "@example.invalid", "test-hash-not-a-secret", username),
        )

    def test_core_account_wallet_store_tables_exist(self):
        expected = {"users", "catalog_items", "inventory", "user_equipped", "wallet_ledger"}
        actual = {
            row["name"]
            for row in self.db.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()
        }
        self.assertTrue(expected.issubset(actual))

    def test_registration_fields_defaults_and_username_uniqueness(self):
        self.create_user()
        row = self.db.execute(
            "SELECT username, password_hash, gems, energy, banned FROM users WHERE id='u-test-1'"
        ).fetchone()
        self.assertEqual(row["username"], "local-ci-user")
        self.assertEqual(row["password_hash"], "test-hash-not-a-secret")
        self.assertEqual(row["gems"], 1000)
        self.assertEqual(row["energy"], 50)
        self.assertEqual(row["banned"], 0)
        with self.assertRaises(sqlite3.IntegrityError):
            self.create_user(user_id="u-test-2", username="local-ci-user")

    def test_market_item_inventory_and_equipped_profile_round_trip(self):
        self.create_user()
        self.db.execute(
            """INSERT INTO catalog_items
               (id, name, rarity, gems, item_type, category, featured, market_visible)
               VALUES ('ci-frame', 'CI Frame', 'Rare', 250, 'frame', 'frames', 1, 1)"""
        )
        self.db.execute(
            "INSERT INTO inventory (user_id, item_id, quantity) VALUES ('u-test-1', 'ci-frame', 1)"
        )
        self.db.execute(
            "INSERT INTO user_equipped (user_id, slot, item_id) VALUES ('u-test-1', 'frame', 'ci-frame')"
        )
        item = self.db.execute(
            """SELECT c.id, c.gems, i.quantity, e.slot
               FROM catalog_items c
               JOIN inventory i ON i.item_id = c.id
               JOIN user_equipped e ON e.item_id = c.id
               WHERE i.user_id='u-test-1' AND c.market_visible=1"""
        ).fetchone()
        self.assertEqual((item["id"], item["gems"], item["quantity"], item["slot"]),
                         ("ci-frame", 250, 1, "frame"))

    def test_wallet_purchase_is_recorded_and_idempotency_key_is_unique(self):
        self.create_user()
        self.db.execute(
            """INSERT INTO catalog_items (id, name, rarity, gems, item_type, category)
               VALUES ('ci-gift', 'CI Gift', 'Common', 250, 'gift', 'gifts')"""
        )
        self.db.commit()
        # Exercise the intended transaction pattern against the local schema only.
        self.db.execute("BEGIN")
        cur = self.db.execute(
            "UPDATE users SET gems = gems - 250 WHERE id='u-test-1' AND gems >= 250"
        )
        self.assertEqual(cur.rowcount, 1)
        balance = self.db.execute(
            "SELECT gems FROM users WHERE id='u-test-1'"
        ).fetchone()["gems"]
        self.db.execute(
            "INSERT INTO inventory (user_id, item_id, quantity) VALUES ('u-test-1', 'ci-gift', 1)"
        )
        self.db.execute(
            """INSERT INTO wallet_ledger
               (id, user_id, kind, amount, balance_after, idempotency_key)
               VALUES ('ledger-1', 'u-test-1', 'store_purchase', -250, ?, 'ci-purchase-1')""",
            (balance,),
        )
        self.db.commit()
        self.assertEqual(balance, 750)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                """INSERT INTO wallet_ledger
                   (id, user_id, kind, amount, balance_after, idempotency_key)
                   VALUES ('ledger-2', 'u-test-1', 'store_purchase', -250, 500, 'ci-purchase-1')"""
            )

    def test_balances_energy_and_inventory_cannot_go_negative_or_over_cap(self):
        self.create_user()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE users SET gems = -1 WHERE id='u-test-1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE users SET energy = 101 WHERE id='u-test-1'")
        self.db.execute(
            "INSERT INTO catalog_items (id, name, rarity, gems, item_type, category) VALUES ('ci-item', 'CI', 'Common', 1, 'gift', 'gifts')"
        )
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO inventory (user_id, item_id, quantity) VALUES ('u-test-1', 'ci-item', -1)"
            )


if __name__ == "__main__":
    unittest.main()
