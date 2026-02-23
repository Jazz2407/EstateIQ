import os

# The folder where this script is running
current_folder = os.getcwd()
print(f"📂 Scanning folder: {current_folder}")

# 1. The name we WANT
target_name = "historic_data.csv"

# 2. The name you likely HAVE (from your upload)
upload_name = "i need data from 2010 to 2024 - i need data from 2010 to 2024.csv"

# 3. Common mistake name (Double extension)
mistake_name = "historic_data.csv.csv"

files = os.listdir(current_folder)

if target_name in files:
    print(f"✅ GOOD NEWS: '{target_name}' already exists!")
    print("   You just need to restart uvicorn.")

elif upload_name in files:
    print(f"⚠️ Found the original file: '{upload_name}'")
    try:
        os.rename(upload_name, target_name)
        print(f"   ✅ SUCCESS: Renamed it to '{target_name}'")
    except Exception as e:
        print(f"   ❌ Error renaming: {e}")

elif mistake_name in files:
    print(f"⚠️ Found a double-named file: '{mistake_name}'")
    try:
        os.rename(mistake_name, target_name)
        print(f"   ✅ SUCCESS: Fixed the name to '{target_name}'")
    except Exception as e:
        print(f"   ❌ Error renaming: {e}")

else:
    print("❌ ERROR: Could not find the file!")
    print("   Please Check:")
    print(f"   1. Did you download the CSV file?")
    print(f"   2. Did you move it into this folder: {current_folder}")
    print("   3. Files currently in this folder:")
    for f in files:
        if f.endswith(".csv"):
            print(f"      - {f}")