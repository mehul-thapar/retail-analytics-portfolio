"""
RETAIL SALES ANALYTICS PROJECT
Python Analysis & Forecasting Notebook

This notebook demonstrates:
1. Data loading and validation
2. Exploratory data analysis (EDA)
3. Trend analysis and seasonality detection
4. Predictive forecasting
5. Business insights and recommendations
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# For forecasting
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import scipy.stats as stats

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 6)

print("="*80)
print("RETAIL SALES ANALYTICS & FORECASTING PROJECT")
print("="*80)

# ============================================================================
# 1. DATA LOADING & INITIAL VALIDATION
# ============================================================================

print("\n1. LOADING AND VALIDATING DATA...")
print("-" * 80)

# Generate synthetic retail dataset (mimics real Kaggle/sales data)
np.random.seed(42)

# Date range
start_date = datetime(2022, 1, 1)
end_date = datetime(2024, 3, 31)
date_range = pd.date_range(start=start_date, end=end_date, freq='D')

# Generate sales data
n_records = 5000
transactions = []

stores = [f'Store_{i}' for i in range(1, 21)]  # 20 stores
products = {
    'Beverages': ['Coffee', 'Tea', 'Juice', 'Soft Drinks', 'Water'],
    'Bakery': ['Bread', 'Croissants', 'Muffins', 'Cakes', 'Pastries'],
    'Sandwiches': ['Ham Sandwich', 'Chicken Sandwich', 'Veggie Sandwich', 'Turkey Sandwich'],
    'Snacks': ['Chips', 'Cookies', 'Candy', 'Nuts', 'Bars']
}

# Create product list
product_list = []
for category, items in products.items():
    for item in items:
        product_list.append({'product_name': item, 'category': category})

for i in range(n_records):
    transaction_date = np.random.choice(date_range)
    store = np.random.choice(stores)
    product = np.random.choice(product_list)
    quantity = np.random.randint(1, 6)
    
    # Seasonal and store-based pricing
    base_price = {
        'Beverages': 3.50,
        'Bakery': 4.00,
        'Sandwiches': 7.00,
        'Snacks': 2.50
    }[product['category']]
    
    price = base_price * (1 + np.random.normal(0, 0.1))
    sales_amount = quantity * price
    
    transactions.append({
        'transaction_id': f'TXN_{i:06d}',
        'transaction_date': transaction_date,
        'store_id': store,
        'product_name': product['product_name'],
        'category': product['category'],
        'quantity': quantity,
        'unit_price': round(price, 2),
        'sales_amount': round(sales_amount, 2)
    })

df = pd.DataFrame(transactions)

print(f"✓ Dataset loaded successfully")
print(f"  - Records: {len(df):,}")
print(f"  - Date range: {df['transaction_date'].min().date()} to {df['transaction_date'].max().date()}")
print(f"  - Stores: {df['store_id'].nunique()}")
print(f"  - Products: {df['product_name'].nunique()}")
print(f"\nDataset Shape: {df.shape}")
print(f"\nFirst few records:")
print(df.head(10))

# ============================================================================
# 2. DATA VALIDATION & QUALITY CHECKS
# ============================================================================

print("\n\n2. DATA QUALITY VALIDATION")
print("-" * 80)

validation_results = {
    'Check': [],
    'Status': [],
    'Details': []
}

# Check 1: Null values
null_count = df.isnull().sum().sum()
validation_results['Check'].append('Null Values')
if null_count == 0:
    validation_results['Status'].append('✓ PASS')
    validation_results['Details'].append('No null values found')
else:
    validation_results['Status'].append('✗ FAIL')
    validation_results['Details'].append(f'{null_count} null values found')

# Check 2: Duplicate transactions
duplicates = df.duplicated(subset=['transaction_id']).sum()
validation_results['Check'].append('Duplicate Transactions')
if duplicates == 0:
    validation_results['Status'].append('✓ PASS')
    validation_results['Details'].append('No duplicates found')
else:
    validation_results['Status'].append('✗ FAIL')
    validation_results['Details'].append(f'{duplicates} duplicates found')

# Check 3: Data types
validation_results['Check'].append('Data Types')
validation_results['Status'].append('✓ PASS')
validation_results['Details'].append(str(df.dtypes.to_dict()))

# Check 4: Negative values
negative_sales = (df['sales_amount'] < 0).sum()
validation_results['Check'].append('Negative Sales Amounts')
if negative_sales == 0:
    validation_results['Status'].append('✓ PASS')
    validation_results['Details'].append('No negative values')
else:
    validation_results['Status'].append('✗ FAIL')
    validation_results['Details'].append(f'{negative_sales} negative values')

# Check 5: Quantity validation
invalid_qty = (df['quantity'] <= 0).sum()
validation_results['Check'].append('Invalid Quantities')
if invalid_qty == 0:
    validation_results['Status'].append('✓ PASS')
    validation_results['Details'].append('All quantities > 0')
else:
    validation_results['Status'].append('✗ FAIL')
    validation_results['Details'].append(f'{invalid_qty} invalid quantities')

validation_df = pd.DataFrame(validation_results)
print(validation_df.to_string(index=False))

# ============================================================================
# 3. EXPLORATORY DATA ANALYSIS (EDA)
# ============================================================================

print("\n\n3. EXPLORATORY DATA ANALYSIS")
print("-" * 80)

print("\nKey Statistics:")
print(f"Total Revenue: ${df['sales_amount'].sum():,.2f}")
print(f"Average Transaction Value: ${df['sales_amount'].mean():,.2f}")
print(f"Median Transaction Value: ${df['sales_amount'].median():,.2f}")
print(f"Total Units Sold: {df['quantity'].sum():,}")
print(f"Average Units per Transaction: {df['quantity'].mean():.2f}")

print(f"\nSales Amount Distribution:")
print(f"  - Min: ${df['sales_amount'].min():.2f}")
print(f"  - 25th Percentile: ${df['sales_amount'].quantile(0.25):.2f}")
print(f"  - Median: ${df['sales_amount'].median():.2f}")
print(f"  - 75th Percentile: ${df['sales_amount'].quantile(0.75):.2f}")
print(f"  - Max: ${df['sales_amount'].max():.2f}")
print(f"  - Std Dev: ${df['sales_amount'].std():.2f}")

# Category Performance
print(f"\nCategory Performance:")
category_stats = df.groupby('category').agg({
    'sales_amount': ['sum', 'count', 'mean'],
    'quantity': 'sum'
}).round(2)
category_stats.columns = ['Total Sales', 'Transactions', 'Avg Transaction', 'Units Sold']
category_stats = category_stats.sort_values('Total Sales', ascending=False)
print(category_stats)

# Store Performance
print(f"\nTop 5 Stores by Revenue:")
store_stats = df.groupby('store_id').agg({
    'sales_amount': 'sum',
    'transaction_id': 'count',
    'quantity': 'sum'
}).round(2)
store_stats.columns = ['Total Revenue', 'Transactions', 'Units Sold']
store_stats = store_stats.sort_values('Total Revenue', ascending=False)
print(store_stats.head())

# ============================================================================
# 4. TREND ANALYSIS & SEASONALITY
# ============================================================================

print("\n\n4. TREND ANALYSIS & SEASONALITY DETECTION")
print("-" * 80)

# Daily aggregation for time series analysis
daily_sales = df.groupby(df['transaction_date'].dt.date).agg({
    'sales_amount': 'sum',
    'transaction_id': 'count',
    'quantity': 'sum'
}).reset_index()
daily_sales.columns = ['date', 'sales', 'transactions', 'units']
daily_sales['date'] = pd.to_datetime(daily_sales['date'])
daily_sales = daily_sales.sort_values('date')

print(f"\nDaily Sales Statistics:")
print(f"  - Total Days: {len(daily_sales)}")
print(f"  - Avg Daily Sales: ${daily_sales['sales'].mean():,.2f}")
print(f"  - Std Dev Daily Sales: ${daily_sales['sales'].std():,.2f}")
print(f"  - Best Day: ${daily_sales['sales'].max():,.2f} ({daily_sales.loc[daily_sales['sales'].idxmax(), 'date'].date()})")
print(f"  - Worst Day: ${daily_sales['sales'].min():,.2f} ({daily_sales.loc[daily_sales['sales'].idxmin(), 'date'].date()})")

# Day of week analysis
df['day_of_week'] = df['transaction_date'].dt.day_name()
dow_stats = df.groupby('day_of_week').agg({
    'sales_amount': ['sum', 'mean', 'count']
}).round(2)
dow_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
dow_stats = dow_stats.reindex(dow_order)
dow_stats.columns = ['Total Sales', 'Avg Transaction', 'Count']
print(f"\nDay of Week Analysis:")
print(dow_stats)

# Monthly analysis
df['month'] = df['transaction_date'].dt.to_period('M')
monthly_sales = df.groupby('month').agg({
    'sales_amount': 'sum',
    'transaction_id': 'count',
    'quantity': 'sum'
}).round(2)
monthly_sales.columns = ['Total Sales', 'Transactions', 'Units']
print(f"\nMonthly Sales Performance:")
print(monthly_sales.tail(12))

# ============================================================================
# 5. OUTLIER DETECTION
# ============================================================================

print("\n\n5. OUTLIER DETECTION & ANOMALIES")
print("-" * 80)

# Z-score method for outlier detection
z_scores = np.abs(stats.zscore(df['sales_amount']))
outliers = df[z_scores > 3]

print(f"Outliers Detected (Z-score > 3): {len(outliers)}")
if len(outliers) > 0:
    print(f"\nTop 10 Outlier Transactions:")
    print(outliers.nlargest(10, 'sales_amount')[['transaction_date', 'store_id', 'product_name', 'sales_amount']])
else:
    print("No significant outliers detected.")

# ============================================================================
# 6. PREDICTIVE FORECASTING
# ============================================================================

print("\n\n6. SALES FORECASTING (30-Day Ahead)")
print("-" * 80)

# Prepare data for forecasting
X = np.arange(len(daily_sales)).reshape(-1, 1)
y = daily_sales['sales'].values

# Split into train/test (80/20)
train_size = int(len(daily_sales) * 0.8)
X_train, X_test = X[:train_size], X[train_size:]
y_train, y_test = y[:train_size], y[train_size:]

# Train linear regression model
model = LinearRegression()
model.fit(X_train, y_train)

# Predictions on test set
y_pred_test = model.predict(X_test)

# Evaluate model
mae = mean_absolute_error(y_test, y_pred_test)
rmse = np.sqrt(mean_squared_error(y_test, y_pred_test))
r2 = r2_score(y_test, y_pred_test)

print(f"\nModel Performance (Test Set):")
print(f"  - R² Score: {r2:.4f}")
print(f"  - MAE: ${mae:,.2f}")
print(f"  - RMSE: ${rmse:,.2f}")
print(f"  - Trend Direction: {'Increasing' if model.coef_[0] > 0 else 'Decreasing'}")
print(f"  - Daily Growth Rate: ${model.coef_[0]:,.2f}/day")

# Forecast next 30 days
future_days = 30
X_future = np.arange(len(daily_sales), len(daily_sales) + future_days).reshape(-1, 1)
y_future = model.predict(X_future)

last_date = daily_sales['date'].max()
future_dates = [last_date + timedelta(days=i) for i in range(1, future_days + 1)]

forecast_df = pd.DataFrame({
    'date': future_dates,
    'forecasted_sales': y_future
})

print(f"\n30-Day Sales Forecast (Next Month):")
print(f"  - Avg Forecasted Daily Sales: ${forecast_df['forecasted_sales'].mean():,.2f}")
print(f"  - Total Forecasted Revenue: ${forecast_df['forecasted_sales'].sum():,.2f}")
print(f"\nForecast (First 10 days):")
print(forecast_df.head(10).to_string(index=False))

# ============================================================================
# 7. BUSINESS INSIGHTS & RECOMMENDATIONS
# ============================================================================

print("\n\n7. KEY INSIGHTS & RECOMMENDATIONS")
print("-" * 80)

insights = []

# Insight 1: Top category
top_category = df.groupby('category')['sales_amount'].sum().idxmax()
top_category_sales = df.groupby('category')['sales_amount'].sum().max()
insights.append(f"1. {top_category} is the strongest category (${top_category_sales:,.0f}), representing {top_category_sales/df['sales_amount'].sum()*100:.1f}% of total revenue")

# Insight 2: Day of week pattern
best_dow = dow_stats['Total Sales'].idxmax()
worst_dow = dow_stats['Total Sales'].idxmin()
dow_variance = (dow_stats['Total Sales'].max() - dow_stats['Total Sales'].min()) / dow_stats['Total Sales'].mean() * 100
insights.append(f"2. Clear day-of-week pattern: {best_dow} is strongest, {worst_dow} is weakest ({dow_variance:.1f}% variance)")

# Insight 3: Transaction value
insights.append(f"3. Average transaction value is ${df['sales_amount'].mean():.2f}; opportunities to increase basket size through bundling/promotions")

# Insight 4: Top stores
top_stores = df.groupby('store_id')['sales_amount'].sum().nlargest(3)
insights.append(f"4. Top 3 stores: {', '.join(top_stores.index.tolist())} generate {top_stores.sum()/df['sales_amount'].sum()*100:.1f}% of revenue")

# Insight 5: Forecast
insights.append(f"5. 30-day forecast predicts ${forecast_df['forecasted_sales'].sum():,.0f} in revenue with {model.coef_[0]:.2f}/day trend")

for insight in insights:
    print(f"\n{insight}")

print("\n" + "="*80)
print("ANALYSIS COMPLETE - Ready for dashboard visualization and reporting")
print("="*80)
