-- This script sets up the target database schema
-- To run this script: psql -d fdms_target -f setup_target_db.sql

-- Step 1: Drop existing document_metadata table if it exists
-- This ensures we start with a clean slate
DROP TABLE IF EXISTS document_metadata;

-- Step 2: Create the document_metadata table
-- This table will store the denormalized data from the source database
CREATE TABLE document_metadata (
    id SERIAL PRIMARY KEY,  -- Auto-incrementing unique identifier
    employee_id INTEGER NOT NULL,  -- Employee ID from source database
    first_name VARCHAR(50) NOT NULL,  -- Employee's first name
    last_name VARCHAR(50) NOT NULL,  -- Employee's last name
    email VARCHAR(100) NOT NULL,  -- Employee's email address
    department_name VARCHAR(100) NOT NULL,  -- Department name from departments table
    document_type VARCHAR(50) NOT NULL,  -- Type of document
    document_category VARCHAR(50) NOT NULL,  -- Categorized document type (e.g., Employment, Identity)
    file_path VARCHAR(255) NOT NULL,  -- Path to document file
    upload_date TIMESTAMP NOT NULL,  -- When document was uploaded
    processed_date TIMESTAMP NOT NULL,  -- When document was processed
    status VARCHAR(20) NOT NULL,  -- Document status (e.g., ACTIVE)
    document_id VARCHAR(100) NOT NULL UNIQUE,  -- Unique document identifier
    s3_path VARCHAR(255)  -- Optional S3 storage path
); 