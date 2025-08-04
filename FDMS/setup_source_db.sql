-- This script sets up the source database with sample data
-- To run this script: psql -d fdms_source -f setup_source_db.sql

-- Step 1: Create departments table to store department information
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,  -- Auto-incrementing unique identifier
    department_name VARCHAR(100) NOT NULL  -- Department name (required)
);

-- Step 2: Create employees table to store employee information
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,  -- Auto-incrementing unique identifier
    first_name VARCHAR(50) NOT NULL,  -- Employee's first name (required)
    last_name VARCHAR(50) NOT NULL,   -- Employee's last name (required)
    email VARCHAR(100) NOT NULL UNIQUE,  -- Unique email address (required)
    department_id INTEGER REFERENCES departments(department_id)  -- Links to departments table
);

-- Step 3: Create employee_documents table to store document information
CREATE TABLE employee_documents (
    document_id SERIAL PRIMARY KEY,  -- Auto-incrementing unique identifier
    employee_id INTEGER REFERENCES employees(employee_id),  -- Links to employees table
    document_type VARCHAR(50) NOT NULL,  -- Type of document (required)
    file_path VARCHAR(255) NOT NULL,  -- Path to document file (required)
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When document was uploaded
);

-- Step 4: Insert sample department data
INSERT INTO departments (department_name) VALUES 
    ('HR'),
    ('Engineering'),
    ('Finance');

-- Step 5: Insert sample employee data
INSERT INTO employees (first_name, last_name, email, department_id) VALUES 
    ('John', 'Doe', 'john.doe@example.com', 1),
    ('Jane', 'Smith', 'jane.smith@example.com', 2),
    ('Bob', 'Johnson', 'bob.johnson@example.com', 3);

-- Step 6: Insert sample document data
INSERT INTO employee_documents (employee_id, document_type, file_path) VALUES 
    (1, 'PASSPORT', '/tmp/docs/passport_1.pdf'),
    (1, 'CONTRACT', '/tmp/docs/contract_1.pdf'),
    (2, 'VISA', '/tmp/docs/visa_2.pdf'),
    (2, 'PAYSLIP', '/tmp/docs/payslip_2.pdf'),
    (3, 'CONTRACT', '/tmp/docs/contract_3.pdf');

-- Note: This table is for reference only, not used in the source database
CREATE TABLE document_metadata (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_category VARCHAR(50) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    upload_date TIMESTAMP NOT NULL,
    processed_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    document_id VARCHAR(100) NOT NULL UNIQUE,
    s3_path VARCHAR(255)
);

# Step 1: Create SQLAlchemy engine for source database
source_engine = create_engine('postgresql://espinshalo@localhost:5432/fdms_source')

# Step 2: Create SQLAlchemy engine for target database
target_engine = create_engine('postgresql://espinshalo@localhost:5432/fdms_target')

print("Database connections established successfully!")

# Step 1: Define SQL query to extract data from source database
query = """
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.email,
    d.department_name,
    doc.document_type,
    doc.file_path,
    doc.upload_date
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employee_documents doc ON e.employee_id = doc.employee_id;
"""

# Step 2: Execute query and load results into DataFrame
df = pd.read_sql(query, source_engine)

# Step 3: Display results
print("Data extracted successfully!")
print(f"Number of records: {len(df)}")
display(df)

# Step 1: Map document types to categories
df['document_category'] = df['document_type'].map({
    'CONTRACT': 'Employment',
    'PASSPORT': 'Identity',
    'VISA': 'Immigration',
    'PAYSLIP': 'Financial'
})

# Step 2: Add processing information
df['processed_date'] = datetime.now()  # Current timestamp
df['status'] = 'ACTIVE'  # Set status to active

# Step 3: Create unique document IDs
df['document_id'] = df.apply(
    lambda x: f"{x['employee_id']}_{x['document_type']}_{x['upload_date'].strftime('%Y%m%d')}", 
    axis=1
)

# Step 4: Display transformed data
print("Data transformed successfully!")
display(df)

# Step 1: Load transformed data into target database
# if_exists='replace' means it will drop the existing table if it exists
df.to_sql('document_metadata', target_engine, if_exists='replace', index=False)

print("Data loaded into target database successfully!")

# Step 1: Query the target database to verify the migration
verification_query = "SELECT * FROM document_metadata;"
result_df = pd.read_sql(verification_query, target_engine)

# Step 2: Display verification results
print("Data verification completed!")
print(f"Number of records in target database: {len(result_df)}")
display(result_df) 