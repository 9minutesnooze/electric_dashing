require_relative '../lib/common'

# graph of yearly usage YTD
SCHEDULER.every '1h', first_in: '5s' do
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_part('year', time) as year
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date_part('doy', time) <= date_part('doy', now())
    GROUP BY date_part('year', time)
    ORDER BY date_part('year', time)
  SQL
  results = DB[query, USAGE_REGISTER]
  points = results.map do |row|
    unix_time = Time.mktime(row[:year]).to_i
    { x: unix_time, y: row[:watt_hours].to_i }
  end
  # graph doesn't zoom out to years unless there are three years worth
  # to show, so add an empty earlier year
  while points.size < 3
    first_year = Time.at(points.first[:x]).year - 1
    points.unshift(x: Time.mktime(first_year).to_i, y: 0)
  end

  send_event('yearly_use_ytd', points: points)
end

