
-- =====================================================

-- 유지보수 계약 갱신 알림 시스템 - 데이터베이스 스키마

-- =====================================================



-- 1. 계약 테이블에 알림 관련 컬럼 추가

ALTER TABLE contracts 

ADD COLUMN IF NOT EXISTS last_notification_date TIMESTAMP,

ADD COLUMN IF NOT EXISTS last_notification_stage VARCHAR(10),

ADD COLUMN IF NOT EXISTS notification_count INT DEFAULT 0,

ADD COLUMN IF NOT EXISTS renewal_probability DECIMAL(5,2) DEFAULT 70.0,

ADD COLUMN IF NOT EXISTS sales_rep_email VARCHAR(255),

ADD COLUMN IF NOT EXISTS sales_rep_phone VARCHAR(20),

ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255),

ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(20),

ADD COLUMN IF NOT EXISTS renewal_status VARCHAR(20) DEFAULT 'pending';



-- 2. 알림 이력 테이블 생성

CREATE TABLE IF NOT EXISTS notification_logs (

    log_id SERIAL PRIMARY KEY,

    contract_id INT NOT NULL,

    contract_number VARCHAR(50),

    customer_name VARCHAR(255),

    notification_type VARCHAR(50) NOT NULL DEFAULT 'renewal_reminder',

    alert_stage VARCHAR(10) NOT NULL,

    urgency_level VARCHAR(20),

    priority INT DEFAULT 0,

    sent_at TIMESTAMP DEFAULT NOW(),

    recipient_name VARCHAR(255),

    recipient_email VARCHAR(255),

    recipient_phone VARCHAR(20),

    email_status VARCHAR(20) DEFAULT 'pending',

    email_sent_at TIMESTAMP,

    sms_status VARCHAR(20) DEFAULT 'pending',

    sms_sent_at TIMESTAMP,

    slack_status VARCHAR(20) DEFAULT 'pending',

    slack_sent_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),

    updated_at TIMESTAMP DEFAULT NOW()

);



-- 3. 인덱스 생성

CREATE INDEX IF NOT EXISTS idx_contracts_end_date ON contracts(end_date) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_notification_logs_contract_id ON notification_logs(contract_id);

CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at DESC);



SELECT 'Database schema created successfully!' AS status;

