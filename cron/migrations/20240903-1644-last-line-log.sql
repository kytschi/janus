ALTER TABLE logs ADD last_line TEXT;
ALTER TABLE logs ADD last_line_number int(11);
ALTER TABLE logs ADD md5_hash varchar(36) NULL;