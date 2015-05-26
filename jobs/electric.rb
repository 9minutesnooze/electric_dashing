require 'sequel'
require 'time'
require 'date'

def generation_since(start, register_id)
  query = 'select sum(watt_hours) as sum_wh from series where time >= ? and register_id = ?'
  result = DB[query, start, register_id].first
  result.any? ? result[:sum_wh].abs.round(1) : 0
end


DATABASE = 'solar'
REGISTER = 'gen'
DB = Sequel.connect(adapter: 'postgres', user: 'aaron', database: DATABASE)

SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  hour_start  = Time.mktime(now.year,now.month,now.day,now.hour)
  today_start = now.to_date.to_time
  year_start  = Time.mktime(now.year)
  month_start = Time.mktime(now.year,now.month)
  register_id = DB[:registers].where(name: REGISTER).first[:id]

  gen_hour_wh  = generation_since(hour_start, register_id)
  gen_today_wh = generation_since(today_start, register_id)
  gen_mtd_wh   = generation_since(month_start, register_id)
  gen_ytd_wh   = generation_since(year_start, register_id)

  send_event('gen_hour', value: gen_hour_wh)
  send_event('gen_today', value: gen_today_wh)
  send_event('gen_mtd', value: gen_mtd_wh)
  send_event('gen_ytd', value: gen_ytd_wh)
end

SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_part('hour', time) as hour
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date(time) = date(now())
      AND date_part('hour', time) BETWEEN 5 AND 22
    GROUP BY date_part('hour', time)
    ORDER BY date_part('hour', time)
  SQL
  results = DB[query, REGISTER]
  points = results.map do |row|
    unix_time = Time.mktime(now.year,now.month,now.day,row[:hour].to_i).to_i
    { x: unix_time, y: row[:watt_hours].to_i }
  end

  send_event('hourly_gen_today', points: points)
end

SCHEDULER.every '1d', first_in: 0 do
  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_trunc('month', time) as month
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND time > now() - interval '1 year'
    GROUP BY date_trunc('month', time)
    ORDER BY date_trunc('month', time)
  SQL

  results = DB[query, REGISTER]
  points = results.map do |row|
    unix_time = row[:month].to_i
    { x: unix_time, y: row[:watt_hours].to_i }
  end

  send_event('monthly_gen_year', points: points)
end

SCHEDULER.every '1h', first_in: 0 do
  register_id = DB[:registers].where(name: REGISTER).first[:id]

  query = <<-SQL
    select abs(sum(watt_hours)) as sum_wh, date(time) as date
    from series
    where register_id = ?
    group by date(time)
    order by abs(sum(watt_hours)) desc
    limit 5
  SQL

  result = DB[query, register_id].all
  i = 0
  msg = result.map do |row|
    i += 1
    kwh = (row[:sum_wh]/1000).round(1)
    sprintf("%d. %s (%.1f kWh)", i, row[:date], kwh)
  end

  msg.unshift '<div>'
  msg.push '</div>'
  send_event('peak_gen_by_day', text: msg.join("<br/>"))
end


