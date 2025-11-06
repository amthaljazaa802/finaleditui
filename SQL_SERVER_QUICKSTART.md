# ✅ SQL Server Configuration Complete

## What Was Changed

I've updated your backend to use **SQL Server** instead of SQLite:

### 1. Updated `.env` File
```env
DB_ENGINE=mssql
DB_NAME=BusTrackingDB
DB_HOST=localhost\SQLEXPRESS
DB_USER=
DB_PASSWORD=
```
- Uses **Windows Authentication** (no username/password needed)
- Database name: `BusTrackingDB`
- Default SQL Server Express instance

### 2. Updated `settings.py`
- Changed `TrustServerCertificate` to `yes` for local development
- Configured for SQL Server as primary database

### 3. Updated `START_QUICK.bat`
- Now installs `mssql-django` and `pyodbc` packages
- Added SQL Server setup reminders

---

## 🚀 Quick Start with SQL Server

### Step 1: Install Requirements (5 minutes)

#### A. Install SQL Server Express (if not installed)
1. Download: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Choose **"Basic"** installation
3. Accept defaults and install

#### B. Install ODBC Driver 17 for SQL Server
1. Download: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
2. Install 64-bit version

### Step 2: Verify SQL Server is Running

```powershell
# Check if SQL Server service is running
Get-Service -Name "MSSQL`$SQLEXPRESS"
```

If it shows "Stopped", start it:
```powershell
Start-Service -Name "MSSQL`$SQLEXPRESS"
```

### Step 3: Create Database

Choose one method:

#### Option A: Using sqlcmd (Quick)
```powershell
sqlcmd -S localhost\SQLEXPRESS -E -Q "CREATE DATABASE BusTrackingDB;"
```

#### Option B: Using SQL Server Management Studio (SSMS)
1. Download SSMS: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
2. Connect to `localhost\SQLEXPRESS` with Windows Authentication
3. Right-click **Databases** → **New Database**
4. Name: `BusTrackingDB`
5. Click **OK**

### Step 4: Setup Backend

```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\Buses_BACK_END-main"

# Use the quick start script (installs SQL Server packages)
.\START_QUICK.bat
```

Or manually:
```powershell
# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install packages (including SQL Server support)
pip install django djangorestframework django-cors-headers channels daphne python-dotenv mssql-django pyodbc

# Test connection
python test_sql_connection.py

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start server
python manage.py runserver 0.0.0.0:8000
```

### Step 5: Test Connection

```powershell
python test_sql_connection.py
```

You should see:
```
✅ نجح الاتصال بقاعدة البيانات!
📊 عدد الجداول: [number]
```

Or use the enhanced test:
```powershell
python test_sql_connection_enhanced.py
```

### Step 6: Run Migrations

```powershell
python manage.py migrate
```

You should see Django creating tables in SQL Server.

### Step 7: Create Test Data

Follow the same steps as before:
```powershell
python manage.py shell
```

```python
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from bus_tracking.models import Bus, BusLine, Location

# Create tokens
driver_user = User.objects.create_user(username='driver1', password='driver123')
driver_token = Token.objects.create(user=driver_user)
print(f"Driver Token: {driver_token.key}")

user_user = User.objects.create_user(username='user1', password='user123')
user_token = Token.objects.create(user=user_user)
print(f"User Token: {user_token.key}")

# Create test data
line = BusLine.objects.create(route_id=1, route_name="Route 1", start_location="Start", end_location="End")
location = Location.objects.create(latitude=24.7136, longitude=46.6753)
bus = Bus.objects.create(bus_id=1, license_plate="ABC-123", bus_line=line, driver_name="Ahmed", current_location=location)

print(f"\nBus ID: {bus.bus_id}, Route ID: {line.route_id}")
exit()
```

---

## 🔍 Verify SQL Server Tables

After migrations, check that tables were created:

### Option A: Using sqlcmd
```powershell
sqlcmd -S localhost\SQLEXPRESS -E -d BusTrackingDB -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';"
```

### Option B: Using SSMS
1. Open SSMS
2. Connect to `localhost\SQLEXPRESS`
3. Expand **Databases** → **BusTrackingDB** → **Tables**
4. You should see tables like:
   - `bus_tracking_bus`
   - `bus_tracking_busline`
   - `bus_tracking_busstop`
   - etc.

---

## 🐛 Common Issues

### Error: "Cannot open database 'BusTrackingDB'"
**Solution:** Database doesn't exist yet
```powershell
sqlcmd -S localhost\SQLEXPRESS -E -Q "CREATE DATABASE BusTrackingDB;"
```

### Error: "Login failed for user"
**Solution:** Using wrong authentication
- Make sure `.env` has empty `DB_USER` and `DB_PASSWORD` for Windows Auth
- Or create SQL Server login and update `.env`

### Error: "ODBC Driver not found"
**Solution:** Install ODBC Driver 17 or 18
- Download from: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

### Error: "No connection could be made"
**Solution:** SQL Server not running or TCP/IP disabled
```powershell
# Start SQL Server
Start-Service -Name "MSSQL`$SQLEXPRESS"

# Then enable TCP/IP in SQL Server Configuration Manager
```

### Error: "No module named 'mssql'"
**Solution:** Install SQL Server packages
```powershell
pip install mssql-django pyodbc
```

---

## 📊 SQL Server vs SQLite

| Feature | SQLite | SQL Server |
|---------|--------|------------|
| Setup | ✅ No setup needed | ⚠️ Requires installation |
| Performance | Good for development | ✅ Better for production |
| Concurrent users | Limited | ✅ Excellent |
| Database size | Limited | ✅ Up to 10 GB (Express) |
| Authentication | None | ✅ Windows/SQL Server Auth |
| Tools | Limited | ✅ SSMS, Azure Data Studio |

---

## 📚 Files Created/Updated

1. ✅ `.env` - Changed to SQL Server configuration
2. ✅ `settings.py` - Updated for SQL Server
3. ✅ `SQL_SERVER_SETUP.md` - Detailed setup guide
4. ✅ `test_sql_connection_enhanced.py` - Enhanced connection test
5. ✅ `START_QUICK.bat` - Updated to install SQL Server packages
6. ✅ `SQL_SERVER_QUICKSTART.md` - This file!

---

## ✅ Next Steps

After SQL Server is set up:

1. ✅ Database created: `BusTrackingDB`
2. ✅ Connection tested: `python test_sql_connection.py`
3. ✅ Migrations run: `python manage.py migrate`
4. ✅ Tokens created (save them!)
5. ✅ Update mobile apps with tokens
6. ✅ Run the system!

---

## 💡 Pro Tips

- **Backup your database** regularly
- Use **SSMS** to view and manage data easily
- **Windows Authentication** is more secure for local dev
- For production, consider **Azure SQL Database**
- Keep **SQL Server service** running

---

## 🆘 Need More Help?

1. **Read:** `SQL_SERVER_SETUP.md` (detailed guide)
2. **Test:** `python test_sql_connection_enhanced.py`
3. **Check:** SQL Server service is running
4. **Verify:** Database exists
5. **Ensure:** ODBC drivers installed

---

**Your backend is now configured for SQL Server! 🎉**

Follow the steps above and you'll have a fully working SQL Server database for your bus tracking system.
