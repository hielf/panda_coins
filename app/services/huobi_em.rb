# require 'httparty'
require 'json'
require 'open-uri'
require 'rack'
require 'digest/md5'
require 'base64'
class HuobiEm

  def huobi_em
    symbol = "btcusdt"
    c = "market." + symbol + ".ticker"
    req = JSON.dump({"sub": c, "id": symbol})

    EM.run do
      ws = Faye::WebSocket::Client.new('wss://api.huobi.pro/ws')
      
      ws.on :message do |event|
        blob_arr = event.data
        data = JSON.parse(Zlib::gunzip(blob_arr.pack('c*')), symbolize_names: true)
        if (ts = data[:ping])
          ws.opened? && ws.send(JSON.dump({ "pong": ts }))
        else
          p [Time.at(data[:ts]/1000), data[:tick][:close]]
        end
      end

      ws.on :open do |event|
        ws.send(req)
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end

  private

  def opened?
    self.ready_state == Faye::WebSocket::OPEN
  end

end

# access_key = ENV["huobi_access_key"]
# secret_key = ENV["huobi_secret_key"]
# account_id = ENV["huobi_accounts"] #huobi_pro.accounts["data"][0]["id"]
# huobi_pro = HuobiPro.new(access_key,secret_key,account_id)

# p huobi_pro.balances
# p huobi_pro.symbols
# p huobi_pro.depth('ethbtc')
# p huobi_pro.history_kline('ethbtc',"1min")
# p huobi_pro.merged('ethbtc')
# p huobi_pro.trade_detail('ethbtc')
# p huobi_pro.history_trade('ethbtc')


# huobi_pro.new_order(symbol,"buy-market",0,1)
# huobi_pro.history_matchresults(symbol)
# huobi_pro.new_order(symbol,"sell-market",0,5)
# huobi_pro.matchresults(359277988888707)
# huobi_pro.submitcancel(359277988888707)
