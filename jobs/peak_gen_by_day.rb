require_relative '../lib/common'

# Top 5 list of peak generation days
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


