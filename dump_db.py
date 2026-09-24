import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='aman7800839003@',
    database='aakriti_ultrasound'
)
cursor = conn.cursor()

tables = ['admin_users', 'patients', 'doctors', 'services', 'appointments', 'reports', 'payments', 'notifications', 'fcm_tokens']

with open('schema.sql', 'w', encoding='utf-8') as f:
    f.write('-- Aakriti Ultrasound & Diagnostic Clinic Complete Database Dump\n')
    f.write('SET NAMES utf8mb4;\n')
    f.write('SET FOREIGN_KEY_CHECKS = 0;\n\n')
    
    for table in tables:
        try:
            cursor.execute(f"SHOW CREATE TABLE `{table}`")
            create_stmt = cursor.fetchone()[1]
            f.write(f"DROP TABLE IF EXISTS `{table}`;\n")
            f.write(f"{create_stmt};\n\n")
            
            cursor.execute(f"SELECT * FROM `{table}`")
            rows = cursor.fetchall()
            if rows:
                cursor.execute(f"SHOW COLUMNS FROM `{table}`")
                cols = [col[0] for col in cursor.fetchall()]
                cols_str = ', '.join([f"`{c}`" for c in cols])
                f.write(f"INSERT INTO `{table}` ({cols_str}) VALUES\n")
                val_strs = []
                for r in rows:
                    formatted_vals = []
                    for v in r:
                        if v is None:
                            formatted_vals.append('NULL')
                        elif isinstance(v, (int, float)):
                            formatted_vals.append(str(v))
                        else:
                            val_str = str(v).replace('\\', '\\\\').replace("'", "\\'")
                            formatted_vals.append(f"'{val_str}'")
                    val_strs.append('(' + ', '.join(formatted_vals) + ')')
                f.write(',\n'.join(val_strs) + ';\n\n')
        except Exception as e:
            print(f"Error dumping {table}: {e}")
            
    f.write('SET FOREIGN_KEY_CHECKS = 1;\n')

conn.close()
print('Dump completed to aakriti_backend/schema.sql successfully!')
