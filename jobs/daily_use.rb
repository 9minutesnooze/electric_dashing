require_relative '../lib/common.rb'

# graph of hourly usage for today
SCHEDULER.every '1m', first_in: 0 do
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date(time) as "date"
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date(time) > now() - interval '7 days'
    GROUP BY date(time)
    ORDER BY date(time)
  SQL

  current_points = DB[query, USAGE_REGISTER].map do |row|
    { x: row[:date].to_time.to_i, y: row[:watt_hours].to_i }
  end

  send_event('daily_use', points: current_points)
end

