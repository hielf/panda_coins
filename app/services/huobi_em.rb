# require 'httparty'
require 'json'
require 'open-uri'
require 'rack'
require 'digest/md5'
require 'base64'
class HuobiEm

  def start
    # ['aacusdt','achusdt','ankrusdt','bsvusdt','cnnsusdt','creusdt','bixusdt','dacusdt','ektusdt','ethusdt','fildausdt','flowusdt','gxcusdt','ltc3susdt','mirusdt','mtausdt','mxcusdt','nasusdt','nbsusdt','neousdt','phausdt','skmusdt','steemusdt','utkusdt','wnxmusdt','xrp3lusdt','zilusdt','1inchusdt','aaveusdt','abtusdt','adausdt','aeusdt','akrousdt','antusdt','api3usdt','apnusdt','arusdt','atomusdt','axsusdt','bagsusdt','batusdt','bch3lusdt','bethusdt','bhdusdt','blzusdt','bntusdt','btc1susdt','btc3susdt','btmusdt','bttusdt','ckbusdt','cmtusdt','cruusdt','crvusdt','csprusdt','ctsiusdt','dashusdt','dfusdt','dkausdt','dogeusdt','dot2susdt','dotusdt','egtusdt','elausdt','elfusdt','eos3lusdt','eosusdt','etcusdt','eth1susdt','firousdt','fisusdt','forthusdt','forusdt','fttusdt','gnxusdt','grtusdt','gtusdt','hbcusdt','hitusdt','hptusdt','icpusdt','icxusdt','iostusdt','fsnusdt','pondusdt','actusdt','algousdt','arpausdt','astusdt','atpusdt','auctionusdt','avaxusdt','badgerusdt','balusdt','bandusdt','bch3susdt','bchusdt','bsv3lusdt','bsv3susdt','iotxusdt','irisusdt','itcusdt','jstusdt','kanusdt','kcashusdt','kncusdt','ksmusdt','lambusdt','latusdt','lbausdt','lhbusdt','linausdt','linkusdt','lrcusdt','ltc3lusdt','ltcusdt','lunausdt','manausdt','massusdt','maticusdt','mdxusdt','mlnusdt','mxusdt','newusdt','nftusdt','nknusdt','nsureusdt','o3usdt','ognusdt','ogousdt','oneusdt','polsusdt','btc3lusdt','btcusdt','btsusdt','canusdt','chrusdt','chzusdt','compusdt','crousdt','ctxcusdt','cvcusdt','cvpusdt','daiusdt','dcrusdt','dhtusdt','dockusdt','dot2lusdt','dtausdt','emusdt','enjusdt','eos3susdt','eth3lusdt','eth3susdt','fil3lusdt','filusdt','frontusdt','ftiusdt','glmusdt','gofusdt','hbarusdt','hcusdt','hiveusdt','hotusdt','htusdt','injusdt','insurusdt','iotausdt','kavausdt','letusdt','link3lusdt','link3susdt','lolusdt','loomusdt','lxtusdt','maskusdt','mdsusdt','mkrusdt','nanousdt','nearusdt','nestusdt','nexousdt','nhbtcusdt','nodeusdt','nulsusdt','nuusdt','ocnusdt','omgusdt','ontusdt','oxtusdt','paiusdt','paxusdt','pearlusdt','pvtusdt','qtumusdt','raiusdt','reefusdt','renusdt','ringusdt','rlcusdt','rndrusdt','rsrusdt','ruffusdt','topusdt','trbusdt','trxusdt','ttusdt','uipusdt','umausdt','uni2lusdt','uni2susdt','uniusdt','usdcusdt','uuuusdt','valueusdt','vetusdt','vidyusdt','vsysusdt','wavesusdt','waxpusdt','wbtcusdt','wiccusdt','woousdt','wtcusdt','wxtusdt','xchusdt','xemusdt','rvnusdt','sandusdt','scusdt','seeleusdt','shibusdt','sklusdt','smtusdt','sntusdt','snxusdt','socusdt','solusdt','stakeusdt','stnusdt','storjusdt','stptusdt','sunusdt','sushiusdt','swftcusdt','swrvusdt','thetausdt','titanusdt','tnbusdt','xlmusdt','xmrusdt','xmxusdt','xrpusdt','xrtusdt','xtzusdt','yamusdt','yeeusdt','yfiiusdt','yfiusdt','zec3lusdt','zec3susdt','zecusdt','zenusdt','zksusdt','zrxusdt']
    list = ["ethusdt", "btcusdt", "dogeusdt", "xrpusdt", "lunausdt", "adausdt", "bttusdt", "nftusdt"]

    tickers = SortedSet.new # SortedSet.new
    symbols_list = Set.new
    Parallel.map(list, in_threads: list.count) do |symbol|
      c = "market." + symbol + ".ticker"
      req = JSON.dump({"sub": c, "id": symbol})
      last_ts = Time.at(Time.now.to_i/1000)
      EM.run do
        ws = Faye::WebSocket::Client.new('wss://api.huobi.pro/ws')
        ws.on :message do |event|
          blob_arr = event.data
          data = JSON.parse(Zlib::gunzip(blob_arr.pack('c*')), symbolize_names: true)
          if (ts = data[:ping])
            ws.ready_state == Faye::WebSocket::OPEN && ws.send(JSON.dump({ "pong": ts }))
          else
            begin
              if data[:ts] && data[:tick]
                symbols_list << {:symbol => data[:ch]}
                current_ts = Time.at(data[:ts]/1000)
                if current_ts != last_ts
                  # p [Time.at(data[:ts]/1000), data[:ch], data[:tick][:close], data[:tick][:bid], data[:tick][:vol]]
                  Rails.cache.write("tickers_data:#{data[:ch]}:#{Time.at(data[:ts]/1000)}", {:tick => data[:tick]}, expires_in: 5.seconds)
                  # tickers << {:time => current_ts, :symbol => data[:ch], :tick => data[:tick]}
                end
              end
            rescue Exception => e
              p e
              p data
            ensure
              last_ts = current_ts
              # if tickers.any?
              #   p "tickers.last: #{tickers.to_a.last[:time]}"
              #   p "finish count: #{(tickers.find_all {|x| x[:time] == current_ts}).count}"
              # end
              # if (tickers.find_all {|x| x[:time] == current_ts}).count == symbols_list.count
              #   p current_ts
              #   tickers.clear
              #   p "ticker cleared"
              # end
            end
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
