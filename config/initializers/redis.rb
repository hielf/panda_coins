conf = Rails.application.config_for(:redis)
REDIS = Redis.new(conf)
