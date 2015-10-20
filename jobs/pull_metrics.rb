#!/usr/bin/env ruby

require_relative '../lib/common'

SCHEDULER.every '1m', first_in: 0 do
  now = Time.new
  today = now.to_date
  history = Egauge::History.new(DB, register_names: %w(use gen))
  epoch = history.epoch
  last_sync_time = history.last_sync_time
  start_date = last_sync_time.nil? ? epoch.to_date : last_sync_time.to_date

  if start_date == today
    LOGGER.info "Last synced at #{last_sync_time}. Pulling new metrics until #{now}..."
    # don't bother batching for less than a day
    h = history.load(time_from: last_sync_time + 1, time_until: now, units: Egauge::REQ_UNIT_MINUTES)
    h.each { |register| register.write(DB) }
  else
    start_date.upto(Date.today) do |date|
      start_t = date.to_time
      # assumes second granularity
      end_t = [(Time.new-60), ((date + 1).to_time)].min
      LOGGER.info "Loading from #{start_t} until #{end_t}"

      history = Egauge::History.new(DB)
      h = history.load(time_from: start_t, time_until: end_t,
                      units: Egauge::REQ_UNIT_MINUTES)

      h.each { |register| register.write(DB) }
    end
  end
end
