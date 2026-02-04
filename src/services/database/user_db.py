"""
User database operations using SQLite.
"""

"""
User database operations supporting both MongoDB and SQLite.
"""

import sqlite3
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
import asyncio
from pathlib import Path

from src.services.auth.password import hash_password, verify_password
from src.services.database.mongo_db import get_database

# =============================================================================
# MONGODB IMPLEMENTATION (ACTIVE)
# Uses motor (async) driver. Maps to 'MongoUserDatabase' for active usage.
# =============================================================================
class MongoUserDatabase:
    """Manages user data in MongoDB."""
    
    def __init__(self):
        """Initialize."""
        pass

    @property
    def _users(self):
        return get_database().users

    async def _seed_default_users(self):
        """Create default users if none exist."""
        try:
            count = await self._users.count_documents({})
            if count == 0:
                await self.create_user("admin", "admin123", "System Administrator", "admin", "admin@iteagrow.com")
                await self.create_user("manager", "manager123", "Tea Estate Manager", "manager", "manager@iteagrow.com")
                await self.create_user("farmer", "farmer123", "Tea Farmer", "farmer", "farmer@iteagrow.com")
        except Exception as e:
            print(f"Mongo Seed Error: {e}")

    async def create_user(self, username, password, full_name, role, email=None, phone=None, language_preference="en"):
        existing = await self._users.find_one({"username": username})
        if existing: return None
        
        user_doc = {
            "username": username,
            "password_hash": hash_password(password),
            "full_name": full_name,
            "role": role,
            "email": email,
            "phone": phone,
            "language_preference": language_preference,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "is_active": True
        }
        result = await self._users.insert_one(user_doc)
        return await self.get_user_by_id(result.inserted_id)

    async def get_user_by_username(self, username: str):
        user = await self._users.find_one({"username": username})
        if user: user['id'] = str(user.pop('_id'))
        return user

    async def get_user_by_id(self, user_id):
        from bson import ObjectId
        try:
            oid = ObjectId(user_id) if isinstance(user_id, str) else user_id
            user = await self._users.find_one({"_id": oid})
            if user: user['id'] = str(user.pop('_id'))
            return user
        except: return None

    async def update_user(self, user_id, updates):
        from bson import ObjectId
        updates = {k: v for k, v in updates.items() if k not in ['id', 'username', 'password_hash', 'created_at']}
        if not updates: return False
        try:
            oid = ObjectId(user_id) if isinstance(user_id, str) else user_id
            res = await self._users.update_one({"_id": oid}, {"$set": updates})
            return res.modified_count > 0 or res.matched_count > 0
        except: return False

    async def verify_credentials(self, username, password):
        user = await self._users.find_one({"username": username})
        if user and verify_password(password, user['password_hash']):
            user['id'] = str(user.pop('_id'))
            return user
        return None


# =============================================================================
# SQLITE IMPLEMENTATION (PRESERVED/PARALLEL)
# Uses sqlite3 (sync) driver. Available via 'get_sqlite_db()'.
# =============================================================================
class SQLiteUserDatabase:
    """Manages user data in SQLite database (Legacy/Local Mode)."""
    
    def __init__(self, db_path: str = "storage/local/users.db"):
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self._create_tables()
        self._seed_default_users()
    
    def _get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def _create_tables(self):
        with self._get_connection() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    full_name TEXT NOT NULL,
                    role TEXT NOT NULL,
                    email TEXT,
                    phone TEXT,
                    language_preference TEXT DEFAULT 'en',
                    is_active BOOLEAN DEFAULT 1,
                    created_at TEXT NOT NULL
                )
            """)
            conn.commit()
    
    def _seed_default_users(self):
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT COUNT(*) as count FROM users")
            if cursor.fetchone()['count'] == 0:
                self.create_user("admin", "admin123", "System Administrator", "admin", "admin@iteagrow.com")
                self.create_user("manager", "manager123", "Tea Estate Manager", "manager", "manager@iteagrow.com")
                self.create_user("farmer", "farmer123", "Tea Farmer", "farmer", "farmer@iteagrow.com")
    
    def create_user(self, username, password, full_name, role, email=None, phone=None, language_preference="en"):
        try:
            with self._get_connection() as conn:
                cursor = conn.execute("""
                    INSERT INTO users (username, password_hash, full_name, role, email, phone, language_preference, created_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (username, hash_password(password), full_name, role, email, phone, language_preference, datetime.utcnow().isoformat()))
                conn.commit()
                return self.get_user_by_id(cursor.lastrowid)
        except sqlite3.IntegrityError: return None
    
    def get_user_by_username(self, username):
        with self._get_connection() as conn:
            row = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
            return dict(row) if row else None
    
    def get_user_by_id(self, user_id):
        with self._get_connection() as conn:
            row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
            return dict(row) if row else None

    # Sync versions of update and verify... 
    def update_user(self, user_id, updates):
        updates = {k: v for k, v in updates.items() if k not in ['id', 'username', 'password_hash', 'created_at']}
        if not updates: return False
        try:
            with self._get_connection() as conn:
                set_clause = ", ".join(f"{key} = ?" for key in updates.keys())
                conn.execute(f"UPDATE users SET {set_clause} WHERE id = ?", list(updates.values()) + [user_id])
                conn.commit()
                return True
        except: return False

    def verify_credentials(self, username, password):
        user = self.get_user_by_username(username)
        if user and verify_password(password, user['password_hash']): return user
        return None


# Singleton instance
_mongo_user_db: Optional[MongoUserDatabase] = None
_sqlite_user_db: Optional[SQLiteUserDatabase] = None

# Primary Accessor (Switched to Mongo)
def get_user_db() -> MongoUserDatabase:
    """Get MongoDB User DB instance."""
    global _mongo_user_db
    if _mongo_user_db is None:
        _mongo_user_db = MongoUserDatabase()
    return _mongo_user_db

# Secondary Accessor (SQLite)
def get_sqlite_db() -> SQLiteUserDatabase:
    """Get SQLite User DB instance."""
    global _sqlite_user_db
    if _sqlite_user_db is None:
        _sqlite_user_db = SQLiteUserDatabase()
    return _sqlite_user_db
