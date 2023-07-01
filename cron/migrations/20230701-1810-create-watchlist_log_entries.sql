CREATE TABLE watchlist_log_entries (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	ip TEXT,
	log_id INTEGER,
	log_line TEXT,
	created_at TEXT
);
