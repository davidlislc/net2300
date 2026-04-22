-- Initialize multiple databases for different environments
-- This script runs automatically when the MariaDB container starts for the first time
use logdb;
CREATE TABLE IF NOT EXISTS export_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(100) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    status ENUM('pending', 'success', 'error') DEFAULT 'pending',
    output TEXT,
    file_size BIGINT,
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_database_name (database_name),
    INDEX idx_status (status),
    INDEX idx_exported_at (exported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Create QA database
CREATE DATABASE IF NOT EXISTS logdbqa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create Production database
CREATE DATABASE IF NOT EXISTS logdbprod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create users for QA environment
CREATE USER IF NOT EXISTS 'logapp_qa'@'%' IDENTIFIED BY 'logapp_qa123';
GRANT ALL PRIVILEGES ON logdbqa.* TO 'logapp_qa'@'%';

-- Create users for Production environment
CREATE USER IF NOT EXISTS 'logapp_prod'@'%' IDENTIFIED BY 'logapp_prod456';
GRANT ALL PRIVILEGES ON logdbprod.* TO 'logapp_prod'@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

-- Create logs table in QA database
USE logdbqa;

CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message TEXT NOT NULL,
    status ENUM('pending', 'processing', 'done', 'error') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS execution_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_id INT NOT NULL,
    command TEXT NOT NULL,
    status ENUM('success', 'error') NOT NULL,
    exit_code INT,
    output TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (log_id) REFERENCES logs(id) ON DELETE CASCADE,
    INDEX idx_log_id (log_id),
    INDEX idx_executed_at (executed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS export_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(100) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    status ENUM('pending', 'success', 'error') DEFAULT 'pending',
    output TEXT,
    file_size BIGINT,
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_database_name (database_name),
    INDEX idx_status (status),
    INDEX idx_exported_at (exported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create Production database
USE logdbprod;

CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message TEXT NOT NULL,
    status ENUM('pending', 'processing', 'done', 'error') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS execution_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_id INT NOT NULL,
    command TEXT NOT NULL,
    status ENUM('success', 'error') NOT NULL,
    exit_code INT,
    output TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (log_id) REFERENCES logs(id) ON DELETE CASCADE,
    INDEX idx_log_id (log_id),
    INDEX idx_executed_at (executed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS export_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(100) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    status ENUM('pending', 'success', 'error') DEFAULT 'pending',
    output TEXT,
    file_size BIGINT,
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_database_name (database_name),
    INDEX idx_status (status),
    INDEX idx_exported_at (exported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
