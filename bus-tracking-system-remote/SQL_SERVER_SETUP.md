# SQL Server Setup Guide for Bus Tracking System

## Prerequisites

### 1. Install SQL Server
- Download SQL Server Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
- Choose "Basic" installation
- Note the instance name (usually `SQLEXPRESS`)

### 2. Install ODBC Driver 17 for SQL Server
- Download from: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
- Install the 64-bit version

### 3. Install mssql-django Python Package
```powershell
cd Buses_BACK_END-main
.\venv\Scripts\Activate.ps1
pip install mssql-django pyodbc
```

---

## Step 1: Verify SQL Server is Running

### Check SQL Server Service
```powershell
# Open Services
services.msc
```
Look for **SQL Server (SQLEXPRESS)** and make sure it's **Running**.

Or use PowerShell:
```powershell
Get-Service -Name "MSSQL`$SQLEXPRESS"
```

If not running, start it:
```powershell
Start-Service -Name "MSSQL`$SQLEXPRESS"
```

---

## Step 2: Enable TCP/IP (Important!)

### Using SQL Server Configuration Manager:

1. Open **SQL Server Configuration Manager**
2. Navigate to: **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Right-click on **TCP/IP** → **Enable**
4. Restart SQL Server service:
   ```powershell
   Restart-Service -Name "MSSQL`$SQLEXPRESS"
   ```

---

## Step 3: Create Database

### Option A: Using SQL Server Management Studio (SSMS)

1. Download SSMS: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
2. Connect to: `localhost\SQLEXPRESS` (Windows Authentication)
3. Right-click **Databases** → **New Database**
4. Database name: `BusTrackingDB`
5. Click **OK**

### Option B: Using sqlcmd (Command Line)

```powershell
# Connect to SQL Server
sqlcmd -S localhost\SQLEXPRESS -E

# Create database
CREATE DATABASE BusTrackingDB;
GO

# Verify
SELECT name FROM sys.databases WHERE name = 'BusTrackingDB';
GO

# Exit
EXIT
```

---

## Step 4: Configure Authentication

### Option 1: Windows Authentication (Recommended for Local Dev)

The `.env` file is already configured for Windows Authentication:
```env
DB_ENGINE=mssql
DB_NAME=BusTrackingDB
DB_HOST=localhost\SQLEXPRESS
DB_USER=
DB_PASSWORD=
```

**This uses your Windows account** - no username/password needed!

### Option 2: SQL Server Authentication

If you prefer SQL Server authentication:

1. **Enable Mixed Mode Authentication:**
   - Open SQL Server Configuration Manager
   - Right-click server → Properties
   - Security → Select "SQL Server and Windows Authentication mode"
   - Restart SQL Server

2. **Create SQL Login:**
   ```sql
   -- Connect with Windows Auth first
   sqlcmd -S localhost\SQLEXPRESS -E
   
   -- Create login
   CREATE LOGIN bus_admin WITH PASSWORD = 'YourStrongPassword123!';
   GO
   
   -- Grant permissions
   USE BusTrackingDB;
   GO
   CREATE USER bus_admin FOR LOGIN bus_admin;
   GO
   ALTER ROLE db_owner ADD MEMBER bus_admin;
   GO
   ```

3. **Update `.env`:**
   ```env
   DB_ENGINE=mssql
   DB_NAME=BusTrackingDB
   DB_HOST=localhost\SQLEXPRESS
   DB_USER=bus_admin
   DB_PASSWORD=YourStrongPassword123!
   ```

---

## Step 5: Test Connection

### Test with Python
```powershell
cd Buses_BACK_END-main
.\venv\Scripts\Activate.ps1
python test_sql_connection.py
```

### Test with Django
```powershell
python manage.py check --database default
```

If you see "System check identified no issues" → **Success!** ✅

---

## Step 6: Run Migrations

```powershell
# Create migration files
python manage.py makemigrations

# Apply migrations to SQL Server
python manage.py migrate
```

You should see output like:
```
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying bus_tracking.0001_initial... OK
  ...
```

---

## Step 7: Create Superuser

```powershell
python manage.py createsuperuser
```

Enter username, email, and password when prompted.

---

## Step 8: Start Server

```powershell
python manage.py runserver 0.0.0.0:8000
```

Visit http://127.0.0.1:8000/admin to verify everything works!

---

## Troubleshooting

### Error: "No module named 'mssql'"
```powershell
pip install mssql-django pyodbc
```

### Error: "Unable to open the physical file"
- Make sure SQL Server service is running
- Check database name is correct

### Error: "Login failed for user"
- Verify credentials in `.env`
- For Windows Auth, leave DB_USER and DB_PASSWORD empty
- Make sure your Windows account has access to SQL Server

### Error: "Cannot open database requested by the login"
- Database doesn't exist yet
- Run: `sqlcmd -S localhost\SQLEXPRESS -E -Q "CREATE DATABASE BusTrackingDB;"`

### Error: "Driver not found: ODBC Driver 17"
- Install ODBC Driver 17 from Microsoft website
- Or change driver in settings.py to 'ODBC Driver 18 for SQL Server'

### Error: "TCP Provider: No connection could be made"
- SQL Server is not running
- TCP/IP is not enabled
- Firewall is blocking connection

---

## Verify Database Tables

After migrations, check if tables were created:

```sql
sqlcmd -S localhost\SQLEXPRESS -E -d BusTrackingDB

-- List all tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
GO

-- Check bus_tracking tables
SELECT * FROM bus_tracking_bus;
GO
```

---

## Connection String Reference

Your connection will use:
```
Server: localhost\SQLEXPRESS
Database: BusTrackingDB
Authentication: Windows Authentication (trusted connection)
Driver: ODBC Driver 17 for SQL Server
```

---

## Quick Check Commands

```powershell
# Check if SQL Server is running
Get-Service -Name "MSSQL`$SQLEXPRESS"

# Check if ODBC driver is installed
Get-OdbcDriver | Where-Object {$_.Name -like "*SQL Server*"}

# Test Django database connection
python manage.py dbshell

# View migrations status
python manage.py showmigrations
```

---

## Next Steps After SQL Server Setup

1. ✅ Run migrations: `python manage.py migrate`
2. ✅ Create superuser: `python manage.py createsuperuser`
3. ✅ Create tokens and test data (see COMPLETE_SETUP_GUIDE.md Step 2)
4. ✅ Start server: `python manage.py runserver 0.0.0.0:8000`
5. ✅ Run mobile apps

---

## Important Notes

- **Backup your database** regularly in production
- **Use strong passwords** for SQL authentication
- **Windows Authentication** is more secure for local development
- **SQL Server Express** is free but has limitations (10 GB database size, 1 GB RAM)
- For production, consider SQL Server Standard or Azure SQL Database

---

## Still Having Issues?

1. Check SQL Server is running: `Get-Service -Name "MSSQL`$SQLEXPRESS"`
2. Verify TCP/IP is enabled in SQL Server Configuration Manager
3. Test connection with sqlcmd: `sqlcmd -S localhost\SQLEXPRESS -E`
4. Check Windows Firewall isn't blocking SQL Server (port 1433)
5. Review Django logs for specific error messages

---

**Your SQL Server is now configured! Follow the steps above to complete the setup.** 🎉
