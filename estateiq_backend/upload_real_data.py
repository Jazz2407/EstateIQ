

# --- CONFIGURATION ---

import pandas as pd
from supabase import create_client, Client

# --- CONFIGURATION ---
# REPLACE THESE WITH YOUR ACTUAL KEYS AGAIN
URL = "https://vlcekqctdgygzqeqyhjv.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsY2VrcWN0ZGd5Z3pxZXF5aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODE3ODMsImV4cCI6MjA4NDY1Nzc4M30._vqxldXXWps7UgidP7Ymo52VSC77ODixfTZO5zo2cDw"



# Initialize Supabase
try:
    supabase: Client = create_client(URL, KEY)
except Exception as e:
    print(f"❌ Configuration Error: Check your URL and KEY in the script. Details: {e}")
    exit()

print("⏳ Loading CSV...")
try:
    df = pd.read_csv("clean_data.csv")
except FileNotFoundError:
    print("❌ Error: 'clean_data.csv' not found. Make sure it is in the 'estateiq_backend' folder.")
    exit()

# --- 2. CLEANING: FORCE INTEGERS (The Fix) ---
print("🧹 Cleaning data...")

# Fill missing values and convert to Integer (removes decimals like 1.0)
df['bathroom'] = df['bathroom'].fillna(2).astype(int)
df['age'] = df['age'].fillna(0).astype(int)
df['area'] = df['area'].astype(int)
df['bhk'] = df['bhk'].astype(int)

# --- 3. UPLOADING ---
records = df.to_dict(orient='records')
print(f"🚀 Uploading {len(records)} rows to Supabase...")

batch_size = 100
success_count = 0

for i in range(0, len(records), batch_size):
    batch = records[i:i+batch_size]
    try:
        supabase.table("property_sales").insert(batch).execute()
        success_count += len(batch)
        print(f"   Uploaded rows {i} to {i+len(batch)}...")
    except Exception as e:
        print(f"❌ Error on batch {i}: {e}")
        # If the table structure is wrong, stop immediately
        if "column" in str(e) or "relation" in str(e):
            print("🛑 STOPPING: Your database table schema might be wrong. Run the SQL script again.")
            break

print(f"✅ Finished! Successfully uploaded {success_count} rows.")