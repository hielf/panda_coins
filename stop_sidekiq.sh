ps -ef | grep sidekiq | grep -v grep | awk '{print $2}' | xargs kill -TSTP

sleep 10

ps -ef | grep sidekiq | grep -v grep | awk '{print $2}' | xargs kill -TERM
