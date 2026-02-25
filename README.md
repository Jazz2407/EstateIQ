EstateIQ | Intelligent Real Estate Forecasting

Buying a home is often the biggest financial decision a family makes, yet most retail buyers are forced to rely on gut feelings or biased broker advice. I built EstateIQ to change that.
EstateIQ is a full-stack platform that brings professional-grade property intelligence to the everyday investor. By using a Hybrid Valuation Engine, the app separates the "hype" from the actual "value," helping users understand what they are actually paying for.

💡 The Core Concept: Market vs. Asset
Most apps only show you the market price. EstateIQ goes deeper by calculating:
  Market Value: What people are currently paying based on demand.
  Asset Value: The real worth of the property, calculated by combining land value with a depreciated building structure (using standard engineering rates).

🚀 What it can do
  Predict the Future: I implemented an interactive "Time-Travel" slider. You can project property values up to 10 years into the future to see how your investment might grow (or shrink).
  Dynamic Aging: If you're looking at a brand-new house today, the app understands that in 5 years, it will be a 5-year-old building. It automatically applies depreciation to the structure while growing the land value.
  Real-Time Data: The app isn't just guessing—it's backed by a Supabase database and historical CAGR data for specific Tamil Nadu districts to keep forecasts grounded in reality.

🛠️ The Tech Stack
  Frontend: Built with Flutter for a smooth, responsive mobile experience.
  Backend: A high-performance FastAPI (Python) server handling all the heavy math.
  Database: Supabase (PostgreSQL) for managing listings and trend data.
  Analysis: Pandas & NumPy were used to process historical growth rates.

🌍 Why this matters (SDGs)
This project is more than just code; it’s about Social Relevancy. By aligning with SDGs 8, 9, 10, and 11, EstateIQ aims to democratize financial data. It protects middle-class wealth by exposing overpriced assets and educating users on how property truly depreciates over time.

⚙️ How to run it
  Backend: Head into /backend, install dependencies via pip, add your Supabase keys, and fire up the server with uvicorn main:app --reload.
  Frontend: Inside the /flutter_app folder, run flutter pub get. Make sure the API URL in main.dart points to your local IP, then hit flutter run.


<img width="1919" height="909" alt="image" src="https://github.com/user-attachments/assets/02edb70b-57d8-43f0-abc0-867e62a18461" />

  
  
  
  
  
  
  Developed by Jai Full-Stack Developer & PropTech Enthusiast
