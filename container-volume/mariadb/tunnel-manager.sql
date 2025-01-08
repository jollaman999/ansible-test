CREATE DATABASE IF NOT EXISTS `tunnel-manager`;

CREATE USER IF NOT EXISTS 'tunnel-manager'@'%' IDENTIFIED BY 'tunnel-manager-pass';

GRANT ALL PRIVILEGES ON `tunnel-manager`.* TO 'tunnel-manager'@'%';

FLUSH PRIVILEGES;
