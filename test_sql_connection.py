#!/usr/bin/env python
"""
اختبار الاتصال بـ SQL Server
"""

import os
import sys
import django

# إضافة المشروع إلى المسار
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# تعيين ملف الإعدادات
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')

# إعداد Django
django.setup()

from django.db import connection
from django.conf import settings

print("=" * 70)
print("🔍 اختبار اتصال قاعدة البيانات")
print("=" * 70)

# طباعة الإعدادات
print("\n📋 الإعدادات الحالية:")
print(f"  • محرك قاعدة البيانات: {settings.DATABASES['default']['ENGINE']}")
print(f"  • اسم قاعدة البيانات: {settings.DATABASES['default']['NAME']}")
print(f"  • الخادم: {settings.DATABASES['default'].get('HOST', 'لم يتم التحديد')}")
print(f"  • المستخدم: {settings.DATABASES['default'].get('USER', 'لم يتم التحديد')}")

# محاولة الاتصال
print("\n🔗 محاولة الاتصال...")

try:
    with connection.cursor() as cursor:
        # اختبار الاتصال
        cursor.execute("SELECT 1")
        print("✅ نجح الاتصال بقاعدة البيانات!")
        
        # الحصول على معلومات الخادم
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        print(f"\n📊 معلومات SQL Server:")
        print(f"  {version}")
        
        # عدد الجداول
        cursor.execute("""
            SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'dbo'
        """)
        table_count = cursor.fetchone()[0]
        print(f"\n📊 عدد الجداول: {table_count}")
        
        # اسم قاعدة البيانات
        cursor.execute("SELECT DB_NAME()")
        db_name = cursor.fetchone()[0]
        print(f"📊 اسم قاعدة البيانات: {db_name}")

except Exception as e:
    print(f"❌ فشل الاتصال!")
    print(f"\n🔴 الخطأ:")
    print(f"  {type(e).__name__}: {str(e)}")
    
    print("\n💡 التوصيات:")
    if "ODBC Driver" in str(e):
        print("  1. تثبيت ODBC Driver 17 for SQL Server")
        print("     https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server")
    
    if "Login failed" in str(e):
        print("  1. التحقق من اسم المستخدم وكلمة المرور في ملف .env")
        print("  2. التحقق من أن SQL Server يعمل")
    
    if "Cannot open database" in str(e):
        print("  1. إنشاء قاعدة البيانات BusTrackingDB")
        print("  2. استخدام: sqlcmd -S localhost\\SQLEXPRESS -U sa -P \"password\" -Q \"CREATE DATABASE BusTrackingDB\"")
    
    sys.exit(1)

print("\n" + "=" * 70)
print("✅ جميع الاختبارات نجحت! النظام جاهز.")
print("=" * 70)
