# Import required libraries
import pandas as pd
from sqlalchemy import create_engine
import psycopg2
import boto3
from datetime import datetime
import os

print("Successfully imported all required libraries")

# Database setup and connection test
def setup_databases():
    try:
        # Connect to default PostgreSQL database
        conn = psycopg2.connect(
            dbname='postgres',
            user='espinshalo',
            host='localhost',
            port='5432'
        )
        conn.autocommit = True
        cur = conn.cursor()
        
        # Create source database if it doesn't exist
        cur.execute("SELECT 1 FROM pg_database WHERE datname = 'fdms_source'")
        if not cur.fetchone():
            cur.execute('CREATE DATABASE fdms_source')
            print("Created source database")
        
        # Create target database if it doesn't exist
        cur.execute("SELECT 1 FROM pg_database WHERE datname = 'fdms_target'")
        if not cur.fetchone():
            cur.execute('CREATE DATABASE fdms_target')
            print("Created target database")
        
        cur.close()
        conn.close()
        print("Database setup completed successfully")
        
    except Exception as e:
        print(f"Error during database setup: {str(e)}")

# Test database connections
def test_connections():
    try:
        # Test source database connection
        source_conn = psycopg2.connect(
            dbname='fdms_source',
            user='espinshalo',
            host='localhost',
            port='5432'
        )
        print("Successfully connected to source database")
        
        # Test target database connection
        target_conn = psycopg2.connect(
            dbname='fdms_target',
            user='espinshalo',
            host='localhost',
            port='5432'
        )
        print("Successfully connected to target database")
        
        # Close connections
        source_conn.close()
        target_conn.close()
        print("All connections closed successfully")
        
    except Exception as e:
        print(f"Error during connection test: {str(e)}")

# Extract data from source database
def extract_data():
    try:
        # Create SQLAlchemy engine for source database
        source_engine = create_engine('postgresql://espinshalo@localhost:5432/fdms_source')
        
        # Extract data from each table
        departments_df = pd.read_sql('SELECT * FROM departments', source_engine)
        print(f"Extracted {len(departments_df)} departments")
        
        document_metadata_df = pd.read_sql('SELECT * FROM document_metadata', source_engine)
        print(f"Extracted {len(document_metadata_df)} document metadata records")
        
        employee_documents_df = pd.read_sql('SELECT * FROM employee_documents', source_engine)
        print(f"Extracted {len(employee_documents_df)} employee documents")
        
        return departments_df, document_metadata_df, employee_documents_df
        
    except Exception as e:
        print(f"Error during data extraction: {str(e)}")
        return None, None, None

# Transform data and generate S3 paths
def transform_data(departments_df, document_metadata_df, employee_documents_df):
    try:
        # Merge dataframes
        merged_df = pd.merge(
            employee_documents_df,
            document_metadata_df,
            on='document_id',
            how='left'
        )
        
        merged_df = pd.merge(
            merged_df,
            departments_df,
            on='department_id',
            how='left'
        )
        
        # Generate S3 paths
        merged_df['s3_path'] = merged_df.apply(
            lambda row: f"s3://fdms-documents/{row['department_name']}/{row['document_type']}/{row['document_id']}.pdf",
            axis=1
        )
        
        print(f"Transformed {len(merged_df)} records")
        return merged_df
        
    except Exception as e:
        print(f"Error during data transformation: {str(e)}")
        return None

# Load data into target database
def load_data(transformed_df):
    try:
        # Create SQLAlchemy engine for target database
        target_engine = create_engine('postgresql://espinshalo@localhost:5432/fdms_target')
        
        # Load transformed data
        transformed_df.to_sql('migrated_documents', target_engine, if_exists='replace', index=False)
        print(f"Loaded {len(transformed_df)} records into target database")
        
    except Exception as e:
        print(f"Error during data loading: {str(e)}")

# Verify data migration
def verify_migration():
    try:
        # Create SQLAlchemy engine for target database
        target_engine = create_engine('postgresql://espinshalo@localhost:5432/fdms_target')
        
        # Read migrated data
        migrated_df = pd.read_sql('SELECT * FROM migrated_documents', target_engine)
        
        # Print verification statistics
        print(f"Total records migrated: {len(migrated_df)}")
        print(f"Unique departments: {migrated_df['department_name'].nunique()}")
        print(f"Unique document types: {migrated_df['document_type'].nunique()}")
        
    except Exception as e:
        print(f"Error during verification: {str(e)}")

# Simulate S3 uploads
def simulate_s3_uploads(transformed_df):
    try:
        # Create S3 client
        s3_client = boto3.client('s3')
        
        # Simulate upload for each document
        for _, row in transformed_df.iterrows():
            print(f"Simulating upload for document {row['document_id']} to {row['s3_path']}")
            
    except Exception as e:
        print(f"Error during S3 simulation: {str(e)}")

# Main execution
if __name__ == "__main__":
    # Run database setup
    setup_databases()
    
    # Test connections
    test_connections()
    
    # Extract data
    departments_df, document_metadata_df, employee_documents_df = extract_data()
    
    # Transform data
    transformed_df = transform_data(departments_df, document_metadata_df, employee_documents_df)
    
    # Load data
    load_data(transformed_df)
    
    # Verify migration
    verify_migration()
    
    # Simulate S3 uploads
    simulate_s3_uploads(transformed_df) 