require_relative '../lib/common.rb'

# graph of hourly usage for today
SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_part('hour', time) as hour
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date(time) = date(now())
    GROUP BY date_part('hour', time)
    ORDER BY date_part('hour', time)
  SQL
  results = DB[query, USAGE_REGISTER]
  current_points = results.map do |row|
    unix_time = Time.mktime(now.year,now.month,now.day,row[:hour].to_i).to_i
    { x: unix_time, y: row[:watt_hours].to_i }
  end

  send_event('hourly_use_today', points: current_points)
end

