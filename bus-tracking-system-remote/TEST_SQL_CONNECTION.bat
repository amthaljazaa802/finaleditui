@echo off
REM اختبار اتصال SQL Server
REM Test SQL Server Connection

echo.
echo ========================================
echo  اختبار اتصال SQL Server
echo  Testing SQL Server Connection
echo ========================================
echo.

cd /d "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"

C:\Users\Windows.11\AppData\Local\Programs\Python\Python313\python.exe test_sql_connection.py

if errorlevel 1 (
    echo.
    echo ❌ فشل الاتصال - Connection Failed
    pause
    exit /b 1
) else (
    echo.
    echo ✅ نجح الاتصال - Connection Successful
    pause
)
