import pandas as pd
import re

def clean_price(value):
    if pd.isna(value) or value == '-' or str(value).strip() == '': return "Empty"
    
    # Standardize string
    val_str = str(value).lower().replace(',', '').replace('₹', '')
    
    # 1. Check for Range (e.g., "40 - 50")
    if '-' in val_str:
        parts = val_str.split('-')
        nums = re.findall(r"[-+]?\d*\.\d+|\d+", "".join(parts))
        if len(nums) >= 2:
            return f"AVG({nums[0]} & {nums[1]})"

    # 2. Check for simple number
    numbers = re.findall(r"[-+]?\d*\.\d+|\d+", val_str)
    if not numbers: return "Error"
    
    num = float(numbers[0])
    
    # 3. Logic Check
    raw_num = num
    if 'cr' in val_str:
        return f"{num} Cr -> {num * 100} Lakhs"
    elif num > 500: # Threshold changed to 500
        return f"{num} (Raw) -> {num / 100000} Lakhs"
    else:
        return f"{num} Lakhs"

print("\n🔍 INSPECTING YOUR CSV FILE...")
try:
    df = pd.read_csv("Data.csv")
    df.columns = df.columns.str.lower().str.strip()
    
    # Check headers
    print(f"✅ Found Columns: {list(df.columns)}")
    
    # Print first 5 rows of 1 BHK column to verify
    target_col = '1 bhk (est.)'
    print(f"\n--- Checking Column: '{target_col}' ---")
    
    if target_col not in df.columns:
        print(f"❌ ERROR: Could not find '{target_col}' column!")
    else:
        for i in range(0, min(5, len(df))):
            raw_val = df.iloc[i][target_col]
            clean_val = clean_price(raw_val)
            print(f"Row {i+1}: CSV says '{raw_val}' \t---> Python sees: {clean_val}")

except Exception as e:
    print(f"❌ Error reading file: {e}")