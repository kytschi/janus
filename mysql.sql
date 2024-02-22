CREATE TABLE `blacklist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` text DEFAULT NULL,
  `country` text DEFAULT NULL,
  `whois` text DEFAULT NULL,
  `service` text DEFAULT NULL,
  `created_at` text DEFAULT NULL,
  `ipvsix` int(11) DEFAULT 0,
  `note` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `block_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pattern` text DEFAULT NULL,
  `label` text DEFAULT NULL,
  `category` text DEFAULT NULL,
  `note` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=138 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

LOCK TABLES `block_patterns` WRITE;
INSERT INTO `block_patterns` VALUES (1,'/wp-info.php','WordPress','WordPress',NULL),(2,'/wp-class.php','WordPress','WordPress',NULL),(3,'/wp-admin.php','WordPress','WordPress',NULL),(4,'/wp-login.php','WordPress','WordPress',NULL),(5,'/wordpress','WordPress','WordPress',NULL),(6,'/wp-content/plugins/woocommerce/readme.txt','WordPress','WordPress',NULL),(7,'/.well-known','.well-known','Hidden Credentials',NULL),(8,'\\\\x16\\\\','HEX','Buffer Overflow',NULL),(9,'\\\\xCC\\\\','HEX','Buffer Overflow',NULL),(10,'\\\\x03\\\\','HEX','Buffer Overflow',NULL),(11,'\\\\x83\\\\','HEX','Buffer Overflow',NULL),(12,'\\\\xC3','HEX','Buffer Overflow',NULL),(13,'/shell4.php','shell4.php','PHP Script',NULL),(14,'/boaform/admin/formLogin','formLogin','Login',NULL),(15,'/data.php','data.php','PHP Script',NULL),(16,'/fw.php','fw.php','PHP Script',NULL),(17,'/x.php','x.php','PHP Script',NULL),(18,'/wso112233.php','wso112233.php','PHP Script',NULL),(19,'/client/get_targets','get_targets','Misc Script',NULL),(20,'/upl.php','upl.php','PHP Script',NULL),(21,'/geoip/','geoip','Misc Script',NULL),(22,'/ai.txt','ai.txt','Text File',NULL),(23,'/setup.cgi','setup.cgi','CGI Script',NULL),(24,'/.env','.env','Credentials',NULL),(25,'/.aws/credentials','AWS credentials','AWS Credentials',NULL),(26,'/aws/credentials','AWS credentials','AWS Credentials',NULL),(27,'/credentials','AWS credentials','AWS Credentials',NULL),(28,'/global_settings.py','global_settings.py','Python Script',NULL),(29,'/_profiler/','_profiler','Misc Script',NULL),(30,'/debug/default/view','Debug view','Misc Script',NULL),(31,'/frontend_dev.php','frontend_dev.php','PHP Script',NULL),(32,'/config.json','config.json','Config File',NULL),(33,'/phpinfo.php','phpinfo.php','PHP Script',NULL),(34,'/info.php','info.php','PHP Script',NULL),(35,'/?phpinfo=','phpinfo','PHP Script',NULL),(36,'/password.php','password.php','PHP Script',NULL),(37,'/__down','__down','Misc Script',NULL),(38,'/actuator/health','Actuator health','Misc Script',NULL),(40,'/.git','.git','Config File',NULL),(41,'/remote/fgt_lang','fgt_lang','Misc Script',NULL),(42,'/autodiscover/autodiscover.json','autodiscover.json','Config File',NULL),(43,'/_ignition/execute-solution','_ignition','Misc Script',NULL),(44,'/owa','owa','MS Credentials',NULL),(45,'/ecp/Current/exporttool/microsoft','owa','MS Credentials',NULL),(46,'/aws.yml','aws.yml','AWS Credentials',NULL),(47,'/sms.py','sms.py','Python Script',NULL),(48,'/isadmin.php','isadmin.php','PHP Script',NULL),(49,'/.travis.yml','.travis.yml','Credentials',NULL),(50,'/s3.js','s3.js','AWS Credentials',NULL),(51,'/aws-secret.yaml','aws-secret.yaml','AWS Credentials',NULL),(52,'/env.template','env.template','Credentials',NULL),(53,'/settings.py','settings.py','Python Script',NULL),(54,'/private/api/v1/service/premaster','Premaster API','API',NULL),(55,'/cgi-bin/adm.cgi','adm.cgi','CGI Script',NULL),(56,'/.svn','.svn','Config File',NULL),(57,'/eval-stdin.php','phpunit','PHP Script',NULL),(58,'\\x16','HEX','Buffer Overflow',NULL),(59,'/wp-json','wp-json','WordPress',NULL),(60,'/solr/admin/info/system?wt=json ','Solr Info','Misc Script',NULL),(61,'invokefunction','invoke function','PHP Script',NULL),(62,'/bala.php','bala.php','PHP Script',NULL),(63,'/t_file_wp.php','t_file_wp Plugin','WordPress',NULL),(64,'/ufahncsiwd.php','t_file_wp Plugin','WordPress',NULL),(65,'/apikey.php','apikey Plugin','WordPress',NULL),(66,'content=die(','content=die(','Misc Script',NULL),(67,'/?XDEBUG_SESSION_START=phpstorm','XDEBUG','XDEBUG',NULL),(68,'/util/bash','Bash','Misc Script',NULL),(69,' /cgi-bin/','CGI bin','CGI Script',NULL),(70,'|\'|\'|','SQL Injection','SQL Injection',NULL),(71,'Gh0st','Buffer Overflow','Buffer Overflow',NULL),(72,'\\x00','Buffer Overflow','Buffer Overflow',NULL),(73,'\\x1B','Buffer Overflow','Buffer Overflow',NULL),(74,'\\x01','Buffer Overflow','Buffer Overflow',NULL),(75,'\\xBD','Buffer Overflow','Buffer Overflow',NULL),(76,'A\\x00','Buffer Overflow','Buffer Overflow',NULL),(77,'\\x09','Buffer Overflow','Buffer Overflow',NULL),(78,'/geoserver','Geoserver','Misc Script',NULL),(79,'/actuator/gateway/routes','Actuator','Misc Script',NULL),(80,'password.php','password.php','PHP Script',NULL),(81,'/phpMyAdmin','phpMyAdmin','phpMyAdmin',NULL),(82,'/myadmin','phpMyAdmin','phpMyAdmin',NULL),(83,'_phpMyAdmin','phpMyAdmin','phpMyAdmin',NULL),(84,'/websql','phpMyAdmin','phpMyAdmin',NULL),(85,'/webdb','phpMyAdmin','phpMyAdmin',NULL),(86,'/sqlweb','phpMyAdmin','phpMyAdmin',NULL),(87,'/phpma','phpMyAdmin','phpMyAdmin',NULL),(88,'/mysqlmanager','phpMyAdmin','phpMyAdmin',NULL),(89,'/sqlmanager','phpMyAdmin','phpMyAdmin',NULL),(90,'/php-myadmin','phpMyAdmin','phpMyAdmin',NULL),(91,'/phpmy-admin','phpMyAdmin','phpMyAdmin',NULL),(92,'/portal/redlion','redlion','Misc Script',NULL),(93,'\\x03U','Buffer Overflow','Buffer Overflow',NULL),(94,'/GponForm/diag_Form?images/ ','GponForm','Misc Script',NULL),(95,'0;sh','SH Script','Misc Script',NULL),(96,'/wp-config.php.bak','wp-config.php.bak','WordPress',NULL),(97,'/?=PHP','PHP Query','PHP Script',NULL),(98,'/Portal/Portal.mwsl','Portal.mwsl','Misc Script',NULL),(99,'/start.pl','start.pl','Perl Script',NULL),(100,'/inicio.cgi','inicio.cgi','CGI Script',NULL),(101,'/scripts/WPnBr.dll','WPnBr.dll','DLL Script',NULL),(102,'/nmaplowercheck','nmaplowercheck','Misc Script',NULL),(103,'/Portal0000.htm','Portal0000','Misc Script',NULL),(104,'/inicio.shtml','inicio.shtml','Misc Script',NULL),(105,'/HNAP1','HNAP1','Misc Script',NULL),(106,'/__Additional','__Additional','Misc Script',NULL),(107,'/pools/default/buckets','buckets','Misc Script',NULL),(108,'/inicio.asp','inicio.asp','Misc Script',NULL),(109,'/menu.jsa','menu.jsa','Misc Script',NULL),(110,'/main.asp','main.asp','Misc Script',NULL),(111,'/default.cfm','default.cfm','Misc Script',NULL),(112,'/base.jhtml','base.jhtml','Misc Script',NULL),(113,'/default.asp','default.asp','Misc Script',NULL),(114,'/admin.php','admin.php','Misc Script',NULL),(115,'/admin.jsp','admin.jsp','Misc Script',NULL),(116,'/localstart.jsp','localstart.jsp','Misc Script',NULL),(117,'/start.jsp','start.jsp','Misc Script',NULL),(118,'/start.php','start.php','Misc Script',NULL),(119,'/admin.jsa','admin.jsa','Misc Script',NULL),(120,'/indice.jsa','indice.jsa','Misc Script',NULL),(121,'/inicio.jsa','inicio.jsa','Misc Script',NULL),(122,'/main.php','main.php','PHP Script',NULL),(123,'/default.cgi','default.cgi','CGI Script',NULL),(124,'/start.jsa','start.jsa','Misc Script',NULL),(125,'/admin.cfm','admin.cfm','Misc Script',NULL),(126,'/start.shtml','start.shtml','Misc Script',NULL),(127,'/indice.aspx','indice.aspx','Misc Script',NULL),(128,'/localstart.jhtml','localstart.jhtml','Misc Script',NULL),(129,'/admin/assets/fileupload/index.php','fileupload','PHP Script',NULL),(130,'27;wget','wget','Misc Script',NULL),(131,'/wp-content/plugins/mstore-api/assets/js/mstore-inspireui.js','mstore-api','WordPress',NULL),(133,'/.remote','.remote','Config File',NULL),(134,'/.local','.local','Config File',NULL),(135,'/.production','.production','Config File',NULL),(136,'/canadapost','canadapost','Misc Script',NULL),(137,'.exe','EXE','Misc Script',NULL);
UNLOCK TABLES;

CREATE TABLE `found_block_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` text DEFAULT NULL,
  `ip` text DEFAULT NULL,
  `category` text DEFAULT NULL,
  `pattern` text DEFAULT NULL,
  `created_at` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `log` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `migration` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

LOCK TABLES `migrations` WRITE;
INSERT INTO `migrations` VALUES (1,20230616),(2,20230616),(3,20230616),(4,20230616),(5,20230622),(6,20230701),(7,20230701),(8,20230701),(9,20230701),(10,20230701),(11,20230701),(12,20230701),(13,20230701),(14,20230701),(15,20230710),(16,20230710),(17,20230710),(18,20230710),(19,20230711);
UNLOCK TABLES;

CREATE TABLE `settings` (
  `ip_lookup` int(11) NOT NULL DEFAULT 1,
  `service_lookup` int(11) NOT NULL DEFAULT 1,
  `firewall_command` text NOT NULL,
  `firewall_cfg_folder` text NOT NULL,
  `firewall_cfg_file_v4` text NOT NULL,
  `cron_folder` text NOT NULL,
  `cron_running` int(11) NOT NULL DEFAULT 0,
  `webuser` text NOT NULL DEFAULT 'www-data',
  `firewall_cfg_file_v6` text NOT NULL,
  `firewall_command_v6` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

LOCK TABLES `settings` WRITE;
INSERT INTO `settings` VALUES (1,1,'/usr/sbin/iptables','/etc/iptables/','rules.v4','/var/www/janus/cron',0,'www-data','rules.v6','/usr/sbin/ip6tables');
UNLOCK TABLES;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `password` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

LOCK TABLES `users` WRITE;
INSERT INTO `users` VALUES (1,'janus','$2y$10$PFfxOR5xcEECPSG1T.2HBuumzC.oy.VVJ8PLE6lviBiY9PZIrfpwG');
UNLOCK TABLES;

CREATE TABLE `watchlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` text DEFAULT NULL,
  `created_at` text DEFAULT NULL,
  `country` text DEFAULT NULL,
  `service` text DEFAULT NULL,
  `whois` text DEFAULT NULL,
  `note` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `watchlist_log_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` text DEFAULT NULL,
  `log_id` int(11) DEFAULT NULL,
  `log_line` text DEFAULT NULL,
  `created_at` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `whitelist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` text DEFAULT NULL,
  `country` text DEFAULT NULL,
  `service` text DEFAULT NULL,
  `whois` text DEFAULT NULL,
  `created_at` text DEFAULT NULL,
  `ipvsix` int(11) DEFAULT 0,
  `note` text DEFAULT NULL,
  `label` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;