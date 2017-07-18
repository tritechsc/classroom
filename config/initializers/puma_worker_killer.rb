# frozen_string_literal: true

if Rails.env.production?
  PumaWorkerKiller.config do |config|
    config.ram           = Integer(ENV["DYNO_RAM"] || 512) # mb
    config.frequency     = 5 # seconds
    config.percent_usage = 0.99
    config.rolling_restart_frequency = 12 * 3600 # 12 hours in seconds
  end
  PumaWorkerKiller.start
end
