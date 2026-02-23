import random
from faker import Faker
from supabase import create_client, Client

# --- CONFIGURATION (Use your same keys from main.py) ---
URL = "https://vlcekqctdgygzqeqyhjv.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsY2VrcWN0ZGd5Z3pxZXF5aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODE3ODMsImV4cCI6MjA4NDY1Nzc4M30._vqxldXXWps7UgidP7Ymo52VSC77ODixfTZO5zo2cDw"

supabase: Client = create_client(URL, KEY)
fake = Faker()

print("🚀 Generating 500 real-estate records...")

properties = []

for _ in range(500):
    # Logic: Generate realistic stats
    sq_ft = random.randint(500, 3500)
    bedrooms = random.randint(1, 5)
    age = random.randint(0, 30)
    location_score = random.randint(3, 10) # 3=Rural, 10=City Center
    
    # Calculate a realistic 'target' price so the AI can learn the pattern
    # Base Price $50k + ($120 per sq_ft) + ($10k per bedroom) - ($500 per year old)
    base_price = 50000 + (sq_ft * 120) + (bedrooms * 10000) - (age * 500)
    
    # Add some "Market Noise" (randomness) so it's not a perfect equation
    noise = random.randint(-15000, 15000)
    final_price = base_price + (location_score * 5000) + noise

    properties.append({
        "sq_ft": sq_ft,
        "bedrooms": bedrooms,
        "age_of_building": age,
        "location_score": location_score,
        "sold_price": final_price
    })

# Upload in batches to be safe
print("📤 Uploading to Supabase...")
data = supabase.table("property_sales").insert(properties).execute()

print(f"✅ Success! Uploaded {len(properties)} new rows.")
print("👉 Now restart your 'main.py' backend to retrain the AI on this new data.")