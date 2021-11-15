conf = Rails.application.config_for(:redis)["market"]
REDIS = Redis.new(conf)
