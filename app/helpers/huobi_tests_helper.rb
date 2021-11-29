#export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# require 'net/ping'
# require 'pycall/import'
# include PyCall::Import
# require 'faye/websocket'
# require 'eventmachine'
# ApplicationController.helpers.huobi_tickers_cache

module HuobiTestsHelper
  # ApplicationController.helpers.huobi_tickers_check(settings, Time.now - 120, Time.now)
  def huobi_tickers_check_test
    list = ["soc"]
    list.each do |sym|
      symbol = sym + "usdt"
      start_time = Time.now.beginning_of_day.strftime("%Y-%m-%dT%H:%M:%S")
      end_time = (Time.now + 900).strftime("%Y-%m-%dT%H:%M:%S")
      times = []
      symbols = []
      white_list_symbols = ApplicationController.helpers.white_list
      settings = TraderSetting.current_settings
      url = "http://postgres.ripple-tech.com:3000/huobi_tickers?and=(time.gte.#{start_time},time.lte.#{end_time},symbol.eq.#{symbol})"
      result = Faraday.get url
      json = JSON.parse result.as_json["body"]
      data_s = json[0]

      if data_s.nil? || data_s.empty?
        p "#{symbol} no data_s!!"
      end

      if !white_list_symbols.include? symbol
        p "not in white_lists!!"
      end

      p "#{symbol} started.."
      json.each do |data_l|
        change = (data_s["close"] == 0 ? 0 : (data_l["close"]-data_s["close"])/data_s["close"])
        p [symbol, data_l["close"] ,change, data_l["time"]]
        if change >= settings.up_floor_limit.to_f && change <= settings.up_up_limit.to_f
          p "found!!!!!! #{symbol} #{change} @ #{data_l["time"]}"
          if data_l["vol"]  >= settings.amount_bottom_limit.to_f
            p "#{symbol} amount_bottom_limit enough"
            break
          end
        end
      end;0
      p "#{symbol} ended.."
    end;0
  end

end
