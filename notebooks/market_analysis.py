"""
Equity Market Data Analysis
Computes daily returns, annualized volatility, Sharpe ratio, max drawdown,
and correlation across a basket of tickers from daily close-price data.
"""

import pandas as pd
import numpy as np

RISK_FREE_ANNUAL = 0.045
TRADING_DAYS = 252


def load_data(path="../data/stock_prices.csv"):
df = pd.read_csv(path, parse_dates=["date"])
prices = df.pivot(index="date", columns="ticker", values="close")
return prices.sort_index()

def compute_returns(prices):
return prices.pct_change().dropna()

def annualized_volatility(returns):
return returns.std() * np.sqrt(TRADING_DAYS)

def sharpe_ratio(returns):
rf_daily = RISK_FREE_ANNUAL / TRADING_DAYS
excess = returns.mean() - rf_daily
return excess / returns.std() * np.sqrt(TRADING_DAYS)

def max_drawdown(prices):
running_max = prices.cummax()
drawdown = prices / running_max - 1
return drawdown.min()

def build_summary(prices, returns):
summary = pd.DataFrame({
"ann_volatility": annualized_volatility(returns),
"sharpe_ratio": sharpe_ratio(returns),
"max_drawdown": max_drawdown(prices),
"end_price": prices.iloc[-1],
})
return summary.round(4)

def main():
prices = load_data()
returns = compute_returns(prices)
summary = build_summary(prices, returns)
print("=== Risk Summary ===")
print(summary)
print()
print("=== Correlation Matrix (daily returns) ===")
print(returns.corr().round(2))
print()
print("=== 5-Day Rolling Volatility (last 5 rows) ===")
rolling_vol = returns.rolling(5).std() * np.sqrt(TRADING_DAYS)
print(rolling_vol.tail())

main()
