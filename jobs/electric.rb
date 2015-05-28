require_relative '../lib/common.rb'

SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  today_start = now.to_date.to_time
  year_start  = Time.mktime(now.year)

  gen_today_wh = generation_since(today_start, REGISTER)
  use_today_wh = generation_since(today_start, USAGE_REGISTER)
  gen_ytd_wh   = generation_since(year_start, REGISTER)

  send_event('gen_today', value: gen_today_wh)
  send_event('use_today', value: use_today_wh)
  send_event('gen_ytd', value: gen_ytd_wh)
end
