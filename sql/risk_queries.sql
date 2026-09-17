-- Schema (SQLite/PostgreSQL compatible)
CREATE TABLE stock_prices (
      date DATE,
      ticker TEXT,
      close NUMERIC
  );

-- 1. Daily returns per ticker (window function)
                                SELECT
                                  date,
                                  ticker,
                                  close,
                                  ROUND(close / LAG(close) OVER (PARTITION BY ticker ORDER BY date) - 1, 4) AS daily_return
                                FROM stock_prices
                                ORDER BY ticker, date;

                                -- 2. 5-day rolling volatility (standard deviation of returns) per ticker
                                WITH returns AS (
                                    SELECT
                                      date,
                                      ticker,
                                      close / LAG(close) OVER (PARTITION BY ticker ORDER BY date) - 1 AS daily_return
                                    FROM stock_prices
                                  )
                                SELECT
                                  date,
                                  ticker,
                                  ROUND(
                                        STDDEV(daily_return) OVER (
                                                PARTITION BY ticker ORDER BY date
                                                ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
                                              ), 4
                                      ) AS rolling_5d_volatility
                                FROM returns
                                ORDER BY ticker, date;

                                -- 3. Cumulative return per ticker (window function)
                                                                    WITH returns AS (
                                                                        SELECT
                                                                          date,
                                                                          ticker,
                                                                          close / LAG(close) OVER (PARTITION BY ticker ORDER BY date) - 1 AS daily_return
                                                                        FROM stock_prices
                                                                      )
                                                                    SELECT
                                                                      date,
                                                                      ticker,
                                                                      ROUND(
                                                                            EXP(SUM(LN(1 + daily_return)) OVER (PARTITION BY ticker ORDER BY date)) - 1, 4
                                                                          ) AS cumulative_return
                                                                    FROM returns
                                                                    WHERE daily_return IS NOT NULL
                                                                    ORDER BY ticker, date;

                                                                    -- 4. Best and worst single-day return per ticker
                                                                    SELECT
                                                                      ticker,
                                                                      MAX(close / prev_close - 1) AS best_day_return,
                                                                      MIN(close / prev_close - 1) AS worst_day_return
                                                                    FROM (
                                                                        SELECT
                                                                          ticker,
                                                                          close,
                                                                          LAG(close) OVER (PARTITION BY ticker ORDER BY date) AS prev_close
                                                                        FROM stock_prices
                                                                      ) t
                                                                    WHERE prev_close IS NOT NULL
                                                                    GROUP BY ticker;
