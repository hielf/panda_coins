conf = Rails.application.config_for(:redis)["trade"]
REDIS = Redis.new(conf)
