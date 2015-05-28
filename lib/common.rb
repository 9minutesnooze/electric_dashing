require 'sequel'
require 'time'
require 'date'

def generation_since(start, register_name)
  query = <<-SQL
    select sum(watt_hours) as sum_wh
    from series s
    join registers r
      ON r.id = s.register_id
    where time >= ?
      and r.name = ?
  SQL
  result = DB[query, start, register_name].first
  result[:sum_wh].nil? ? 0 : result[:sum_wh].abs.round(1)
end


DATABASE = 'solar'
REGISTER = 'gen'
USAGE_REGISTER = 'use'
DB = Sequel.connect(adapter: 'postgres', user: 'aaron', database: DATABASE)

