#!/bin/bash

docker exec -i mysql_sanitizer mysql -u root -prootpassword <<EOF
USE sanitizer_db;

-- INSERT into job_request
INSERT INTO job_request 
(id, file_content, file_content_content_type, score, status, file_type, request_type, priority, file_name, user_id)
VALUES 
(5, 'ZmlsZSBjb250ZW50', 'text/plain', 0, 'pending', 'txt', 'scan', 1, 'script5.txt', 1);

SELECT * FROM job_request;

-- INSERT into job_execution_report
INSERT INTO job_execution_report
(id, start_time, end_time, execution_node, execution_log, status, job_request_id, user_id)
VALUES
(5, NOW(), NOW(), 'node1', 'script run', 'done', 5, 1);

SELECT * FROM job_execution_report;

-- UPDATE both tables
UPDATE job_request 
SET status = 'completed', score = 10 
WHERE id = 5;

UPDATE job_execution_report 
SET status = 'verified' 
WHERE id = 5;

-- FINAL CHECK
SELECT * FROM job_request;
SELECT * FROM job_execution_report;

EOF
