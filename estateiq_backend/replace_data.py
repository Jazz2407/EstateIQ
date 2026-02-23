


import pandas as pd
import numpy as np
from supabase import create_client, Client
import time
import re

# --- CONFIGURATION (Paste your Keys Here!) ---
URL = "https://vlcekqctdgygzqeqyhjv.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsY2VrcWN0ZGd5Z3pxZXF5aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODE3ODMsImV4cCI6MjA4NDY1Nzc4M30._vqxldXXWps7UgidP7Ymo52VSC77ODixfTZO5zo2cDw"
                                             
supabase: Client = create_client(URL, KEY)

def clean_value(value):
    """
    Converts mixed units (Lakhs/Crores) into a standard 'Lakhs' float.
    Examples:
      '45 L'      -> 45.0
      '1.2 Cr'    -> 120.0
      '45,00,000' -> 45.0
    """
    if pd.isna(value) or str(value).strip() in ['', '-', 'nan', 'None']:
        return None
    
    # 1. Normalize String (Lower case)
    val_str = str(value).lower().strip()
    
    # 2. Extract Numbers FIRST
    # We remove currency symbols but KEEP letters like 'c', 'l' for now to detect units
    clean_str = val_str.replace(',', '').replace('₹', '').replace('/sq.ft', '')
    numbers = re.findall(r"[-+]?\d*\.\d+|\d+", clean_str)
    
    if not numbers:
        return None
    
    # 3. Handle Ranges (e.g. "40 - 50") -> Take Average
    floats = [float(n) for n in numbers]
    avg_val = sum(floats) / len(floats)
    
    # --- 4. UNIT DETECTION LOGIC ---
    
    # CASE A: CRORES (e.g. "1.5 Cr", "1.5 C", "1.5 Crore")
    if 'cr' in val_str or 'crore' in val_str:
        return round(avg_val * 100, 2)  # 1.5 Cr -> 150.0 Lakhs
        
    # CASE B: LAKHS (e.g. "45 L", "45 Lac") -> Keep as is
    if 'l' in val_str or 'lac' in val_str:
        return round(avg_val, 2)
        
    # CASE C: RAW NUMBERS (e.g. "15000000" or "4500000")
    # If the number is huge (> 10,000), it's likely raw Rupees.
    if avg_val > 10000:
        return round(avg_val / 100000, 2) # Convert to Lakhs

    # CASE D: SMALL RAW NUMBERS (e.g. "45")
    # We assume these are already in Lakhs.
    return round(avg_val, 2)

def replace_database():
    print("\n--- STARTING INTELLIGENT DATA UPLOAD ---")
    
    # 1. READ CSV FIRST (To check data before deleting)
    print("1️⃣  Reading 'Data.csv'...")
    try:
        df = pd.read_csv("Data.csv")
    except FileNotFoundError:
        print("   ❌ ERROR: 'Data.csv' not found.")
        return

    # Normalize headers
    df.columns = df.columns.str.lower().str.strip()
    
    # 2. WIPE DATABASE
    print("2️⃣  Wiping existing data from Supabase...")
    while True:
        res = supabase.table('property_sales').select("id").limit(1000).execute()
        if not res.data: break
        ids = [r['id'] for r in res.data]
        supabase.table('property_sales').delete().in_('id', ids).execute()
    print("   ✅ Database cleared.")

    # 3. PROCESS ROWS
    print("3️⃣  Processing & Converting Units...")
    
    # Mappings
    col_city = 'district'
    col_loc = 'specific area / locality'
    col_rate = 'est. price (₹/sq.ft)'
    price_cols = {1: '1 bhk (est.)', 2: '2 bhk (est.)', 3: '3 bhk (est.)', 4: '4 bhk (est.)'}
    default_areas = {1: 600, 2: 950, 3: 1400, 4: 2200}
    
    new_listings = []
    
    # Debug counter to show user examples
    debug_count = 0
    
    for index, row in df.iterrows():
        loc = row.get(col_loc)
        city = row.get(col_city)
        raw_rate = row.get(col_rate)
        rate = clean_value(raw_rate) # Rate is usually per sq.ft, so no Lakh/Cr conversion logic needed usually, but logic handles it safely.

        if pd.isna(loc): continue
        if pd.isna(city): city = "Chennai"

        for bhk, col_name in price_cols.items():
            raw_price = row.get(col_name)
            price = clean_value(raw_price) # <--- THIS NOW HANDLES CRORES
            
            if price:
                # Math: Area = (Price in Lakhs * 100,000) / Rate
                if rate and rate > 0:
                    area = int((price * 100000) / rate)
                else:
                    area = default_areas[bhk]

                # DEBUG: Print the first few Crore conversions to verify
                if 'cr' in str(raw_price).lower() and debug_count < 3:
                    print(f"   🔎 CONVERTED: '{raw_price}' -> {price} Lakhs")
                    debug_count += 1
                
                new_listings.append({
                    "city": city, "location": loc, "price": price, 
                    "bhk": bhk, "bathroom": bhk, "area": area, 
                    "status": "Ready to move", "age": 2
                })

    print(f"   ✅ Processed {len(new_listings)} listings.")

    # 4. UPLOAD
    print("4️⃣  Uploading to Supabase...")
    batch_size = 100
    for i in range(0, len(new_listings), batch_size):
        batch = new_listings[i : i + batch_size]
        try:
            supabase.table('property_sales').insert(batch).execute()
            print(f"      Uploaded batch {i} - {i+len(batch)}")
        except Exception as e:
            print(f"      ❌ Upload Error: {e}")
            time.sleep(2)

    print("\n🎉 DONE! Data uploaded with corrected units.")

if __name__ == "__main__":
    replace_database()