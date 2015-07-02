-- Calculate percentage of electricity generated on an average day
-- this week in previous years
WITH hourly_sums AS (
  SELECT sum(watt_hours) AS watt_hours,
         date_trunc('hour', time) AS date_hour
  FROM series s
  JOIN registers r
    ON s.register_id = r.id
    AND r.name = 'gen'
  WHERE date_part('week', time) = date_part('week', now())
    AND date_part('year', time) < date_part('year', now())
  GROUP BY 2
),
avg_wh_by_hour AS (
  SELECT date_part('hour', date_hour) AS hour,
        avg(watt_hours) AS avg_wh
  FROM hourly_sums
  GROUP BY 1
)
SELECT abs(avg_wh / (SELECT sum(avg_wh) FROM avg_wh_by_hour)) * 100 AS percent,
       hour
FROM avg_wh_by_hour
ORDER BY hour
