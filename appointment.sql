DROP TABLE IF EXISTS `appointment`;
CREATE TABLE `appointment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `app_date` DATETIME DEFAULT NOW(), 
  `description` varchar(256) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `description` (`description`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

