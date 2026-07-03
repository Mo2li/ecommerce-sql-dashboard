"""Load Olist CSVs into SQL Server (OlistEcommerce database)."""
import csv
import os
import pyodbc

DATA = r"D:\projectes\Data_Analysis\ecommerce-sql-dashboard\data"
CONN = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=OlistEcommerce;Trusted_Connection=yes;"

# table -> (csv file, n_columns)
TABLES = {
    "customers":            ("olist_customers_dataset.csv", 5),
    "sellers":              ("olist_sellers_dataset.csv", 4),
    "products":             ("olist_products_dataset.csv", 9),
    "category_translation": ("product_category_name_translation.csv", 2),
    "geolocation":          ("olist_geolocation_dataset.csv", 5),
    "orders":               ("olist_orders_dataset.csv", 8),
    "order_items":          ("olist_order_items_dataset.csv", 7),
    "order_payments":       ("olist_order_payments_dataset.csv", 5),
    "order_reviews":        ("olist_order_reviews_dataset.csv", 7),
}

def rows_from_csv(path):
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        next(reader)  # header
        for row in reader:
            yield [v if v != "" else None for v in row]

def main():
    cn = pyodbc.connect(CONN, autocommit=False)
    cur = cn.cursor()
    cur.fast_executemany = True

    for table, (fname, ncols) in TABLES.items():
        path = os.path.join(DATA, fname)
        placeholders = ",".join(["?"] * ncols)
        sql = f"INSERT INTO {table} VALUES ({placeholders})"
        batch, total = [], 0
        for row in rows_from_csv(path):
            batch.append(row)
            if len(batch) == 50000:
                cur.executemany(sql, batch)
                total += len(batch)
                batch = []
        if batch:
            cur.executemany(sql, batch)
            total += len(batch)
        cn.commit()
        print(f"{table:<22} {total:>10,} rows")

    cur.close(); cn.close()
    print("\nAll tables loaded.")

if __name__ == "__main__":
    main()
