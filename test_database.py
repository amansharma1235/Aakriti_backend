from database import get_db_connection


try:
    connection = get_db_connection()

    if connection.is_connected():
        print("[SUCCESS] MySQL Database Connected Successfully!")

    connection.close()

except Exception as e:
    print("[ERROR] Database Connection Failed!")
    print(e)