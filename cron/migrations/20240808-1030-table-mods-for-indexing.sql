/* IGNORE SQLITE */

/* blacklist table */
ALTER TABLE blacklist MODIFY COLUMN ip varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE blacklist ADD INDEX (ip);

ALTER TABLE blacklist MODIFY COLUMN country varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE blacklist ADD INDEX (country);

ALTER TABLE blacklist MODIFY COLUMN `service` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE blacklist ADD INDEX (`service`);

ALTER TABLE blacklist MODIFY COLUMN created_at date NOT NULL;
ALTER TABLE blacklist ADD INDEX (created_at);

ALTER TABLE blacklist ADD INDEX (ipvsix);

/* block_patterns table */
ALTER TABLE block_patterns MODIFY COLUMN `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE block_patterns MODIFY COLUMN `category` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;

/* found_block_patterns table */
ALTER TABLE found_block_patterns MODIFY COLUMN `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE found_block_patterns MODIFY COLUMN `ip` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE found_block_patterns MODIFY COLUMN `category` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE found_block_patterns MODIFY COLUMN `created_at` date NOT NULL;

/* settings table */
ALTER TABLE settings MODIFY COLUMN `firewall_command` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE settings MODIFY COLUMN `firewall_cfg_folder` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE settings MODIFY COLUMN `firewall_cfg_file_v4` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE settings MODIFY COLUMN `cron_folder` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE settings MODIFY COLUMN `webuser` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'www-data' NOT NULL;
ALTER TABLE settings MODIFY COLUMN `firewall_cfg_file_v6` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE settings MODIFY COLUMN `firewall_command_v6` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;

/* users table */
ALTER TABLE users MODIFY COLUMN `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE users MODIFY COLUMN `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;

/* watchlist table */
ALTER TABLE watchlist MODIFY COLUMN ip varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE watchlist ADD INDEX (ip);

ALTER TABLE watchlist MODIFY COLUMN country varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE watchlist ADD INDEX (country);

ALTER TABLE watchlist MODIFY COLUMN `service` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE watchlist ADD INDEX (`service`);

ALTER TABLE watchlist MODIFY COLUMN created_at date NOT NULL;
ALTER TABLE watchlist ADD INDEX (created_at);

/* watchlist_log_entries table */
ALTER TABLE watchlist MODIFY COLUMN ip varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE watchlist ADD INDEX (ip);

ALTER TABLE watchlist MODIFY COLUMN created_at date NOT NULL;
ALTER TABLE watchlist ADD INDEX (created_at);

ALTER TABLE watchlist ADD INDEX (log_id);

/* whitelist table */
ALTER TABLE whitelist MODIFY COLUMN ip varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE whitelist ADD INDEX (ip);

ALTER TABLE whitelist MODIFY COLUMN country varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE whitelist ADD INDEX (country);

ALTER TABLE whitelist MODIFY COLUMN `service` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE whitelist ADD INDEX (`service`);

ALTER TABLE whitelist MODIFY COLUMN created_at date NOT NULL;
ALTER TABLE whitelist ADD INDEX (created_at);

ALTER TABLE whitelist ADD INDEX (ipvsix);

ALTER TABLE whitelist MODIFY COLUMN `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL NULL;
ALTER TABLE whitelist ADD INDEX (`label`);