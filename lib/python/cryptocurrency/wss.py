import gzip
import json
import pprint
import threading
import csv
import time
import websocket
import pandas as pd
import datetime
from functools import partial

def send_message(ws, message_dict):
    data = json.dumps(message_dict).encode()
    print("Sending Message:")
    pprint.pprint(message_dict)
    ws.send(data)


def on_message(ws, message):
    unzipped_data = gzip.decompress(message).decode()
    msg_dict = json.loads(unzipped_data)
    print("Recieved Message: ")
    # pprint.pprint(msg_dict["data"])

    data = msg_dict["data"]
    id = msg_dict["id"]
    file_date = datetime.datetime.fromtimestamp(int(data[0]["id"])).strftime('%Y%m%d')
    file_name = id + "_" + file_date + ".csv"
    f = csv.writer(open(file_name, "w", newline=''))
    f.writerow(["date", "open", "high", "low", "close", "amount", "vol"])
    for d in data:
        dt = datetime.datetime.fromtimestamp(int(d["id"])).strftime('%Y-%m-%d %H:%M:%S')
        print ([dt,d["open"],d["high"],d["low"],d["close"],d["amount"],d["vol"]])
        f.writerow([dt,d["open"],d["high"],d["low"],d["close"],d["amount"],d["vol"]])

    if 'ping' in msg_dict:
        data = {
            "pong": msg_dict['ping']
        }
        send_message(ws, data)


def on_error(ws, error):
    print("Error: " + str(error))
    error = gzip.decompress(error).decode()
    print(error)


def on_close(ws):
    print("### closed ###")


def on_open(ws, c):
    def run(*args):
        # for c in usdts:
        req = "market." + c + ".kline.1min"
        begin_date = datetime.datetime(2021,9,12,0,0)
        end_date = datetime.datetime(2021,9,20,0,0)

        diff = end_date - begin_date
        for i in range(diff.days):
            begin_time = (begin_date + datetime.timedelta(i))
            print ("start")
            print (int(time.mktime(begin_time.timetuple())))
            for end_time in (begin_time + datetime.timedelta(minutes=1*it) for it in range(16)):
                end_time
            print ("end")
            print (int(time.mktime(end_time.timetuple())))

            # # 每2秒请求一次K线图，请求5次
            for i in range(2):
                time.sleep(2)
                data = {
                    "req": req,
                    "id": c,
                    "from": int(time.mktime(begin_time.timetuple())),
                    "to": int(time.mktime(end_time.timetuple())),
                }
                print (data)
                send_message(ws, data)
        ws.close()
        print("thread terminating...")

    t = threading.Thread(target=run, args=())
    t.start()


if __name__ == "__main__":
    # usdts = ["ethusdt", "btcusdt", "dogeusdt", "xrpusdt", "lunausdt", "adausdt", "bttusdt", "nftusdt", "dotusdt", "trxusdt", "icpusdt", "abtusdt", "skmusdt", "bhdusdt", "aacusdt", "canusdt", "fisusdt", "nhbtcusdt", "letusdt", "massusdt", "achusdt", "ringusdt", "stnusdt", "mtausdt", "itcusdt", "atpusdt", "gofusdt", "pvtusdt", "auctionus", "ocnusdt"]
    usdts = ["xprtusdt", "astusdt", "flowusdt", "bagsusdt", "ringusdt", "kncusdt", "xrpusdt", "btcusdt", "bchusdt", "eos3susdt", "mxusdt", "vidyusdt", "btc3susdt", "kanusdt", "ctxcusdt", "ksmusdt", "yeeusdt", "nbsusdt", "rlyusdt", "wtcusdt", "yfiiusdt", "dacusdt", "nodeusdt", "btc1susdt", "nhbtcusdt", "ctsiusdt", "irisusdt", "daiusdt", "forthusdt", "neousdt", "grtusdt", "icpusdt", "uni2susdt", "hbcusdt", "arusdt", "sxpusdt", "zrxusdt", "uni2lusdt", "aeusdt", "uipusdt", "dfusdt", "stptusdt", "dot2susdt", "yggusdt", "vsysusdt", "btsusdt", "xrtusdt", "swftcusdt", "cruusdt", "sushiusdt", "dhtusdt", "hitusdt", "bhdusdt", "rsrusdt", "agldusdt", "lunausdt", "arpausdt", "forusdt", "creusdt", "topusdt", "ogousdt", "ognusdt", "xrp3lusdt", "nulsusdt", "canusdt", "akrousdt", "stfusdt", "uuuusdt", "bsv3susdt", "requsdt", "auctionusdt", "egtusdt", "borusdt", "dtausdt", "omgusdt", "gnxusdt", "batusdt", "utkusdt", "venusdt", "pvtusdt", "oxtusdt", "swrvusdt", "antusdt", "xmrusdt", "kavausdt", "lendusdt", "lbausdt", "mcousdt", "vetusdt", "crousdt", "paxusdt", "1inchusdt", "o3usdt", "enjusdt", "bixusdt", "linausdt", "gofusdt", "mtausdt", "xmxusdt", "shibusdt", "link3susdt", "cvcusdt", "zec3susdt", "lrcusdt", "aaveusdt", "epikusdt", "clvusdt", "dkausdt", "insurusdt", "xrp3susdt", "botusdt", "ocnusdt", "yamv2usdt", "eth1susdt", "xecusdt", "eth3susdt", "iostusdt", "dcrusdt", "waxpusdt", "scusdt", "polyusdt", "umausdt", "fisusdt", "emusdt", "xlmusdt", "trxusdt", "chzusdt", "wiccusdt", "spausdt", "elausdt", "thetausdt", "balusdt", "sklusdt", "lxtusdt", "polsusdt", "lolusdt", "ftiusdt", "woousdt", "tusdusdt", "btmusdt", "fttusdt", "bch3lusdt", "mirusdt", "fsnusdt", "tribeusdt", "jstusdt", "link3lusdt", "ltc3susdt", "wozxusdt", "blzusdt", "edenusdt", "injusdt", "xemusdt", "bttusdt", "oneusdt", "abtusdt", "cmtusdt", "letusdt", "sandusdt", "dot2lusdt", "lambusdt", "maskusdt", "yfiusdt", "firousdt", "nexousdt", "dfausdt", "snxusdt", "cotiusdt", "dotusdt", "xchusdt", "kcashusdt", "newusdt", "crvusdt", "pondusdt", "boringusdt", "hcusdt", "renusdt", "paiusdt", "eos3lusdt", "nuusdt", "bethusdt", "wavesusdt", "zilusdt", "seeleusdt", "dashusdt", "hotusdt", "iotxusdt", "adausdt", "mkrusdt", "manausdt", "wnxmusdt", "ckbusdt", "zecusdt", "mdxusdt", "filusdt", "dydxusdt", "stnusdt", "algousdt", "fil3lusdt", "sntusdt", "mdsusdt", "wxtusdt", "glmusdt", "xtzusdt", "pearlusdt", "skuusdt", "bchausdt", "dogeusdt", "avaxusdt", "ethusdt", "smtusdt", "raiusdt", "latusdt", "bntusdt", "mxcusdt", "radusdt", "ruffusdt", "eth3lusdt", "tnbusdt", "valueusdt", "loomusdt", "linkusdt", "skmusdt", "achusdt", "mlnusdt", "bch3susdt", "steemusdt", "nknusdt", "compusdt", "etcusdt", "usdcusdt", "bsvusdt", "btc3lusdt", "csprusdt", "eosusdt", "wbtcusdt", "maticusdt", "pushusdt", "nasusdt", "atomusdt", "rndrusdt", "reefusdt", "qtumusdt", "fil3susdt", "elfusdt", "axsusdt", "gtusdt", "massusdt", "fildausdt", "ektusdt", "nftusdt", "solusdt", "trbusdt", "lhbusdt", "uniusdt", "aacusdt", "frontusdt", "titanusdt", "rlcusdt", "nestusdt", "whaleusdt", "atpusdt", "nsureusdt", "hbarusdt", "hiveusdt", "bandusdt", "stakeusdt", "sunusdt", "zec3lusdt", "icxusdt", "ltcusdt", "api3usdt", "srmusdt", "chrusdt", "cvpusdt", "itcusdt", "ltc3lusdt", "cnnsusdt", "ankrusdt", "rvnusdt", "zenusdt", "phausdt", "actusdt", "hptusdt", "socusdt", "nearusdt", "iotausdt", "dockusdt", "talkusdt", "gxcusdt", "nanousdt", "storjusdt", "zksusdt", "badgerusdt", "apnusdt", "htusdt", "ontusdt", "ttusdt", "yamusdt", "bsv3lusdt"]
    # begin_date = datetime.datetime(2021,6,16,0,0)
    # end_date = datetime.datetime(2021,8,16,0,0)
    #
    # diff = end_date - begin_date
    # for i in range(diff.days):
    #     begin_time = (begin_date + datetime.timedelta(i))
    #     print ("start")
    #     print (int(time.mktime(begin_time.timetuple())))
    #     for end_time in (begin_time + datetime.timedelta(minutes=1*it) for it in range(16)):
    #         end_time
    #     print ("end")
    #     print (int(time.mktime(end_time.timetuple())))
    # websocket.enableTrace(True)
    for c in usdts:
        ws = websocket.WebSocketApp(
            "wss://api.huobi.pro/ws",
            # on_open=on_open,
            on_message=on_message,
            on_open=lambda ws: on_open(ws, c),
            # on_message=lambda ws: on_message(ws, message),
            on_error=on_error,
            on_close=on_close
        )
        ws.run_forever()
