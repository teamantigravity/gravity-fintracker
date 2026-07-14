import sqlite3
conn = sqlite3.connect(':memory:')
cursor = conn.cursor()
cursor.execute("SELECT DATE('2026-07-01 00:00')")
print(cursor.fetchone()[0])
