require 'sequel'
require 'time'
require 'date'
require 'logger'
require_relative 'egauge'

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
LOGGER = Logger.new($stderr)
LOGGER.level = Logger::INFO

Egauge.configure do |config|
  config.url = 'http://sol.borg.lan'
end

Sequel.extension :migration
DB = Sequel.connect(adapter: 'postgres', database: DATABASE,
                    user: 'aaron',
                    logger: LOGGER, sql_log_level: :debug)

migration_path = File.expand_path('../../db/migrate', __FILE__)
Sequel::Migrator.run(DB, migration_path)
