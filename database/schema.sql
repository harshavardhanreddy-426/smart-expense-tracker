-- ============================================================================
-- Smart Expense Tracker - Production Ready MySQL 8.0+ Schema
-- ============================================================================

CREATE DATABASE IF NOT EXISTS smart_expense_tracker
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_expense_tracker;

-- ============================================================================
-- Table: users
-- Description: Stores user account information and authentication details
-- ============================================================================
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    INDEX idx_email (email),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_currency_length CHECK (LENGTH(currency) = 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: categories
-- Description: Stores expense/income categories with hierarchy support
-- Supports both predefined and custom categories for each user
-- ============================================================================
CREATE TABLE categories (
    category_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    color VARCHAR(7),
    is_predefined BOOLEAN NOT NULL DEFAULT FALSE,
    parent_category_id BIGINT,
    category_type ENUM('EXPENSE', 'INCOME') NOT NULL DEFAULT 'EXPENSE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    UNIQUE KEY uk_user_category_name (user_id, name, is_deleted),
    INDEX idx_user_id (user_id),
    INDEX idx_parent_category_id (parent_category_id),
    INDEX idx_category_type (category_type),
    INDEX idx_is_predefined (is_predefined),
    
    CONSTRAINT fk_categories_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_hex_color CHECK (color IS NULL OR color REGEXP '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT chk_category_not_self_parent CHECK (category_id != parent_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: expenses
-- Description: Stores individual expense transactions with soft delete support
-- Supports receipt attachment via receipt_url field
-- ============================================================================
CREATE TABLE expenses (
    expense_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    expense_date DATE NOT NULL,
    description VARCHAR(500),
    receipt_url VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_expense_date (expense_date),
    INDEX idx_user_date (user_id, expense_date),
    INDEX idx_user_category_date (user_id, category_id, expense_date),
    INDEX idx_is_deleted (is_deleted),
    
    CONSTRAINT fk_expenses_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_expense_date_not_future CHECK (expense_date <= CURDATE())
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: income
-- Description: Stores individual income transactions
-- Records money coming in from various sources (salary, freelance, etc)
-- ============================================================================
CREATE TABLE income (
    income_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    income_date DATE NOT NULL,
    description VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_income_date (income_date),
    INDEX idx_user_date (user_id, income_date),
    INDEX idx_is_deleted (is_deleted),
    
    CONSTRAINT fk_income_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_income_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_income_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_income_date_not_future CHECK (income_date <= CURDATE())
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: budgets
-- Description: Stores monthly budget limits and alert thresholds per category
-- budget_month stores first day of the month for easier calculations
-- Supports dual alert thresholds (e.g., 75% and 90%)
-- ============================================================================
CREATE TABLE budgets (
    budget_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    budget_month DATE NOT NULL,
    limit_amount DECIMAL(12, 2) NOT NULL,
    alert_threshold_1 INT NOT NULL DEFAULT 75,
    alert_threshold_2 INT NOT NULL DEFAULT 90,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    UNIQUE KEY uk_user_category_month (user_id, category_id, budget_month, is_deleted),
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_budget_month (budget_month),
    INDEX idx_user_month (user_id, budget_month),
    INDEX idx_is_deleted (is_deleted),
    
    CONSTRAINT fk_budgets_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_limit_amount_positive CHECK (limit_amount > 0),
    CONSTRAINT chk_alert_threshold_1 CHECK (alert_threshold_1 BETWEEN 1 AND 99),
    CONSTRAINT chk_alert_threshold_2 CHECK (alert_threshold_2 BETWEEN 2 AND 100),
    CONSTRAINT chk_threshold_order CHECK (alert_threshold_1 < alert_threshold_2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: refresh_tokens
-- Description: Stores refresh tokens for JWT authentication
-- Tokens are revoked on logout and checked for expiration
-- Short-lived table - tokens auto-expire based on expires_at timestamp
-- ============================================================================
CREATE TABLE refresh_tokens (
    token_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_token (token),
    INDEX idx_expires_at (expires_at),
    INDEX idx_revoked (revoked),
    
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Create Indexes for Performance Optimization
-- ============================================================================

-- Composite indexes for frequently used query patterns
ALTER TABLE expenses ADD INDEX idx_expense_user_category_date (user_id, category_id, expense_date);
ALTER TABLE income ADD INDEX idx_income_user_category_date (user_id, category_id, income_date);
ALTER TABLE budgets ADD INDEX idx_budget_user_category (user_id, category_id);
ALTER TABLE categories ADD INDEX idx_categories_user_type (user_id, category_type);

-- ============================================================================
-- Create Views for Reporting and Analytics
-- ============================================================================

-- View: User Monthly Expense Summary
-- Provides aggregated expense totals by category per month
CREATE VIEW v_monthly_expense_summary AS
SELECT 
    e.user_id,
    YEAR(e.expense_date) AS year,
    MONTH(e.expense_date) AS month,
    c.category_id,
    c.name AS category_name,
    c.icon,
    c.color,
    COUNT(e.expense_id) AS transaction_count,
    SUM(e.amount) AS total_amount,
    AVG(e.amount) AS average_amount,
    MIN(e.amount) AS minimum_amount,
    MAX(e.amount) AS maximum_amount
FROM expenses e
INNER JOIN categories c ON e.category_id = c.category_id
WHERE e.is_deleted = FALSE
    AND c.is_deleted = FALSE
    AND c.category_type = 'EXPENSE'
GROUP BY e.user_id, YEAR(e.expense_date), MONTH(e.expense_date), c.category_id, c.name, c.icon, c.color;

-- View: User Monthly Income Summary
-- Provides aggregated income totals by category per month
CREATE VIEW v_monthly_income_summary AS
SELECT 
    i.user_id,
    YEAR(i.income_date) AS year,
    MONTH(i.income_date) AS month,
    c.category_id,
    c.name AS category_name,
    c.icon,
    c.color,
    COUNT(i.income_id) AS transaction_count,
    SUM(i.amount) AS total_amount,
    AVG(i.amount) AS average_amount,
    MIN(i.amount) AS minimum_amount,
    MAX(i.amount) AS maximum_amount
FROM income i
INNER JOIN categories c ON i.category_id = c.category_id
WHERE i.is_deleted = FALSE
    AND c.is_deleted = FALSE
    AND c.category_type = 'INCOME'
GROUP BY i.user_id, YEAR(i.income_date), MONTH(i.income_date), c.category_id, c.name, c.icon, c.color;

-- View: Budget vs Actual Comparison
-- Compares budget limits with actual spending for analysis
CREATE VIEW v_budget_vs_actual AS
SELECT 
    b.budget_id,
    b.user_id,
    b.category_id,
    c.name AS category_name,
    c.icon,
    c.color,
    YEAR(b.budget_month) AS year,
    MONTH(b.budget_month) AS month,
    b.limit_amount,
    COALESCE(SUM(e.amount), 0) AS actual_amount,
    (b.limit_amount - COALESCE(SUM(e.amount), 0)) AS remaining_amount,
    ROUND((COALESCE(SUM(e.amount), 0) / b.limit_amount) * 100, 2) AS percentage_used,
    CASE 
        WHEN COALESCE(SUM(e.amount), 0) >= b.limit_amount THEN 'EXCEEDED'
        WHEN COALESCE(SUM(e.amount), 0) >= (b.limit_amount * b.alert_threshold_2 / 100) THEN 'WARNING_2'
        WHEN COALESCE(SUM(e.amount), 0) >= (b.limit_amount * b.alert_threshold_1 / 100) THEN 'WARNING_1'
        ELSE 'OK'
    END AS alert_status
FROM budgets b
LEFT JOIN expenses e ON b.user_id = e.user_id
    AND b.category_id = e.category_id
    AND YEAR(e.expense_date) = YEAR(b.budget_month)
    AND MONTH(e.expense_date) = MONTH(b.budget_month)
    AND e.is_deleted = FALSE
INNER JOIN categories c ON b.category_id = c.category_id
WHERE b.is_deleted = FALSE
    AND c.is_deleted = FALSE
GROUP BY b.budget_id, b.user_id, b.category_id, c.name, c.icon, c.color, 
         YEAR(b.budget_month), MONTH(b.budget_month), b.limit_amount, 
         b.alert_threshold_1, b.alert_threshold_2;

-- View: Daily Spending Summary
-- Provides daily expense aggregation for trend analysis
CREATE VIEW v_daily_spending_summary AS
SELECT 
    e.user_id,
    e.expense_date,
    DAYNAME(e.expense_date) AS day_name,
    COUNT(e.expense_id) AS transaction_count,
    SUM(e.amount) AS daily_total,
    AVG(e.amount) AS daily_average,
    MIN(e.amount) AS daily_minimum,
    MAX(e.amount) AS daily_maximum
FROM expenses e
WHERE e.is_deleted = FALSE
GROUP BY e.user_id, e.expense_date, DAYNAME(e.expense_date);

-- View: User Financial Summary
-- Provides high-level financial overview for dashboard
CREATE VIEW v_user_financial_summary AS
SELECT 
    u.user_id,
    u.email,
    u.full_name,
    u.currency,
    YEAR(CURDATE()) AS current_year,
    MONTH(CURDATE()) AS current_month,
    (SELECT COALESCE(SUM(amount), 0) FROM expenses 
     WHERE user_id = u.user_id 
       AND YEAR(expense_date) = YEAR(CURDATE())
       AND MONTH(expense_date) = MONTH(CURDATE())
       AND is_deleted = FALSE) AS mtd_expenses,
    (SELECT COALESCE(SUM(amount), 0) FROM income 
     WHERE user_id = u.user_id 
       AND YEAR(income_date) = YEAR(CURDATE())
       AND MONTH(income_date) = MONTH(CURDATE())
       AND is_deleted = FALSE) AS mtd_income,
    (SELECT COALESCE(SUM(amount), 0) FROM expenses 
     WHERE user_id = u.user_id 
       AND YEAR(expense_date) = YEAR(CURDATE())
       AND is_deleted = FALSE) AS ytd_expenses,
    (SELECT COALESCE(SUM(amount), 0) FROM income 
     WHERE user_id = u.user_id 
       AND YEAR(income_date) = YEAR(CURDATE())
       AND is_deleted = FALSE) AS ytd_income
FROM users u
WHERE u.is_deleted = FALSE;

-- ============================================================================
-- Stored Procedures for Common Operations
-- ============================================================================

-- Procedure: Get Monthly Expense Summary by Category
DELIMITER //
CREATE PROCEDURE sp_get_monthly_expense_summary(
    IN p_user_id BIGINT,
    IN p_year INT,
    IN p_month INT
)
READS SQL DATA
BEGIN
    SELECT 
        c.category_id,
        c.name AS category_name,
        c.icon,
        c.color,
        COUNT(e.expense_id) AS transaction_count,
        SUM(e.amount) AS total_amount,
        AVG(e.amount) AS average_amount,
        MIN(e.amount) AS minimum_amount,
        MAX(e.amount) AS maximum_amount
    FROM expenses e
    INNER JOIN categories c ON e.category_id = c.category_id
    WHERE e.user_id = p_user_id
        AND YEAR(e.expense_date) = p_year
        AND MONTH(e.expense_date) = p_month
        AND e.is_deleted = FALSE
        AND c.is_deleted = FALSE
    GROUP BY c.category_id, c.name, c.icon, c.color
    ORDER BY total_amount DESC;
END //
DELIMITER ;

-- Procedure: Get Budget Alerts for Current Month
DELIMITER //
CREATE PROCEDURE sp_check_budget_alerts(
    IN p_user_id BIGINT,
    IN p_year INT,
    IN p_month INT
)
READS SQL DATA
BEGIN
    SELECT 
        b.budget_id,
        b.category_id,
        c.name AS category_name,
        b.limit_amount,
        COALESCE(SUM(e.amount), 0) AS spent_amount,
        (b.limit_amount - COALESCE(SUM(e.amount), 0)) AS remaining_amount,
        ROUND((COALESCE(SUM(e.amount), 0) / b.limit_amount) * 100, 2) AS spent_percentage,
        b.alert_threshold_1,
        b.alert_threshold_2,
        CASE 
            WHEN COALESCE(SUM(e.amount), 0) >= b.limit_amount THEN 'EXCEEDED'
            WHEN COALESCE(SUM(e.amount), 0) >= (b.limit_amount * b.alert_threshold_2 / 100) THEN 'WARNING_2'
            WHEN COALESCE(SUM(e.amount), 0) >= (b.limit_amount * b.alert_threshold_1 / 100) THEN 'WARNING_1'
            ELSE 'OK'
        END AS alert_status
    FROM budgets b
    LEFT JOIN expenses e ON b.user_id = e.user_id
        AND b.category_id = e.category_id
        AND YEAR(e.expense_date) = p_year
        AND MONTH(e.expense_date) = p_month
        AND e.is_deleted = FALSE
    INNER JOIN categories c ON b.category_id = c.category_id
    WHERE b.user_id = p_user_id
        AND YEAR(b.budget_month) = p_year
        AND MONTH(b.budget_month) = p_month
        AND b.is_deleted = FALSE
    GROUP BY b.budget_id, b.category_id, c.name, b.limit_amount, b.alert_threshold_1, b.alert_threshold_2
    ORDER BY spent_percentage DESC;
END //
DELIMITER ;

-- Procedure: Get Spending Trends
DELIMITER //
CREATE PROCEDURE sp_get_spending_trends(
    IN p_user_id BIGINT,
    IN p_months INT
)
READS SQL DATA
BEGIN
    SELECT 
        DATE(CONCAT(YEAR(e.expense_date), '-', LPAD(MONTH(e.expense_date), 2, '0'), '-01')) AS month_date,
        YEAR(e.expense_date) AS year,
        MONTH(e.expense_date) AS month,
        c.category_id,
        c.name AS category_name,
        COUNT(e.expense_id) AS transaction_count,
        SUM(e.amount) AS total_amount,
        AVG(e.amount) AS average_amount
    FROM expenses e
    INNER JOIN categories c ON e.category_id = c.category_id
    WHERE e.user_id = p_user_id
        AND e.expense_date >= DATE_SUB(CURDATE(), INTERVAL p_months MONTH)
        AND e.is_deleted = FALSE
        AND c.is_deleted = FALSE
    GROUP BY DATE(CONCAT(YEAR(e.expense_date), '-', LPAD(MONTH(e.expense_date), 2, '0'), '-01')),
             YEAR(e.expense_date), MONTH(e.expense_date), c.category_id, c.name
    ORDER BY year DESC, month DESC, total_amount DESC;
END //
DELIMITER ;

-- Procedure: Clean Up Expired Refresh Tokens
DELIMITER //
CREATE PROCEDURE sp_cleanup_expired_tokens()
MODIFIES SQL DATA
BEGIN
    DELETE FROM refresh_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP 
       OR revoked = TRUE;
    
    SELECT ROW_COUNT() AS deleted_token_count;
END //
DELIMITER ;

-- Procedure: Get User Dashboard Summary
DELIMITER //
CREATE PROCEDURE sp_get_dashboard_summary(IN p_user_id BIGINT)
READS SQL DATA
BEGIN
    SELECT 
        (SELECT COALESCE(SUM(amount), 0) FROM expenses 
         WHERE user_id = p_user_id 
           AND expense_date >= DATE(CONCAT(YEAR(CURDATE()), '-', LPAD(MONTH(CURDATE()), 2, '0'), '-01'))
           AND is_deleted = FALSE) AS mtd_expenses,
        (SELECT COALESCE(SUM(amount), 0) FROM income 
         WHERE user_id = p_user_id 
           AND income_date >= DATE(CONCAT(YEAR(CURDATE()), '-', LPAD(MONTH(CURDATE()), 2, '0'), '-01'))
           AND is_deleted = FALSE) AS mtd_income,
        (SELECT COUNT(*) FROM expenses 
         WHERE user_id = p_user_id 
           AND expense_date = CURDATE()
           AND is_deleted = FALSE) AS today_expense_count,
        (SELECT COALESCE(SUM(amount), 0) FROM expenses 
         WHERE user_id = p_user_id 
           AND expense_date = CURDATE()
           AND is_deleted = FALSE) AS today_expenses,
        (SELECT COUNT(DISTINCT DATE(expense_date)) FROM expenses 
         WHERE user_id = p_user_id 
           AND YEAR(expense_date) = YEAR(CURDATE())
           AND MONTH(expense_date) = MONTH(CURDATE())
           AND is_deleted = FALSE) AS days_with_expenses;
END //
DELIMITER ;

-- ============================================================================
-- Insert Predefined Categories (System Default)
-- These can be automatically assigned to new users
-- ============================================================================
INSERT INTO categories (user_id, name, icon, color, is_predefined, category_type) VALUES
-- Expense Categories
(NULL, 'Food & Dining', '🍔', '#FF6B6B', TRUE, 'EXPENSE'),
(NULL, 'Groceries', '🛒', '#A29BFE', TRUE, 'EXPENSE'),
(NULL, 'Transportation', '🚗', '#4ECDC4', TRUE, 'EXPENSE'),
(NULL, 'Fuel', '⛽', '#74B9FF', TRUE, 'EXPENSE'),
(NULL, 'Public Transport', '🚌', '#00B894', TRUE, 'EXPENSE'),
(NULL, 'Utilities', '💡', '#45B7D1', TRUE, 'EXPENSE'),
(NULL, 'Internet', '📡', '#0984E3', TRUE, 'EXPENSE'),
(NULL, 'Mobile Phone', '📱', '#6C5CE7', TRUE, 'EXPENSE'),
(NULL, 'Entertainment', '🎬', '#96CEB4', TRUE, 'EXPENSE'),
(NULL, 'Movies & Shows', '🎥', '#DDA0DD', TRUE, 'EXPENSE'),
(NULL, 'Games', '🎮', '#87CEEB', TRUE, 'EXPENSE'),
(NULL, 'Hobbies', '🎨', '#FFB347', TRUE, 'EXPENSE'),
(NULL, 'Healthcare', '🏥', '#FFEAA7', TRUE, 'EXPENSE'),
(NULL, 'Doctor', '👨‍⚕️', '#FFA07A', TRUE, 'EXPENSE'),
(NULL, 'Medicines', '💊', '#FFD700', TRUE, 'EXPENSE'),
(NULL, 'Shopping', '🛍️', '#DFE6E9', TRUE, 'EXPENSE'),
(NULL, 'Clothing', '👕', '#F1C40F', TRUE, 'EXPENSE'),
(NULL, 'Shoes', '👟', '#E67E22', TRUE, 'EXPENSE'),
(NULL, 'Books', '📚', '#8B4513', TRUE, 'EXPENSE'),
(NULL, 'Travel', '✈️', '#74B9FF', TRUE, 'EXPENSE'),
(NULL, 'Hotel', '🏨', '#FF69B4', TRUE, 'EXPENSE'),
(NULL, 'Subscriptions', '📺', '#00B894', TRUE, 'EXPENSE'),
(NULL, 'Streaming Services', '🎭', '#20B2AA', TRUE, 'EXPENSE'),
(NULL, 'Personal Care', '💄', '#FD79A8', TRUE, 'EXPENSE'),
(NULL, 'Hair Salon', '💇', '#FF1493', TRUE, 'EXPENSE'),
(NULL, 'Gym Membership', '💪', '#1E90FF', TRUE, 'EXPENSE'),
(NULL, 'Insurance', '🛡️', '#696969', TRUE, 'EXPENSE'),
(NULL, 'Rent', '🏠', '#A9A9A9', TRUE, 'EXPENSE'),
(NULL, 'Home Maintenance', '🔨', '#D2691E', TRUE, 'EXPENSE'),
(NULL, 'Pet Care', '🐕', '#CD853F', TRUE, 'EXPENSE'),
(NULL, 'Education', '📖', '#4169E1', TRUE, 'EXPENSE'),
(NULL, 'Courses', '🎓', '#1E90FF', TRUE, 'EXPENSE'),
(NULL, 'Miscellaneous', '❓', '#808080', TRUE, 'EXPENSE'),
-- Income Categories
(NULL, 'Salary', '💼', '#00B894', TRUE, 'INCOME'),
(NULL, 'Freelance', '💻', '#00CEC9', TRUE, 'INCOME'),
(NULL, 'Business', '🏢', '#00B8A9', TRUE, 'INCOME'),
(NULL, 'Investment Returns', '📈', '#6C5CE7', TRUE, 'INCOME'),
(NULL, 'Dividends', '💹', '#0984E3', TRUE, 'INCOME'),
(NULL, 'Gifts Received', '🎁', '#FF7675', TRUE, 'INCOME'),
(NULL, 'Bonus', '🎉', '#FDCB6E', TRUE, 'INCOME'),
(NULL, 'Refund', '↩️', '#55EFC4', TRUE, 'INCOME'),
(NULL, 'Reimbursement', '💰', '#A29BFE', TRUE, 'INCOME'),
(NULL, 'Other Income', '💵', '#FAB1A0', TRUE, 'INCOME');

-- ============================================================================
-- Create Triggers for Audit Trail (Optional but Recommended)
-- ============================================================================

-- Trigger: Ensure budget_month is always first day of month
DELIMITER //
CREATE TRIGGER tr_budget_month_normalize
BEFORE INSERT ON budgets
FOR EACH ROW
BEGIN
    SET NEW.budget_month = DATE(CONCAT(YEAR(NEW.budget_month), '-', LPAD(MONTH(NEW.budget_month), 2, '0'), '-01'));
END //
DELIMITER ;

-- Trigger: Prevent updates to created_at timestamp
DELIMITER //
CREATE TRIGGER tr_prevent_created_at_update_users
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.created_at != OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot modify created_at timestamp';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_prevent_created_at_update_expenses
BEFORE UPDATE ON expenses
FOR EACH ROW
BEGIN
    IF NEW.created_at != OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot modify created_at timestamp';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_prevent_created_at_update_income
BEFORE UPDATE ON income
FOR EACH ROW
BEGIN
    IF NEW.created_at != OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot modify created_at timestamp';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_prevent_created_at_update_budgets
BEFORE UPDATE ON budgets
FOR EACH ROW
BEGIN
    IF NEW.created_at != OLD.created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot modify created_at timestamp';
    END IF;
END //
DELIMITER ;

-- ============================================================================
-- Grant Permissions (Example - Adjust based on your deployment)
-- ============================================================================

-- Create application user (replace password with strong password in production)
CREATE USER IF NOT EXISTS 'expense_app'@'localhost' IDENTIFIED BY 'change_me_in_production';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON smart_expense_tracker.* TO 'expense_app'@'localhost';

-- Create read-only user for analytics/reporting
CREATE USER IF NOT EXISTS 'expense_reader'@'localhost' IDENTIFIED BY 'change_me_in_production';
GRANT SELECT ON smart_expense_tracker.* TO 'expense_reader'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================================
-- End of Schema Definition
-- ============================================================================