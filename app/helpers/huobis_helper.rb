#export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# require 'net/ping'
# require 'pycall/import'
# include PyCall::Import
# require 'faye/websocket'
# require 'eventmachine'
# ApplicationController.helpers.huobi_tickers_cache
module HuobisHelper
# ["ethusdt", "btcusdt", "dogeusdt", "xrpusdt", "lunausdt", "adausdt", "bttusdt", "nftusdt", "dotusdt", "trxusdt", "icpusdt", "abtusdt", "skmusdt", "bhdusdt", "aacusdt", "canusdt", "fisusdt", "nhbtcusdt", "letusdt", "massusdt", "achusdt", "ringusdt", "stnusdt", "mtausdt", "itcusdt", "atpusdt", "gofusdt", "pvtusdt", "auctionus", "ocnusdt"]

  def usdts_symbols
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    list = huobi_pro.symbols["data"]
    usdts = []
    if list && list.any?
      list.each do |l|
        usdts << l if l["quote-currency"] == "usdt"
      end
    end

    usdts.each do |usdt|
      Rails.cache.redis.hset("symbols", usdt["symbol"], {"price-precision": usdt["price-precision"], "amount-precision": usdt["amount-precision"], "value-precision": usdt["value-precision"], "state": usdt["state"], "api-trading": usdt["api-trading"]})
    end

    return usdts.count
  end

  def huobi_tickers_cache
    url = "https://api.huobi.pro/market/tickers"
    Parallel.map([1, 2, 3], in_processes: 3) do |i|
      sleep i
      # raise Parallel::Break # -> stops after all current items are finished
      loop do
        sleep rand(0..0.5)
        # current_time = Time.zone.now.strftime('%H:%M')
        # p current_time
        res = Faraday.get url
        json = JSON.parse res.body
        ticker_time = Time.at(json["ts"]/1000)
        data = []
        json["data"].each do |d|
          if d["symbol"].end_with?("usdt")
            data << d
          end
        end

        # redis = Rails.cache.redis
        begin
          Rails.cache.write(ticker_time, data, expires_in: 2.minute)
          # redis.hset("tickers",ticker_time,data, expires_in: 2.minute)
        rescue Exception => e
          Rails.logger.warn e.message
        end
      end
      # Parallel::Stop
    end
    return true
  end

  # ApplicationController.helpers.huobi_tickers_check(Time.now - 120, Time.now)
  def huobi_tickers_check(start_time, end_time)
    start_time = Time.now.beginning_of_day - 2 if start_time.nil?
    end_time = Time.now if end_time.nil?
    keys = Rails.cache.redis.keys.sort
    times = []
    symbols = []
    keys.each do |key|
      times << key if (!key.to_time.nil? && key.to_time >= start_time && key.to_time <= end_time)
    end
    p times[0]
    begin
      data_s = Rails.cache.read(times[0])
      data_l = Rails.cache.read(times[-1])
      if data_s && !data_s.empty? && data_l && !data_l.empty?
        data_s.each do |ticker|
          symbol = ticker["symbol"]
          last = data_l.find {|x| x["symbol"] == symbol}
          change = (ticker["close"] == 0 ? 0 : (last["close"]-ticker["close"])/ticker["close"])
          Rails.cache.redis.hset("tickers", ticker["symbol"], {"time": times[-1], "open": ticker["close"], "close": last["close"], "change": change})
        end

        changes = Rails.cache.redis.hgetall("tickers")
        symbols = changes.find_all {|x| (eval x[1])[:change] >= ENV["up_floor_limit"].to_f}
      end
    rescue Exception => e
      Rails.logger.warn e.message
    end
    return symbols
  end

  def huobi_open_symbols(symbols)
    # symbols = ApplicationController.helpers.huobi_tickers_check(Time.now - 120, Time.now)
    start_time = Time.now - 10
    symbols.delete_if {|x| (eval x[1])[:time].to_time <= start_time}
    opened_symbols = Rails.cache.redis.hgetall("orders")
    if !opened_symbols.empty?
      opened_symbols.each do |sym|
        symbols.delete_if {|x| x[0] == sym[0]}
      end
    end

    # Parallel.each(symbols, in_thread: symbols.count) do |symbol|
    symbols.each do |symbol|
      huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
      tick = huobi_pro.merged(symbol[0])
      # tick = ApplicationController.helpers.huobi_symbol_ticker(symbol[0])
      ticker_time = Time.at(tick["ts"]/1000).to_s
      sym_data = eval symbol[1]
      change = (sym_data[:close] == 0 ? 0 : (tick["tick"]["close"]-sym_data[:close])/sym_data[:close])
      Rails.cache.redis.hset("orders", symbol[0], {"open_price": sym_data[:close], "current_price": tick["tick"]["close"], "change": change, "open_time": sym_data[:time], "current_time": ticker_time})
    end

    return symbols.count
  end

  def huobi_orders_check
    opened_symbols = Rails.cache.redis.hgetall("orders")
    # opened_symbols.each do |symbol|
    if opened_symbols && opened_symbols.any?
      Parallel.each(opened_symbols, in_thread: opened_symbols.count) do |symbol|
        redis = Redis.new(Rails.application.config_for(:redis))
        huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
        tick = huobi_pro.merged(symbol[0])
        ticker_time = Time.at(tick["ts"]/1000).to_s
        # p [symbol[0], ticker_time, tick["tick"]["close"]]
        sym_data = eval symbol[1]
        change = (sym_data[:open_price] == 0 ? 0 : (tick["tick"]["close"]-sym_data[:open_price])/sym_data[:open_price])
        redis.hset("orders", symbol[0], {"open_price": sym_data[:open_price], "current_price": tick["tick"]["close"], "change": change, "open_time": sym_data[:open_time], "current_time": ticker_time})

        pnl = change.truncate(4)
        Rails.logger.warn "#{symbol[0]} pnl: #{pnl}"
        redis.rpush("pnl:#{symbol[0]}", pnl)
        redis.quit
      end
    end

    return opened_symbols.count
  end

  def huobi_pnls(symbol)
    pnls = Rails.cache.redis.lrange("pnl:#{symbol}", 0, -1)
    return pnls.map(&:to_f)
  end

  def huobi_orders_close
    # 1 down limit
    count = 0
    data = Rails.cache.redis.hgetall("orders")
    orders = data.find_all {|x| (eval x[1])[:change] <= ENV["down_limit"].to_f}

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        begin
          ApplicationController.helpers.huobi_orders_log(symbol)
          Rails.cache.redis.hdel("orders", symbol)
        rescue Exception => e
          Rails.logger.warn e.message
        ensure
          ApplicationController.helpers.huobi_pnls_log(symbol, pnls)
          Rails.cache.redis.del("pnl:#{symbol}")
          Rails.logger.warn "#{symbol} closed due to down limit"
        end

        count = count + 1
      end
    end

    # 2 up_limit
    data = Rails.cache.redis.hgetall("orders")
    orders = data.find_all {|x| (eval x[1])[:change] > ENV["up_limit"].to_f}

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        begin
          ApplicationController.helpers.huobi_orders_log(symbol)
          Rails.cache.redis.hdel("orders", symbol)
        rescue Exception => e
          Rails.logger.warn e.message
        ensure
          ApplicationController.helpers.huobi_pnls_log(symbol, pnls)
          Rails.cache.redis.del("pnl:#{symbol}")
          Rails.logger.warn "#{symbol} closed due to up limit"
        end

        count = count + 1
      end
    end

    # 3 pnl_limit
    data = Rails.cache.redis.hgetall("orders")
    orders = data

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        pnls = ApplicationController.helpers.huobi_pnls(symbol)
        pnl_samples = (pnls.select.with_index{|_,i| (i+1) % ENV["pnl_interval"].to_i == 0}).last(3)

        if pnl_samples.any? && pnl_samples.sort.reverse == pnl_samples
          begin
            ApplicationController.helpers.huobi_orders_log(symbol)
            Rails.cache.redis.hdel("orders", symbol)
          rescue Exception => e
            Rails.logger.warn e.message
          ensure
            ApplicationController.helpers.huobi_pnls_log(symbol, pnls)
            # Rails.cache.redis.del("pnl:#{symbol}")
            Rails.logger.warn "#{symbol} closed due to pnl limit"
          end
        end

        count = count + 1
      end
    end

    return count
  end

  def huobi_orders_log(symbol)
    begin
      order = Rails.cache.redis.hget("orders", symbol)
      el = EventLog.new(eval order)
      el.symbol = symbol
      el.save
    rescue Exception => e
      Rails.logger.warn e.message
    end
  end

  def huobi_pnls_log(symbol, pnls)
    begin
      pnls.each do |change|
        ProfitLoss.create(symbol: symbol, change: change)
      end
    rescue Exception => e
      Rails.logger.warn e.message
    end
  end

  def huobi_symbol_ticker(symbol)
    url = "https://api.huobi.pro/market/detail/merged?symbol=#{symbol}"
    tick = false
    begin
      res = Faraday.get url
      json = JSON.parse res.body
      ticker_time = Time.at(json["ts"]/1000)
      tick = json["tick"]
      tick["ticker_time"] = ticker_time
    rescue Exception => e
      Rails.logger.warn e.message
    end
    return tick
  end

  def huobi_data_insert
    table_name = "huobi_start_1min"
    dir = Rails.root.to_s + "/lib/python/cryptocurrency/"
    his_dir = Rails.root.to_s + "/lib/python/cryptocurrency/his/"
    total = 0

    Dir.entries(dir).sort.each do |d|
      next if d == '.' or d == '..'
      fpath = dir + d
      # p path if File.file?(path)
      if File.extname(fpath) == ".csv"
        file_name = File.basename(fpath, File.extname(fpath))
        currency = file_name.split('_')[0]
        date = file_name.split('_')[1]
        csv_text = File.read(fpath)
        csv = CSV.parse(csv_text, :headers => true)
        count = 0

        p file_name

        begin
          postgres = PG.connect :host => ENV['quant_db_host'], :port => ENV['quant_db_port'], :dbname => ENV['quant_db_name'], :user => ENV['quant_db_user'], :password => ENV['quant_db_pwd']
          csv.each do |row|
            sql = "insert into #{table_name} select '#{currency}', '#{row[0]}', #{row[1]}, #{row[2]}, #{row[3]}, #{row[4]}, #{row[5]}, #{row[6]} WHERE NOT EXISTS (select '#{currency}', '#{row[0]}' from #{table_name} where contract = '#{currency}' and date = '#{row[0]}');"
            postgres.exec(sql)
            p sql
            count = count + 1
          end
        rescue PG::Error => e
          Rails.logger.warn e.message
        ensure
          p "#{count} inserted"
          postgres.close if postgres

          FileUtils.mv(fpath, his_dir + d)
          total = count + total
        end
      end
    end

    return total
  end

  def huobi_tickers
    contracts = []
    filepath = Rails.root.to_s + "/tmp/contracts.json"
    url = "https://api.huobi.pro/market/tickers"

    loop do
      current_time = Time.zone.now.strftime('%H:%M')
      p current_time
      if (current_time >= "00:00" && current_time < "00:01")
        res = Faraday.get url
        json = JSON.parse res.body
        ticker_time = Time.at(json["ts"]/1000).to_s
        if !contracts.any?{|d| d["time"] == ticker_time}
          hash = {}
          data = []
          json["data"].each do |d|
            if d["symbol"].end_with?("usdt")
              data << d
            end
          end
          hash["time"] = ticker_time
          hash["data"] = data
          contracts << hash
        end
      elsif current_time == "00:01"
        p "end"
        break
      end
      sleep 0.1
    end

    File.write(filepath, JSON.dump(contracts))

    return filepath
  end

  def huobi_ticker_insert(filepath)
    f = File.open filepath
    json_data = JSON.load f
    table_name = "huobi_tickers"

    begin
      postgres = PG.connect :host => ENV['quant_db_host'], :port => ENV['quant_db_port'], :dbname => ENV['quant_db_name'], :user => ENV['quant_db_user'], :password => ENV['quant_db_pwd']
      json_data.each do |time|
        time["data"].each do |d|
          sql = "insert into #{table_name} select '#{d["symbol"]}', '#{time["time"]}', '#{d["open"]}', #{d["high"]}, #{d["low"]}, #{d["close"]}, #{d["vol"]}, #{d["amount"]}, #{d["count"]}, #{d["bid"]}, #{d["bidSize"]}, #{d["ask"]}, #{d["askSize"]} WHERE NOT EXISTS (select '#{d["symbol"]}', '#{time["time"]}' from #{table_name} where symbol = '#{d["symbol"]}' and time = '#{time["time"]}');"
          postgres.exec(sql)
          p sql
        end
      end
    rescue PG::Error => e
      Rails.logger.warn e.message
    ensure
      postgres.close if postgres
    end
  end

  # sql = "CREATE TABLE public.#{table_name} (symbol varchar, time timestamp, open float8, high float8, low float8, close float8, vol float8, amount float8, count int8, bid float8, bidSize float8, ask float8, askSize float8);"
  # res = postgres.exec(sql)
  # sql = "CREATE UNIQUE INDEX #{table_name}_idx ON public.#{table_name} (symbol, time);"
  # res = postgres.exec(sql)

  # def ws_client
  #   WebSocket::Client::Simple.connect 'wss://api.huobi.pro/ws' do |ws|
  #     ws.on :open do
  #       puts "connect!"
  #     end
  #
  #     ws.on :message do |msg|
  #       puts msg.data
  #     end
  #   end
  #
  #
  #   EM.run {
  #     ws = Faye::WebSocket::Client.new('wss://api.huobi.pro/ws', [], :tls => {
  #       :verify_peer => false
  #     })
  #
  #     ws.on :open do |event|
  #       p [:open]
  #       ws.send({
  #               "req": "market.btcusdt.kline.1min",
  #               "id": "id1",
  #               "from": 1629129608,
  #               "to": 1629131336,
  #           }.to_json)
  #     end
  #
  #     ws.on :message do |event|
  #       # data = {"pong": event.data['ping']}
  #       # ws.send(data)
  #       # p [:message, event.data]
  #       # buf = ActiveSupport::Gzip.decompress(event.data)
  #       p [:message, event.data]
  #     end
  #
  #     ws.on :close do |event|
  #       p [:close, event.code, event.reason]
  #       ws = nil
  #     end
  #   }
  #
  #   App = lambda do |env|
  #     if Faye::WebSocket.websocket?(env)
  #       # ws = Faye::WebSocket.new(env)
  #       ws = Faye::WebSocket::Client.new('wss://api.huobi.pro/ws', [], :tls => {
  #         :verify_peer => false
  #       })
  #
  #       ws.on :message do |event|
  #         p event
  #         ws.send(event.data)
  #       end
  #
  #       ws.on :close do |event|
  #         p [:close, event.code, event.reason]
  #         ws = nil
  #       end
  #
  #       # Return async Rack response
  #       ws.rack_response
  #
  #     else
  #       # Normal HTTP request
  #       [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  #     end
  #   end
  # end

end
