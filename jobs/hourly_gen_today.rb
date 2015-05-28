require_relative '../lib/common.rb'

# graph of hourly generation for today
SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_part('hour', time) as hour
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date(time) = date(now())
      AND date_part('hour', time) BETWEEN 5 AND 20
    GROUP BY date_part('hour', time)
    ORDER BY date_part('hour', time)
  SQL
  results = DB[query, REGISTER]
  current_points = results.map do |row|
    unix_time = Time.mktime(now.year,now.month,now.day,row[:hour].to_i).to_i
    { x: unix_time, y: row[:watt_hours].to_i }
  end

  # get historical average by computing the average wh generated each hour
  # during this week in previous years.
  query = <<-SQL
    SELECT abs(avg(sum_wh)) as avg_wh, date_part('hour', time_hour) as hour
    FROM (
      SELECT sum(watt_hours) as sum_wh, date_trunc('hour', time) as time_hour
      FROM series s
      JOIN registers r
        ON r.id = s.register_id
      WHERE r.name = ?
        AND date_part('week', time) = date_part('week', now())
        AND date_part('hour', time) BETWEEN 5 AND 20
        AND date_part('year', time) < date_part('year', now())
      GROUP BY date_trunc('hour', time)
      ORDER BY date_trunc('hour', time)
      ) sums
    GROUP BY date_part('hour', time_hour)
    ORDER BY date_part('hour', time_hour)
  SQL
  results = DB[query, REGISTER]
  average_points = results.map do |row|
    unix_time = Time.mktime(now.year,now.month,now.day,row[:hour].to_i).to_i
    { x: unix_time, y: row[:avg_wh].to_i }
  end

  series = [
    { name: 'Today',
      data: current_points },
    { name: 'Historical Average',
      data: average_points }
  ]

  hour_start = Time.mktime(now.year, now.month, now.day, now.hour)
  gen_hourly_wh = generation_since(hour_start, REGISTER)
  send_event('hourly_gen_today', series: series, displayedValue: "#{gen_hourly_wh.to_i}")
end

