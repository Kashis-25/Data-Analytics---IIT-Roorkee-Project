SELECT job, AVG(balance) AS avg_balance
FROM clients
GROUP BY job
ORDER BY avg_balance DESC
LIMIT 1;
SELECT education, COUNT(DISTINCT campaign) AS num_campaigns
FROM clients
GROUP BY education
ORDER BY num_campaigns DESC;
CREATE VIEW campaign_success_rate AS
SELECT c.campaign, 
       COUNT(DISTINCT CASE WHEN c.y = 'yes' THEN c.id END) AS success_count,
       COUNT(c.id) AS total_count,
       (COUNT(DISTINCT CASE WHEN c.y = 'yes' THEN c.id END) / COUNT(c.id)) AS success_rate
FROM clients c
GROUP BY c.campaign;
CREATE VIEW client_summary AS
SELECT id, 
       job, 
       marital, 
       education, 
       balance, 
       COUNT(DISTINCT loan) AS num_loans,
       COUNT(DISTINCT contact) AS num_contacts
FROM clients
GROUP BY id;
CREATE VIEW campaign_performance_by_month AS
SELECT EXTRACT(MONTH FROM date) AS campaign_month, 
       COUNT(campaign) AS total_contacts, 
       COUNT(CASE WHEN y = 'yes' THEN 1 END) AS success_count,
       (COUNT(CASE WHEN y = 'yes' THEN 1 END) / COUNT(campaign)) AS success_rate
FROM clients
GROUP BY EXTRACT(MONTH FROM date)
ORDER BY campaign_month;
-- Create index on age column
CREATE INDEX idx_age ON clients(age);

-- Create index on job column
CREATE INDEX idx_job ON clients(job);

-- Create index on marital status column
CREATE INDEX idx_marital ON clients(marital);
DELIMITER $$

CREATE PROCEDURE update_balance()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE client_id INT;
    DECLARE transaction_amt DECIMAL(10, 2);
    DECLARE balance_cursor CURSOR FOR 
        SELECT client_id, SUM(transaction_amount)
        FROM transactions
        GROUP BY client_id;
    
    -- Declare CONTINUE HANDLER for when no more rows are available
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN balance_cursor;
    
    -- Loop through each client and update their balance
    read_loop: LOOP
        FETCH balance_cursor INTO client_id, transaction_amt;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Update balance for each client
        UPDATE clients
        SET balance = balance + transaction_amt
        WHERE id = client_id;
    END LOOP;
    
    CLOSE balance_cursor;
END $$

DELIMITER ;
