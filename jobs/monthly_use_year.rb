require_relative '../lib/common'

# Generation by month graph
SCHEDULER.every '1h', first_in: '15s' do
  now = Time.new
  results = DB[:registers].select(:id).where(name: USAGE_REGISTER).first
  register_id = results[:id]

  # postgres is bad at select distinct queries.  Use a recursive query
  # http://zogovic.com/post/44856908222/optimizing-postgresql-query-for-distinct-values 
  query = <<-SQL
    WITH RECURSIVE t(n) AS (
      SELECT min(date_part('year',time))
      FROM series
      WHERE register_id = ?
      UNION
      SELECT (
        SELECT date_part('year',time)
        FROM series WHERE date_part('year',time) > n
          AND register_id = ?
        ORDER BY date_part('year',time)
        LIMIT 1
      )
      FROM t WHERE n IS NOT NULL
    )
    SELECT n as year FROM t WHERE n IS NOT NULL ORDER BY n DESC;
  SQL

  years = DB[query, register_id, register_id].map { |row| row[:year].to_i }

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
  use_mtd_wh = generation_since(month_start, USAGE_REGISTER)

  series = years.map do |year|
    results = DB[query, USAGE_REGISTER, year]

    points = results.map do |row|
      normalized_time = Time.new(now.year, row[:month].month)
      unix_time = normalized_time.to_i
      { x: unix_time, y: row[:watt_hours].to_i }
    end

    { name: year.to_s,
      data: points }
  end

  send_event('monthly_use_year', series: series, displayedValue: "#{use_mtd_wh.to_i/1000}K")
end

