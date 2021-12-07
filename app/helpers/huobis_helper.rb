#export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# require 'net/ping'
# require 'pycall/import'
# include PyCall::Import
# require 'faye/websocket'
# require 'eventmachine'
# ApplicationController.helpers.huobi_tickers_cache

module HuobisHelper
  # ApplicationController.helpers.huobi_close_all
  def huobi_close_all
    ApplicationController.helpers.usdts_symbols
    @account_id, @status = ApplicationController.helpers.huobi_balances
    @trader_balances = TraderBalance.where("balance > ?", 0.0001)
    symbol = ""
    @trader_balances.each do |tb|
      if tb.currency != "usdt"
        symbol = tb.currency + "usdt"
        # @count_match = ApplicationController.helpers.huobi_histroy_matchresults(symbol)
        # @account_id, @status = ApplicationController.helpers.huobi_balances
        amount, shares_amount = ApplicationController.helpers.huobi_close_amount(symbol, 1)
        p [symbol, amount]
        OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
        sleep 0.3
      end
    end
  end
# ["ethusdt", "btcusdt", "dogeusdt", "xrpusdt", "lunausdt", "adausdt", "bttusdt", "nftusdt", "dotusdt", "trxusdt", "icpusdt", "abtusdt", "skmusdt", "bhdusdt", "aacusdt", "canusdt", "fisusdt", "nhbtcusdt", "letusdt", "massusdt", "achusdt", "ringusdt", "stnusdt", "mtausdt", "itcusdt", "atpusdt", "gofusdt", "pvtusdt", "auctionus", "ocnusdt"]
  # ApplicationController.helpers.white_list
  def white_list
    symbols = []
    usdts = Rails.cache.redis.hgetall("symbols")
    settings = TraderSetting.current_settings
    black_list = SymbolList.black_list

    usdts.each do |usdt|
      hash = eval usdt[1]
      precision = hash[:"amount-precision"]
      sell_market_min_order_amt = hash[:"sell-market-min-order-amt"]
      sell_market_max_order_amt = hash[:"sell-market-max-order-amt"]
      state = hash[:"state"]
      api_trading = hash[:"api-trading"]
      listing_date = hash[:"listing-date"]
      if !black_list.map(&:symbol).include? usdt[0]
        symbols << usdt[0] if state == "online" && api_trading == "enabled" && listing_date.to_date <= settings.days_after_symbol_listing.to_i.days.ago
      end
    end
    # symbols = ['aacusdt','achusdt','ankrusdt','bsvusdt','cnnsusdt','creusdt','bixusdt','dacusdt','ektusdt','ethusdt','fildausdt','flowusdt','gxcusdt','ltc3susdt','mirusdt','mtausdt','mxcusdt','nasusdt','nbsusdt','neousdt','phausdt','skmusdt','steemusdt','utkusdt','wnxmusdt','xrp3lusdt','zilusdt','1inchusdt','aaveusdt','abtusdt','adausdt','aeusdt','akrousdt','antusdt','api3usdt','apnusdt','arusdt','atomusdt','axsusdt','bagsusdt','batusdt','bch3lusdt','bethusdt','bhdusdt','blzusdt','bntusdt','btc1susdt','btc3susdt','btmusdt','bttusdt','ckbusdt','cmtusdt','cruusdt','crvusdt','csprusdt','ctsiusdt','dashusdt','dfusdt','dkausdt','dogeusdt','dot2susdt','dotusdt','egtusdt','elausdt','elfusdt','eos3lusdt','eosusdt','etcusdt','eth1susdt','firousdt','fisusdt','forthusdt','forusdt','fttusdt','gnxusdt','grtusdt','gtusdt','hbcusdt','hitusdt','hptusdt','icpusdt','icxusdt','iostusdt','fsnusdt','pondusdt','actusdt','algousdt','arpausdt','astusdt','atpusdt','auctionusdt','avaxusdt','badgerusdt','balusdt','bandusdt','bch3susdt','bchusdt','bsv3lusdt','bsv3susdt','iotxusdt','irisusdt','itcusdt','jstusdt','kanusdt','kcashusdt','kncusdt','ksmusdt','lambusdt','latusdt','lbausdt','lhbusdt','linausdt','linkusdt','lrcusdt','ltc3lusdt','ltcusdt','lunausdt','manausdt','massusdt','maticusdt','mdxusdt','mlnusdt','mxusdt','newusdt','nftusdt','nknusdt','nsureusdt','o3usdt','ognusdt','ogousdt','oneusdt','polsusdt','btc3lusdt','btcusdt','btsusdt','canusdt','chrusdt','chzusdt','compusdt','crousdt','ctxcusdt','cvcusdt','cvpusdt','daiusdt','dcrusdt','dhtusdt','dockusdt','dot2lusdt','dtausdt','emusdt','enjusdt','eos3susdt','eth3lusdt','eth3susdt','fil3lusdt','filusdt','frontusdt','ftiusdt','glmusdt','gofusdt','hbarusdt','hcusdt','hiveusdt','hotusdt','htusdt','injusdt','insurusdt','iotausdt','kavausdt','letusdt','link3lusdt','link3susdt','lolusdt','loomusdt','lxtusdt','maskusdt','mdsusdt','mkrusdt','nanousdt','nearusdt','nestusdt','nexousdt','nhbtcusdt','nodeusdt','nulsusdt','nuusdt','ocnusdt','omgusdt','ontusdt','oxtusdt','paiusdt','paxusdt','pearlusdt','pvtusdt','qtumusdt','raiusdt','reefusdt','renusdt','ringusdt','rlcusdt','rndrusdt','rsrusdt','ruffusdt','topusdt','trbusdt','trxusdt','ttusdt','uipusdt','umausdt','uni2lusdt','uni2susdt','uniusdt','usdcusdt','uuuusdt','valueusdt','vetusdt','vidyusdt','vsysusdt','wavesusdt','waxpusdt','wbtcusdt','wiccusdt','woousdt','wtcusdt','wxtusdt','xchusdt','xemusdt','rvnusdt','sandusdt','scusdt','seeleusdt','shibusdt','sklusdt','smtusdt','sntusdt','snxusdt','socusdt','solusdt','stakeusdt','stnusdt','storjusdt','stptusdt','sunusdt','sushiusdt','swftcusdt','swrvusdt','thetausdt','titanusdt','tnbusdt','xlmusdt','xmrusdt','xmxusdt','xrpusdt','xrtusdt','xtzusdt','yamusdt','yeeusdt','yfiiusdt','yfiusdt','zec3lusdt','zec3susdt','zecusdt','zenusdt','zksusdt','zrxusdt']
    return symbols
  end

  def usdts_symbols
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    list = huobi_pro.symbols["data"]
    usdts = []
    if list && list.any?
      list.each do |l|
        usdts << l if l["quote-currency"] == "usdt"
      end
    end

   #  {"base-currency"=>"em", "quote-currency"=>"usdt",
   #    "price-precision"=>6, "amount-precision"=>2,
   #    "symbol-partition"=>"innovation", "symbol"=>"emusdt",
   #    "state"=>"online", "value-precision
   # "=>8, "min-order-amt"=>1, "max-order-amt"=>120000000,
   # "min-order-value"=>5, "limit-order-min-order-amt"=>1,
   # "limit-order-max-order-amt"=>120000000,
   # "limit-order-max-buy-amt"=>120000000,
   # "limit-order-max
   # -sell-amt"=>120000000, "sell-market-min-order-amt"=>1,
   # "sell-market-max-order-amt"=>12000000,
   # "buy-market-max-order-value"=>70000,
   # "api-trading"=>"enabled", "tags"=>""}

    usdts.each do |usdt|
      if SymbolList.find_by(symbol: usdt["symbol"]).nil?
        begin
          SymbolList.create(symbol: usdt["symbol"], listing_date: Date.today)
        rescue Exception => e
          Rails.logger.warn "usdts_symbols error: #{e.message}"
        end
      end

      symbol = SymbolList.find_by(symbol: usdt["symbol"])

      Rails.cache.redis.hset("symbols", usdt["symbol"],
        {"price-precision": usdt["price-precision"],
          "amount-precision": usdt["amount-precision"],
          "value-precision": usdt["value-precision"],
          "min-order-amt": usdt["min-order-amt"],
          "min-order-value": usdt["min-order-value"],
          "limit-order-min-order-amt": usdt["limit-order-min-order-amt"],
          "limit-order-max-order-amt": usdt["limit-order-max-order-amt"],
          "limit-order-max-buy-amt": usdt["limit-order-max-buy-amt"],
          "limit-order-max-sell-amt": usdt["limit-order-max-sell-amt"],
          "sell-market-min-order-amt": usdt["sell-market-min-order-amt"],
          "sell-market-max-order-amt": usdt["sell-market-max-order-amt"],
          "buy-market-max-order-value": usdt["buy-market-max-order-value"],
          "state": usdt["state"],
          "api-trading": usdt["api-trading"],
          "listing-date": symbol.listing_date.to_s})
    end

    return usdts.count
  end

  def huobi_tickers_cache
    url = "https://api.huobi.pro/market/tickers"
    Parallel.map([0, 1, 2], in_processes: 3) do |i|
      # raise Parallel::Break # -> stops after all current items are finished
      loop do
        if Time.now.sec.to_s.end_with? ENV["collect_sec"]
          sleep 4 if i == 1
          sleep 8 if i == 2
          # p "time_#{i.to_s}: #{Time.now}"
          res = Faraday.get url
          json = JSON.parse res.body
          ticker_time = Time.at(json["ts"]/1000)
          data = []
          json["data"].each do |d|
            if d["symbol"].end_with?("usdt")
              data << d
            end
          end
          # p "ticker_#{i.to_s}: #{ticker_time}"
          # redis = Rails.cache.redis
          begin
            Rails.cache.write(ticker_time, data, expires_in: 300.seconds)
            # redis.hset("tickers",ticker_time,data, expires_in: 2.minute)
            sleep 1
          rescue Exception => e
            Rails.logger.warn "huobi_tickers_cache: #{e.message}"
          end
        end
      end
      # Parallel::Stop
    end
    return true
  end

  # ApplicationController.helpers.huobi_tickers_cache_ws
  def huobi_tickers_cache_ws
    white_list_symbols = ApplicationController.helpers.white_list
    data = Set.new
    Rails.cache.redis.del("tickers_latest")
    loop do
      t = (Time.now - 1).strftime('%Y-%m-%d %H:%M:%S +0800')
      redis = Redis.new(Rails.application.config_for(:redis)["market"])
      # keys = redis.keys.sort
      # tick = redis.mget(keys.last)
      white_list_symbols.each do |symbol|
        h = {:symbol => symbol}
        ticker = "tickers_data:market.#{symbol}.ticker:#{t}"
        begin
          tick = redis.get(ticker)
          if tick.nil?
            # symbol_tickers = keys.find_all {|x| x.include? "tickers_data:market.#{symbol}.ticker"}
            # next if symbol_tickers.empty?
            # tick = Rails.cache.read(symbol_tickers[-1])
            s = Rails.cache.redis.hget("tickers_latest", symbol)
            tick = {:tick => (eval s)} if !s.nil?
          else
            tick = eval tick
          end
          if tick && !tick.empty?
            h.merge!(tick[:tick])
            data << h
          end
        rescue Exception => e
          # p e
          # p [symbol, tick]
          Rails.logger.warn "huobi_tickers_cache_ws error: #{symbol} #{e.message}"
        ensure
          Rails.cache.redis.hset("tickers_latest", symbol, tick[:tick]) if (tick && !tick.empty?)
        end
      end
      delay = 930
      if (t.to_time.hour == 0 && t.to_time.min == 0 && t.to_time.sec <= 1)
        delay = 24 * 60 * 60
      end
      Rails.cache.write("#{t}", data, expires_in: delay.seconds)
      data.clear
      redis.quit
      sleep 0.2
    end
  end

  # ApplicationController.helpers.huobi_tickers_check(settings, Time.now - 120, Time.now)
  def huobi_tickers_check(settings, start_time, end_time)
    start_time = Time.now.beginning_of_day if start_time.nil?
    end_time = Time.now if end_time.nil?
    current_time = Time.now.strftime("%H:%M")
    keys = Rails.cache.redis.keys.sort
    times = []
    symbols = []
    white_list_symbols = ApplicationController.helpers.white_list
    # current_trades = Rails.cache.redis.hgetall("trades")
    # settings = TraderSetting.current_settings
    keys.each do |key|
      times << key if (!(key.count("a-zA-Z") > 0) && (DateTime.parse key rescue nil) && key.to_time >= start_time && key.to_time <= end_time)
    end
    # p times[0]
    if times && times.any?
      begin
        data_s = Rails.cache.read(times[0])
        data_l = Rails.cache.read(times[-1])
        if data_s && !data_s.empty? && data_l && !data_l.empty?
          data_s.each do |ticker|
            symbol = ticker[:symbol]
            next if !white_list_symbols.include? symbol

            last = data_l.find {|x| x[:symbol] == symbol}
            change = (ticker[:close] == 0 ? 0 : (last[:close]-ticker[:close])/ticker[:close])
            Rails.cache.redis.hset("tickers", ticker[:symbol], {"time": times[-1], "open": ticker[:close], "close": last[:close],  "amount": last[:amount],  "vol": ticker[:vol], "change": change})
          end

          changes = Rails.cache.redis.hgetall("tickers")

          # symbols1 = changes.find_all {|x| (eval x[1])[:change] >= settings.up_floor_limit.to_f && (eval x[1])[:change] <= settings.first_up_up_limit.to_f}
          # symbols1.sort_by! { |s| -(eval s[1])[:change] }
          # symbols2 = changes.find_all {|x| (eval x[1])[:change] >= settings.up_floor_limit.to_f && (eval x[1])[:change] <= settings.up_up_limit.to_f}
          #
          # if (current_trades.count == 0) && (current_time >= "00:00" && current_time <= settings.buy_accept_end_time) && !symbols1.empty?
          #   symbols = ([symbols1[0]] + symbols2).uniq
          # else
          #   symbols = symbols2
          # end

          symbols = changes.find_all {|x| (eval x[1])[:change] >= settings.up_floor_limit.to_f && (eval x[1])[:change] <= settings.up_up_limit.to_f && (eval x[1])[:vol] >= settings.amount_bottom_limit.to_f}
          symbols.sort_by! { |s| (eval s[1])[:change] }
        end
      rescue Exception => e
        Rails.logger.warn "huobi_tickers_check error: #{e.message}" unless (e.message.include? "[]")
      end
    end

    return symbols
  end

  def huobi_open_symbols(settings, symbols)
    # symbols = ApplicationController.helpers.huobi_tickers_check(Time.now - 120, Time.now)
    start_time = Time.now - 10
    # settings = TraderSetting.current_settings
    symbols.delete_if {|x| (eval x[1])[:time].to_time <= start_time}
    opened_symbols = Rails.cache.redis.hgetall("orders")
    begin
      if !opened_symbols.empty?
        opened_symbols.each do |sym|
          symbols.delete_if {|x| x[0] == sym[0]}
        end
      end
    rescue Exception => e
      Rails.logger.warn "huobi_open_symbols error: #{e.message}"
    end

    begin
      closed_symbols = EventLog.today.where(current_time: 24.hour.ago..Time.now)
      if closed_symbols && closed_symbols.any?
        closed_symbols.each do |sym|
          symbols.delete_if {|x| x[0] == sym.symbol}
        end
      end
      closed_symbols = Rails.cache.redis.hgetall("orders:closing")
      if closed_symbols && closed_symbols.any?
        closed_symbols.each do |sym|
          symbols.delete_if {|x| x[0] == sym[0]}
        end
      end
    rescue Exception => e
      Rails.logger.warn "huobi_open_symbols error: #{e.message}"
    end

    # Parallel.each(symbols, in_thread: symbols.count) do |symbol|
    openning_symbols = []
    symbols.each do |symbol|
      next if Rails.cache.read("enqueued:openning:#{symbol[0]}")
      Rails.cache.write("enqueued:openning:#{symbol[0]}", "openning", expires_in: settings.tickers_check_interval.to_i.second)
      # opened_symbols = Rails.cache.redis.hgetall("orders")
      if opened_symbols.count >= settings.max_opened_orders.to_i
        # symbols.delete_if {|x| x[0] == symbol[0]}
        Rails.logger.warn "skip openning: #{symbol[0]} due to reach max_opened_orders"
        # next
      else
        # huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
        # tick = huobi_pro.merged(symbol[0])
        redis = Redis.new(Rails.application.config_for(:redis)["market"])
        ticker_time = ""
        tick_str = Rails.cache.redis.hget("tickers_latest", symbol[0])
        tick = {:tick => (eval tick_str)} if !tick_str.nil?
        begin
          10.times do
            ticker_time = Time.now.strftime('%Y-%m-%d %H:%M:%S +0800')
            key = "tickers_data:market.#{symbol[0]}.ticker:#{ticker_time}"
            tick_str = redis.get(key)
            if !tick_str.nil?
              tick = eval tick_str
              break
            end
            sleep 0.05
          end
        rescue Exception => e
          Rails.logger.warn "huobi_open_symbols tick_str error: #{e.message}"
        ensure
          redis.quit
        end

        symbol_tendency = huobi_symbol_tendency_check(symbol[0], tick[:tick][:close])
        # next if (symbol_tendency.empty? || !symbol_tendency.all? { |x| x == 1 })
        next if (symbol_tendency.empty? || !(symbol_tendency[0] == 1))

        # ticker_time = Time.at(tick[:ts]/1000).to_s
        sym_data = eval symbol[1]
        change = (sym_data[:close] == 0 ? 0 : (tick[:tick][:close]-sym_data[:close])/sym_data[:close])
        change_open = (sym_data[:open] == 0 ? 0 : (tick[:tick][:close]-sym_data[:open])/sym_data[:open])
        Rails.cache.redis.hset("orders", symbol[0], {"open_price": sym_data[:close], "current_price": tick[:tick][:close], "change": change, "open_time": sym_data[:time], "current_time": ticker_time, "change_open": change_open, "first_price": sym_data[:open]})
        openning_symbols << symbol
      end
    end

    return openning_symbols.count, openning_symbols
  end

  def huobi_open_order(symbol, sym_data, settings)
    begin
      current_trades = Rails.cache.redis.hgetall("trades")
      last_balance = Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")))[:balance]
      divide_shares = settings.divide_shares.to_i
      use_balance = last_balance * settings.balance_proportion.to_f
      amount = (use_balance / divide_shares).truncate(0)

      if current_trades.count < divide_shares
        OrdersJob.perform_now symbol, 'buy-market', 0, amount, false
        Rails.logger.warn "symbol #{symbol} open @ #{sym_data[:close]} amount: #{amount}"
      else
        Rails.logger.warn "symbol #{symbol} open skipped: shares all used"
      end
    rescue Exception => e
      Rails.logger.warn "huobi_open_order error: #{e.message}"
    end
  end

  def huobi_symbol_tendency_check(symbol, close_0)
    flag = []
    data_1 = Set.new
    data_2 = Set.new

    begin
      (2..3).each do |i|
        time_1 = (Time.now - i).strftime('%Y-%m-%d %H:%M:%S +0800')
        data_1 = Rails.cache.read(time_1)
        break if data_1.any?
      end
    rescue Exception => e
      Rails.logger.warn "huobi_symbol_tendency_check data_1 error: #{e.message}"
    end

    begin
      (4..5).each do |i|
        time_2 = (Time.now - i).strftime('%Y-%m-%d %H:%M:%S +0800')
        data_2 = Rails.cache.read(time_2)
        break if data_2.any?
      end
    rescue Exception => e
      Rails.logger.warn "huobi_symbol_tendency_check data_2 error: #{e.message}"
    end

    begin
      # p close_0
      ticker_1 = data_1.find{|x| x[:symbol] == symbol}
      # p "ticker_1: #{ticker_1[:close]}"
      ticker_2 = data_2.find{|x| x[:symbol] == symbol}
      # p "ticker_2: #{ticker_2[:close]}"
      Rails.logger.warn "huobi_symbol_tendency_check #{symbol}: #{close_0} #{ticker_1[:close]} #{ticker_2[:close]}"

      flag1 = (close_0 > ticker_1[:close]) ? 1 : 0
      flag2 = (ticker_1[:close] > ticker_2[:close]) ? 1 : 0
      flag = [flag1, flag2]
    rescue Exception => e
      Rails.logger.warn "huobi_symbol_tendency_check flags error: #{e.message}"
    end

    return flag
  end

  def huobi_orders_check
    opened_symbols = Rails.cache.redis.hgetall("orders")
    threads = opened_symbols.count < 4 ? opened_symbols.count : 4
    if opened_symbols && opened_symbols.any?
      Parallel.each(opened_symbols, in_thread: threads) do |symbol|
      # opened_symbols.each do |symbol|
        begin
          redis = Redis.new(Rails.application.config_for(:redis)["trade"])
          huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
          tick = huobi_pro.merged(symbol[0])
          ticker_time = Time.at(tick["ts"]/1000).to_s
          # p [symbol[0], ticker_time, tick["tick"]["close"]]
          sym_data = eval symbol[1]
          change = (sym_data[:open_price] == 0 ? 0 : (tick["tick"]["close"]-sym_data[:open_price])/sym_data[:open_price])
          change_open = (sym_data[:first_price] == 0 ? 0 : (tick["tick"]["close"]-sym_data[:first_price])/sym_data[:first_price])
          if !redis.hget("orders", symbol[0]).nil?
            redis.hset("orders", symbol[0], {"open_price": sym_data[:open_price], "current_price": tick["tick"]["close"], "change": change, "open_time": sym_data[:open_time], "current_time": ticker_time, "change_open": change_open, "first_price": sym_data[:first_price]})
          end

          pnl = change.truncate(4)
          # Rails.logger.warn "#{symbol[0]} pnl: #{pnl}"
          # redis.rpush("pnl:#{symbol[0]}", pnl)
          # ticker_time = Time.now.to_s
          h = {:current_time => ticker_time, :change => pnl}
          # redis.sadd("pnl:#{symbol[0]}", h.to_s)
          redis.lrem("pnl:#{symbol[0]}", 0, h.to_s)
          redis.rpush("pnl:#{symbol[0]}", h.to_s)
          redis.quit
        rescue Exception => e
          Rails.logger.warn "huobi_orders_check error: #{e.message} #{symbol[0]} #{symbol[1]}"
        end
      end
    end

    return opened_symbols.count
  end

  def huobi_pnls(symbol)
    # pnls = Rails.cache.redis.smembers("pnl:#{symbol}")
    pnls = Rails.cache.redis.lrange("pnl:#{symbol}", 0, -1)
    # return pnls.map(&:to_f)
    return pnls
  end

  def huobi_close_amount(symbol, shares)
    amount = 0
    shares_amount = 0
    begin
      hash = eval Rails.cache.redis.hget("symbols", symbol)
      precision = hash[:"amount-precision"]
      sell_market_min_order_amt = hash[:"sell-market-min-order-amt"]
      sell_market_max_order_amt = hash[:"sell-market-max-order-amt"]
      listing_date = hash[:"listing-date"]
      # tr = TraderBalance.find_by(currency: symbol.sub("usdt",""), balance_type: 'trade')
      rbalance =  Rails.cache.redis.hget("balances", "#{symbol.sub("usdt","")}:trade")
      tr = (eval rbalance)[:balance] if rbalance
      balance = tr.to_d.truncate(precision).to_f if tr
      share_balance = (tr.to_d/shares).truncate(precision).to_f if tr
      balance = balance.to_i if precision == 0
      share_balance = (balance/shares).to_i if precision == 0

      if balance && balance < sell_market_min_order_amt
        amount = 0
        shares_amount = 0
      elsif balance && balance > sell_market_max_order_amt
        amount = sell_market_max_order_amt
        shares_amount = (sell_market_max_order_amt/shares)
      else
        amount = balance.nil? ? 0 : balance
        shares_amount = balance.nil? ? 0 : share_balance
      end
    rescue Exception => e
      Rails.logger.warn "huobi_close_amount error: #{e.message}"
    end
    return amount, shares_amount
  end

  def huobi_frozen_amount(symbol)
    amount = 0
    begin
      hash = eval Rails.cache.redis.hget("symbols", symbol)
      precision = hash[:"amount-precision"]
      sell_market_min_order_amt = hash[:"sell-market-min-order-amt"]
      sell_market_max_order_amt = hash[:"sell-market-max-order-amt"]
      listing_date = hash[:"listing-date"]
      # tr = TraderBalance.find_by(currency: symbol.sub("usdt",""), balance_type: 'trade')
      rbalance =  Rails.cache.redis.hget("balances", "#{symbol.sub("usdt","")}:frozen")
      tr = (eval rbalance)[:balance] if rbalance
      balance = tr.to_d.truncate(precision).to_f if tr
      balance = balance.to_i if precision == 0

      if balance && balance < sell_market_min_order_amt
        amount = 0
      elsif balance && balance > sell_market_max_order_amt
        amount = sell_market_max_order_amt
      else
        amount = balance.nil? ? 0 : balance
      end
    rescue Exception => e
      Rails.logger.warn "huobi_close_amount error: #{e.message}"
    end
    return amount
  end

  def huobi_orders_close(settings)
    count = 0
    closing_symbols = []
    # settings = TraderSetting.current_settings
    # 1 timer limit
    orders_data = Rails.cache.redis.hgetall("orders")
    orders = orders_data.find_all {|x| (eval x[1])[:open_time] <= settings.close_timer_up.to_i.seconds.ago}
    if settings.daily_clear_all_time && !settings.daily_clear_all_time.empty? && Time.now.strftime('%H:%M:%S') == settings.daily_clear_all_time
      orders = orders_data
    elsif Time.now.strftime("%H:%M:%S") == "23:59:55"
      orders = orders_data
    end

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        data = eval Rails.cache.redis.hget("orders", symbol)
        Rails.cache.redis.hset("orders:closing", symbol, data)
        Rails.cache.redis.hdel("orders", symbol)
        # Rails.logger.warn "huobi_orders_close 1 #{symbol}: deleted #{o}"
        closing_symbols << symbol if !closing_symbols.include?(symbol)

        count = count + 1
      end
    end

    # 2 down limit
    orders_data = Rails.cache.redis.hgetall("orders")
    orders = orders_data.find_all {|x| ((eval x[1])[:change] <= settings.down_limit.to_f) && (Time.now - (eval x[1])[:open_time].to_time >= settings.open_await_to_close_time.to_i)}

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        data = eval Rails.cache.redis.hget("orders", symbol)
        Rails.cache.redis.hset("orders:closing", symbol, data)
        Rails.cache.redis.hdel("orders", symbol)
        # Rails.logger.warn "huobi_orders_close 2 #{symbol}: deleted #{o}"
        closing_symbols << symbol if !closing_symbols.include?(symbol)

        count = count + 1
      end
    end

    # 2.5 change_open down limit
    orders_data = Rails.cache.redis.hgetall("orders")
    orders = orders_data.find_all {|x| ((eval x[1])[:change_open] <= settings.down_limit.to_f) && (Time.now - (eval x[1])[:open_time].to_time >= settings.open_await_to_close_time.to_i)}

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        data = eval Rails.cache.redis.hget("orders", symbol)
        Rails.cache.redis.hset("orders:closing", symbol, data)
        Rails.cache.redis.hdel("orders", symbol)
        # Rails.logger.warn "huobi_orders_close 2.5 #{symbol}: deleted #{o}"
        closing_symbols << symbol if !closing_symbols.include?(symbol)

        count = count + 1
      end
    end

    # 3 up_limit
    orders_data = Rails.cache.redis.hgetall("orders")
    orders = orders_data.find_all {|x| ((eval x[1])[:change] > settings.up_limit.to_f) && (Time.now - (eval x[1])[:open_time].to_time >= settings.open_await_to_close_time.to_i)}

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        data = eval Rails.cache.redis.hget("orders", symbol)
        Rails.cache.redis.hset("orders:closing", symbol, data)
        Rails.cache.redis.hdel("orders", symbol)
        # Rails.logger.warn "huobi_orders_close 3 #{symbol}: deleted #{o}"
        closing_symbols << symbol if !closing_symbols.include?(symbol)

        count = count + 1
      end
    end

    # 4 pnl_limit
    orders_data = Rails.cache.redis.hgetall("orders")
    orders = orders_data

    if orders && orders.any?
      orders.each do |order|
        symbol = order[0]
        data = eval Rails.cache.redis.hget("orders", symbol)
        pnls = ApplicationController.helpers.huobi_pnls(symbol)
        array = pnls.map{|x| (eval x)[:change]}
        # pnl_samples = (array.select.with_index{|_,i| (i+1) % settings.pnl_interval.to_i == 0}).last(3)

        # if pnl_samples.any? && pnl_samples.count == 3 && pnl_samples.sort.reverse == pnl_samples && pnl_samples[0] != pnl_samples[-1] && pnl_samples[1] != pnl_samples[-1]
        if array.any? && array.last - array.max < settings.max_down_limit.to_f
          Rails.cache.redis.hset("orders:closing", symbol, data)
          Rails.cache.redis.hdel("orders", symbol)
          closing_symbols << symbol if !closing_symbols.include?(symbol)
        end

        count = count + 1
      end
    end
    return count, closing_symbols
  end

  def huobi_orders_log(symbol, data)
    begin
      # order = Rails.cache.redis.hget("orders", symbol)
      # Rails.cache.redis.hdel("orders", symbol)
      el = EventLog.new(data)
      el.symbol = symbol
      el.save unless EventLog.today.where(current_time: 24.hour.ago..Time.now, symbol: symbol).any?
    rescue Exception => e
      Rails.logger.warn "huobi_orders_log error: #{e.message}"
    ensure
      Rails.cache.redis.hdel("orders:closing", symbol)
    end
  end

  # symbol = "paiusdt"
  def huobi_pnls_log(symbol, pnls)
    if pnls && pnls.any?
      begin
        pnls.each do |change|
          h = eval change
          ProfitLoss.create(symbol: symbol, change: h[:change], current_time: h[:current_time])
        end
      rescue Exception => e
        Rails.logger.warn "huobi_pnls_log error: #{e.message}"
      end
    end
  end

  def huobi_balances
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    balances = huobi_pro.balances
    status = false
    frozen_count = 0
    if balances && balances["status"] == "ok"
      account_id = balances["data"]["id"]
      data = balances["data"]["list"].find_all{|x| x["balance"].to_f != 0}

      Rails.cache.redis.hgetall("balances").each do |d|
        Rails.cache.redis.hdel("balances", d[0]) if d[0].include? "frozen"
      end

      data.each do |d|
        begin
          Rails.cache.redis.hset("balances", "#{d["currency"]}:#{d["type"]}", {"currency": d["currency"],"type": d["type"], "balance": d["balance"], "seq-num": d["seq-num"]} )
          frozen_count = frozen_count + 1 if (d["type"] == "frozen" && d["currency"] != "usdt")
        rescue Exception => e
          Rails.logger.warn "huobi_balances save error: #{e.message}"
        end
      end
      status = true
    end

    return frozen_count, status
  end

  def huobi_histroy_matchresults(symbol)
    count = 0
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    @matchresults = huobi_pro.history_matchresults(symbol)
    if !@matchresults.nil? && @matchresults["status"] != "error" && @matchresults["data"].any?
      @matchresults["data"].each do |result|
        begin
          trade = Trade.find_or_initialize_by(symbol: result["symbol"],trade_id: result["trade-id"])
          trade.attributes = {fee_currency: result["fee-currency"],
                              match_id: result["match-id"],
                              order_id: result["order-id"],
                              price: result["price"],
                              created_time: Time.at(result["created-at"]/1000),
                              role: result["role"],
                              filled_amount: result["filled-amount"],
                              filled_fees: result["filled-fees"],
                              filled_points: result["filled-points"],
                              fee_deduct_currency: result["fee-deduct-currency"],
                              fee_deduct_state: result["fee-deduct-state"],
                              tid: result["id"],
                              trade_type: result["type"]}

          if trade.save
            count = count + 1
          end
        rescue Exception => e
          Rails.logger.warn "huobi_histroy_matchresults error: #{e.message}"
        end
      end
    end

    return count
  end

  def huobi_accounts_history
    count = 0
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    @accounts_history = huobi_pro.accounts_history
    if @accounts_history && @accounts_history["status"] == "ok"
      data = @accounts_history["data"]
      data.each do |his|
        AccountHi.transaction do
          begin
            ah = AccountHi.find_or_initialize_by(account_id: his["account-id"],record_id: his["record-id"].to_s)
            ah.attributes = { currency: his["currency"],
                              transact_amt: his["transact-amt"],
                              transact_type: his["transact-type"],
                              avail_balance: his["avail-balance"],
                              acct_balance: his["acct-balance"],
                              transact_time: Time.at(his["transact-time"]/1000) }

            if ah.save
              count = count + 1
            end
          rescue Exception => e
            Rails.logger.warn "huobi_histroy_matchresults error: #{e.message}"
          end
        end
      end
    end

    return count
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
      Rails.logger.warn "huobi_symbol_ticker: #{e.message}"
    end
    return tick
  end

  # ApplicationController.helpers.huobi_data_insert
  def huobi_data_insert
    require 'csv'

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
        end
      end
    rescue PG::Error => e
      # p "huobi_ticker_insert: #{e.message}"
      Rails.logger.warn "huobi_ticker_insert: #{e.message}"
    ensure
      postgres.close if postgres
    end
  end

  def huobi_url_generator(symbol)
    sym = symbol.gsub("usdt", "")
    url = "https://www.huobi.com/en-us/exchange/#{sym}_usdt/"

    return url
  end

  # def huobi_em
  #   c = "astusdt"
  #   req = "market." + c + ".kline.1min"
  #   @handshake = WebSocket::Handshake::Client.new(url: 'wss://api.huobi.pro/ws', headers: { "sub": req, "id": 1 })
  #
  #   EM.run do
  #
  #     ws = WebSocket::EventMachine::Client.connect(:uri => 'wss://api.huobi.pro/ws')
  #
  #     ws.onopen do
  #       puts "Connected"
  #     end
  #
  #     ws.onping do |message|
  #       puts "Ping received: #{message}"
  #       puts "pong"
  #     end
  #
  #     ws.onmessage do |msg, type|
  #       puts "Received message: #{msg}"
  #     end
  #
  #     ws.onclose do |code, reason|
  #       puts "Disconnected with status code: #{code}"
  #     end
  #
  #     EventMachine.next_tick do
  #       ws.send "Hello Server!"
  #     end
  #
  #   end

  # end

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

  def sidekiq_queue_clear
    require 'sidekiq/api'
    # Clear retry set
    Sidekiq::RetrySet.new.clear
    # Clear scheduled jobs
    Sidekiq::ScheduledSet.new.clear
    # Clear 'Dead' jobs statistics
    Sidekiq::DeadSet.new.clear
    # Clear 'Processed' and 'Failed' jobs statistics
    Sidekiq::Stats.new.reset
    # Clear specific queue
    stats = Sidekiq::Stats.new
    stats.queues
    # => {"main_queue"=>25, "my_custom_queue"=>1}
    queue = Sidekiq::Queue.new('low')
    queue.count
    queue.clear
  end

end
