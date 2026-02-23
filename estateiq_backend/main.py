


import pandas as pd
import numpy as np
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client

URL = "https://vlcekqctdgygzqeqyhjv.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsY2VrcWN0ZGd5Z3pxZXF5aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODE3ODMsImV4cCI6MjA4NDY1Nzc4M30._vqxldXXWps7UgidP7Ymo52VSC77ODixfTZO5zo2cDw"

supabase: Client = create_client(URL, KEY)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Storage
location_growth_rates = {} 
df_global = None 

@app.on_event("startup")
def load_data():
    global location_growth_rates, df_global
    print("⏳ Loading Data...")
    
    # 1. Load Listings (Real-Time Price)
    try:
        response = supabase.table('property_sales').select("*").execute()
        if response.data:
            df_global = pd.DataFrame(response.data)
            df_global['location'] = df_global['location'].str.lower().str.strip()
            print(f"✅ Loaded {len(df_global)} listings.")
    except Exception as e:
        print(f"⚠️ Supabase Error: {e}")

    # 2. Load History (Growth Rates)
    try:
        df_hist = pd.read_csv("historic_data.csv")
        year_cols = [c for c in df_hist.columns if c.isdigit()]
        year_cols.sort()
        start, end = year_cols[0], year_cols[-1]
        years_diff = int(end) - int(start)

        for index, row in df_hist.iterrows():
            loc = str(row['Area']).lower().strip()
            try:
                s_val, e_val = float(row[start]), float(row[end])
                if s_val > 0 and e_val > 0:
                    cagr = (e_val / s_val) ** (1 / years_diff) - 1
                    # Safety Caps
                    if cagr > 0.08: cagr = 0.08
                    if cagr < 0.03: cagr = 0.03
                    location_growth_rates[loc] = cagr
            except: continue
        print("✅ Growth Engine Ready.")
    except: print("❌ Historic Data Load Failed")

class PropertyRequest(BaseModel):
    area: int
    bhk: int
    bathroom: int
    age: int          # Current Age (e.g., 0 for New)
    location: str 
    status: str
    target_year: int = 2026

@app.post("/predict_price")
def predict_price(req: PropertyRequest):
    loc_key = req.location.lower().strip()
    
    # --- 1. BASE MARKET PRICE (TODAY) ---
    base_price = 45.0 # Default
    if df_global is not None:
        match = df_global[(df_global['location'] == loc_key) & (df_global['bhk'] == req.bhk)]
        if not match.empty:
            base_price = match.iloc[0]['price']
        else:
            match_loc = df_global[df_global['location'] == loc_key]
            if not match_loc.empty:
                rate = (match_loc.iloc[0]['price'] * 100000) / match_loc.iloc[0]['area']
                base_price = (rate * req.area) / 100000

    # --- 2. CURRENT ASSET VALUE ---
    # Logic: Market Price - Depreciation on Current Age
    curr_land = base_price * 0.25
    curr_bldg = base_price * 0.75
    
    curr_dep_rate = 0.0166 * req.age
    if curr_dep_rate > 0.60: curr_dep_rate = 0.60
    
    current_asset_val = curr_land + (curr_bldg * (1 - curr_dep_rate))

    # --- 3. FUTURE MARKET PRICE ---
    # Logic: Market Price * Growth Rate ^ Years
    growth_rate = location_growth_rates.get(loc_key, 0.055)
    years_future = req.target_year - 2026
    
    future_market_val = base_price * ((1 + growth_rate) ** years_future)
    
    # --- 4. FUTURE ASSET VALUE ---
    # Logic: Future Market Price - Depreciation on (Current Age + Time Passed)
    
    # 👇 THIS IS THE LOGIC YOU ASKED FOR
    future_total_age = req.age + years_future 
    
    fut_land = future_market_val * 0.25
    fut_bldg = future_market_val * 0.75
    
    fut_dep_rate = 0.0166 * future_total_age # Depreciates based on Future Age
    if fut_dep_rate > 0.60: fut_dep_rate = 0.60
    
    future_asset_val = fut_land + (fut_bldg * (1 - fut_dep_rate))

    return {
        "current_market": round(base_price, 2),
        "current_asset": round(current_asset_val, 2),
        "future_market": round(future_market_val, 2),
        "future_asset": round(future_asset_val, 2)
    }

@app.get("/all_properties")
def get_all_properties():
    if df_global is not None:
        return df_global[['city', 'location']].drop_duplicates().to_dict(orient='records')
    return []