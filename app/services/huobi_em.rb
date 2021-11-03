# require 'httparty'
require 'json'
require 'open-uri'
require 'rack'
require 'digest/md5'
require 'base64'
class HuobiEm

  def start
    # ['aacusdt','achusdt','ankrusdt','bsvusdt','cnnsusdt','creusdt','bixusdt','dacusdt','ektusdt','ethusdt','fildausdt','flowusdt','gxcusdt','ltc3susdt','mirusdt','mtausdt','mxcusdt','nasusdt','nbsusdt','neousdt','phausdt','skmusdt','steemusdt','utkusdt','wnxmusdt','xrp3lusdt','zilusdt','1inchusdt','aaveusdt','abtusdt','adausdt','aeusdt','akrousdt','antusdt','api3usdt','apnusdt','arusdt','atomusdt','axsusdt','bagsusdt','batusdt','bch3lusdt','bethusdt','bhdusdt','blzusdt','bntusdt','btc1susdt','btc3susdt','btmusdt','bttusdt','ckbusdt','cmtusdt','cruusdt','crvusdt','csprusdt','ctsiusdt','dashusdt','dfusdt','dkausdt','dogeusdt','dot2susdt','dotusdt','egtusdt','elausdt','elfusdt','eos3lusdt','eosusdt','etcusdt','eth1susdt','firousdt','fisusdt','forthusdt','forusdt','fttusdt','gnxusdt','grtusdt','gtusdt','hbcusdt','hitusdt','hptusdt','icpusdt','icxusdt','iostusdt','fsnusdt','pondusdt','actusdt','algousdt','arpausdt','astusdt','atpusdt','auctionusdt','avaxusdt','badgerusdt','balusdt','bandusdt','bch3susdt','bchusdt','bsv3lusdt','bsv3susdt','iotxusdt','irisusdt','itcusdt','jstusdt','kanusdt','kcashusdt','kncusdt','ksmusdt','lambusdt','latusdt','lbausdt','lhbusdt','linausdt','linkusdt','lrcusdt','ltc3lusdt','ltcusdt','lunausdt','manausdt','massusdt','maticusdt','mdxusdt','mlnusdt','mxusdt','newusdt','nftusdt','nknusdt','nsureusdt','o3usdt','ognusdt','ogousdt','oneusdt','polsusdt','btc3lusdt','btcusdt','btsusdt','canusdt','chrusdt','chzusdt','compusdt','crousdt','ctxcusdt','cvcusdt','cvpusdt','daiusdt','dcrusdt','dhtusdt','dockusdt','dot2lusdt','dtausdt','emusdt','enjusdt','eos3susdt','eth3lusdt','eth3susdt','fil3lusdt','filusdt','frontusdt','ftiusdt','glmusdt','gofusdt','hbarusdt','hcusdt','hiveusdt','hotusdt','htusdt','injusdt','insurusdt','iotausdt','kavausdt','letusdt','link3lusdt','link3susdt','lolusdt','loomusdt','lxtusdt','maskusdt','mdsusdt','mkrusdt','nanousdt','nearusdt','nestusdt','nexousdt','nhbtcusdt','nodeusdt','nulsusdt','nuusdt','ocnusdt','omgusdt','ontusdt','oxtusdt','paiusdt','paxusdt','pearlusdt','pvtusdt','qtumusdt','raiusdt','reefusdt','renusdt','ringusdt','rlcusdt','rndrusdt','rsrusdt','ruffusdt','topusdt','trbusdt','trxusdt','ttusdt','uipusdt','umausdt','uni2lusdt','uni2susdt','uniusdt','usdcusdt','uuuusdt','valueusdt','vetusdt','vidyusdt','vsysusdt','wavesusdt','waxpusdt','wbtcusdt','wiccusdt','woousdt','wtcusdt','wxtusdt','xchusdt','xemusdt','rvnusdt','sandusdt','scusdt','seeleusdt','shibusdt','sklusdt','smtusdt','sntusdt','snxusdt','socusdt','solusdt','stakeusdt','stnusdt','storjusdt','stptusdt','sunusdt','sushiusdt','swftcusdt','swrvusdt','thetausdt','titanusdt','tnbusdt','xlmusdt','xmrusdt','xmxusdt','xrpusdt','xrtusdt','xtzusdt','yamusdt','yeeusdt','yfiiusdt','yfiusdt','zec3lusdt','zec3susdt','zecusdt','zenusdt','zksusdt','zrxusdt']
    # list = ["ethusdt", "btcusdt", "dogeusdt", "xrpusdt", "lunausdt", "adausdt", "bttusdt", "nftusdt"]
    url = "http://139.162.149.116:81/api/trade_orders/white_list"
    res = Faraday.get url
    data = JSON.parse res.body
    list = case ENV["collect_order"]
    when "1"
      data["data"][0..29]
    when "2"
      data["data"][30..59]
    when "3"
      data["data"][60..89]
    when "4"
      data["data"][90..119]
    when "5"
      data["data"][120..149]
    when "6"
      data["data"][150..179]
    when "7"
      data["data"][180..209]
    when "8"
      data["data"][210..239]
    when "9"
      data["data"][240..269]
    when "10"
      data["data"][270..299]
    end

    tickers = SortedSet.new # SortedSet.new
    symbols_list = Set.new
    Parallel.map(list, in_threads: list.count) do |symbol|
      em(symbol)
    end

  end

  private

  def opened?
    self.ready_state == Faye::WebSocket::OPEN
  end

  def em(symbol)
    c = "market." + symbol + ".ticker"
    req = JSON.dump({"sub": c, "id": symbol})
    last_ts = Time.at(Time.now.to_i/1000)
    EM.run do
      ws = Faye::WebSocket::Client.new('wss://api.huobi.pro/ws')
      ws.on :message do |event|
        blob_arr = event.data
        data = JSON.parse(Zlib::gunzip(blob_arr.pack('c*')), symbolize_names: true)
        if (ts = data[:ping])
          ws.opened? && ws.send(JSON.dump({ "pong": ts }))
        else
          begin
            if data[:ts] && data[:tick]
              current_ts = Time.at(data[:ts]/1000)
              if current_ts != last_ts
                Rails.cache.write("tickers_data:#{data[:ch]}:#{Time.at(data[:ts]/1000)}", {:tick => data[:tick]}, expires_in: 10.seconds)
              end
            end
          rescue Exception => e
            p e
            p data
          ensure
            last_ts = current_ts
          end
        end
      end

      ws.on :open do |event|
        p req
        ws.send(req)
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason, symbol]
        ws = nil
        em(symbol)
      end
    end
  end

end
