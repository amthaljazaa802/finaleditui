"""
Enhanced SQL Server Connection Test for Bus Tracking System

This script tests the database connection to ensure SQL Server is properly configured.
Run this before starting the Django server to catch any configuration issues early.

Usage:
    python test_sql_connection_enhanced.py
"""

import os
import sys
from pathlib import Path

# Add the project directory to Python path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')

try:
    import django
    django.setup()
except Exception as e:
    print(f"❌ Error setting up Django: {e}")
    sys.exit(1)

from django.db import connection
from django.core.exceptions import ImproperlyConfigured
import pyodbc

def test_pyodbc_drivers():
    """Check if ODBC drivers are installed."""
    print("\n" + "="*60)
    print("Step 1: Checking ODBC Drivers")
    print("="*60)
    
    drivers = [driver for driver in pyodbc.drivers() if 'SQL Server' in driver]
    
    if drivers:
        print("✅ ODBC Drivers found:")
        for driver in drivers:
            print(f"   - {driver}")
        return True
    else:
        print("❌ No SQL Server ODBC drivers found!")
        print("\n📥 Please install ODBC Driver 17 or 18 for SQL Server:")
        print("   https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server")
        return False

def test_settings():
    """Check Django database settings."""
    print("\n" + "="*60)
    print("Step 2: Checking Django Settings")
    print("="*60)
    
    from django.conf import settings
    
    db_config = settings.DATABASES['default']
    
    print(f"Database Engine: {db_config.get('ENGINE')}")
    print(f"Database Name: {db_config.get('NAME')}")
    print(f"Host: {db_config.get('HOST')}")
    print(f"User: {db_config.get('USER') or '(Windows Authentication)'}")
    
    if db_config.get('ENGINE') != 'mssql':
        print("❌ Database engine is not set to 'mssql'")
        print("   Check your .env file: DB_ENGINE=mssql")
        return False
    
    print("✅ Django settings look correct")
    return True

def test_connection():
    """Test actual database connection."""
    print("\n" + "="*60)
    print("Step 3: Testing Database Connection")
    print("="*60)
    
    try:
        # Try to connect
        with connection.cursor() as cursor:
            cursor.execute("SELECT @@VERSION")
            version = cursor.fetchone()[0]
            
        print("✅ Successfully connected to SQL Server!")
        print(f"\nSQL Server Version:")
        print(f"   {version[:100]}...")
        return True
        
    except pyodbc.OperationalError as e:
        error_msg = str(e)
        print(f"❌ Connection failed: {error_msg}")
        
        if "Login failed" in error_msg:
            print("\n💡 Troubleshooting:")
            print("   - Check username/password in .env file")
            print("   - For Windows Auth, leave DB_USER and DB_PASSWORD empty")
            print("   - Make sure your Windows account has SQL Server access")
            
        elif "Cannot open database" in error_msg:
            print("\n💡 Database doesn't exist. Create it:")
            print("   sqlcmd -S localhost\\SQLEXPRESS -E -Q \"CREATE DATABASE BusTrackingDB;\"")
            
        elif "Server not found" in error_msg or "No connection" in error_msg:
            print("\n💡 Cannot reach SQL Server:")
            print("   1. Check SQL Server is running:")
            print("      Get-Service -Name \"MSSQL$SQLEXPRESS\"")
            print("   2. Enable TCP/IP in SQL Server Configuration Manager")
            print("   3. Restart SQL Server service")
            
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def test_database_exists():
    """Check if the database exists."""
    print("\n" + "="*60)
    print("Step 4: Checking Database Exists")
    print("="*60)
    
    try:
        from django.conf import settings
        db_name = settings.DATABASES['default']['NAME']
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT COUNT(*) 
                FROM sys.databases 
                WHERE name = %s
            """, [db_name])
            exists = cursor.fetchone()[0] > 0
            
        if exists:
            print(f"✅ Database '{db_name}' exists")
            return True
        else:
            print(f"❌ Database '{db_name}' does not exist")
            print("\n💡 Create the database:")
            print(f"   sqlcmd -S localhost\\SQLEXPRESS -E -Q \"CREATE DATABASE {db_name};\"")
            return False
            
    except Exception as e:
        print(f"⚠️  Could not verify database: {e}")
        return False

def main():
    """Run all tests."""
    print("\n🔍 SQL Server Connection Test")
    print("="*60)
    
    results = []
    
    # Test 1: ODBC Drivers
    results.append(("ODBC Drivers", test_pyodbc_drivers()))
    
    if not results[-1][1]:
        print("\n❌ Cannot proceed without ODBC drivers. Please install them first.")
        return False
    
    # Test 2: Django Settings
    results.append(("Django Settings", test_settings()))
    
    # Test 3: Connection
    results.append(("Connection", test_connection()))
    
    if results[-1][1]:
        # Test 4: Database exists (only if connection worked)
        results.append(("Database Exists", test_database_exists()))
    
    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    all_passed = all(result[1] for result in results)
    
    if all_passed:
        print("\n✅ All tests passed! Your SQL Server is ready to use.")
        print("\nNext steps:")
        print("   1. python manage.py migrate")
        print("   2. python manage.py createsuperuser")
        print("   3. python manage.py runserver 0.0.0.0:8000")
    else:
        print("\n❌ Some tests failed. Please fix the issues above.")
        print("   See SQL_SERVER_SETUP.md for detailed instructions.")
    
    return all_passed

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
