require_relative '../lib/common'

# Generation by month graph
SCHEDULER.every '1h', first_in: '15s' do
  now = Time.new
  query = <<-SQL
    SELECT distinct date_part('year', time) AS year
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
    ORDER BY date_part('year', time) DESC
  SQL

  years = DB[query, REGISTER].map { |row| row[:year].to_i }

  query = <<-SQL
    SELECT abs(sum(watt_hours)) as watt_hours, date_trunc('month', time) as month
    FROM series s
    JOIN registers r
      ON r.id = s.register_id
    WHERE r.name = ?
      AND date_part('year', time) = ?
    GROUP BY date_trunc('month', time)
    ORDER BY date_trunc('month', time)
  SQL

  now = Time.new
  month_start = Time.mktime(now.year,now.month)
  gen_mtd_wh = generation_since(month_start, REGISTER)

  series = years.map do |year|
    results = DB[query, REGISTER, year]

    points = results.map do |row|
      normalized_time = Time.new(now.year, row[:month].month)
      unix_time = normalized_time.to_i
      { x: unix_time, y: row[:watt_hours].to_i }
    end

    { name: year.to_s,
      data: points }
  end

  send_event('monthly_gen_year', series: series, displayedValue: "#{gen_mtd_wh.to_i/1000}K")
end

