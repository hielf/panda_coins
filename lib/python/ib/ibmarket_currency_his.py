from ib_insync import *
from sqlalchemy import create_engine
import os
import psycopg2
import sched, time
import datetime
# util.startLoop()  # uncomment this line when in a notebook

ib = IB()
# ib.connect('127.0.0.1', 7496, clientId=100)
# ib.connect('124.156.100.215', 7497, clientId=101)
ib.connect(host='124.156.100.215', port=7497, clientId=500, timeout=10, readonly=False)

contracts = [Forex('USDJPY'), Forex('EURUSD')]
# contracts = [Index(symbol = "HSI", exchange = "HKFE")]
# bars = ib.reqHistoricalData(contract, endDateTime='', durationStr='1 D',
#         barSizeSetting='1 min', whatToShow='TRADES', useRTH=True)

def get_index_1min(end_date):
    print("start collect %s" % str(end_date))
    for contract in contracts:
        conn = psycopg2.connect("host='postgres.ripple-tech.com' dbname='panda_quant' user='chesp' password='Chesp2021' port='5432'")
        cur = conn.cursor()
        if contract.secType == 'CASH':
            if contract.symbol == 'USD' and contract.currency == 'JPY':
                tmp_table = 'usd_jpy_tmp'
                table = 'usd_jpy'
            elif contract.symbol == 'EUR' and contract.currency == 'USD':
                tmp_table = 'eur_usd_tmp'
                table = 'eur_usd'
            bars = ib.reqHistoricalData(contract, endDateTime=end_date, durationStr='1 D', barSizeSetting='1 min', whatToShow='MIDPOINT', useRTH=True)
        elif contract.secType == 'IND':
            if contract.symbol == 'HSI':
                tmp_table = 'hsi_tmp'
                table = 'hsi'
            bars = ib.reqHistoricalData(contract, endDateTime=end_date, durationStr='1 D', barSizeSetting='1 min', whatToShow='TRADES', useRTH=True)
        df = util.df(bars)
        print("got bars %s" % str(bars))
        print("got contract %s" % str(contract))
        engine = create_engine('postgresql+psycopg2://chesp:Chesp2021@postgres.ripple-tech.com:5432/panda_quant',echo=True,client_encoding='utf8')
        print("waiting for collect %s" % table)
        df.to_sql(tmp_table,engine,chunksize=1000,if_exists='replace');
        sql = "insert into " + table + " select * from " + tmp_table +  " b where not exists (select 1 from " + table + " a where a.date = b.date);"
        cur.execute(sql, (10, 1000000, False, False))
        conn.commit()
        conn.close()


def get_index_5min(end_date):
    for contract in contracts:
        conn = psycopg2.connect("host='postgres.ripple-tech.com' dbname='panda_quant' user='chesp' password='Chesp2021' port='5432'")
        cur = conn.cursor()
        if contract.secType == 'CASH':
            if contract == Forex('USDJPY'):
                tmp_table = 'usd_jpy_30mins_tmp'
                table = 'usd_jpy_30mins'
            elif contract == Forex('EURUSD'):
                tmp_table = 'eur_usd_30mins_tmp'
                table = 'eur_usd_30mins'
            bars = ib.reqHistoricalData(contract, endDateTime=end_date, durationStr='1 D', barSizeSetting='5 mins', whatToShow='MIDPOINT', useRTH=True)
        elif contract.secType == 'IND':
            if contract.symbol == 'HSI':
                tmp_table = 'hsi_5mins_tmp'
                table = 'hsi_5mins'
            bars = ib.reqHistoricalData(contract, endDateTime=end_date, durationStr='50 D', barSizeSetting='5 mins', whatToShow='TRADES', useRTH=True)
        # convert to pandas dataframe:
        df = util.df(bars)
        # print(df[['date', 'open', 'high', 'low', 'close']])

        engine = create_engine('postgresql+psycopg2://chesp:Chesp2021@postgres.ripple-tech.com:5432/panda_quant',echo=True,client_encoding='utf8')

        print("collecting %s" % table)
        # get last 2000 bars
        df.tail(2000).to_sql(tmp_table,engine,chunksize=1000,if_exists='replace');

        #不再清空表
        # sql = "delete from %s;" % table
        sql = "insert into " + table + " select * from " + tmp_table +  " b where not exists (select 1 from " + table + " a where a.date = b.date);"

        cur.execute(sql, (10, 1000000, False, False))
        conn.commit()
        conn.close()


# def get_index_30min(date_time):
#     for contract in contracts:
#         conn = psycopg2.connect("host='postgres.ripple-tech.com' dbname='panda_quant' user='chesp' password='Chesp2021' port='5432'")
#         cur = conn.cursor()
#         if contract.secType == 'CASH':
#             bars = ib.reqHistoricalData(contract, endDateTime='', durationStr='45 D', barSizeSetting='30 mins', whatToShow='MIDPOINT', useRTH=True)
#             if contract == Forex('USDJPY'):
#                 tmp_table = 'usd_jpy_30mins_tmp'
#                 table = 'usd_jpy_30mins'
#             elif contract == Forex('EURUSD'):
#                 tmp_table = 'eur_usd_30mins_tmp'
#                 table = 'eur_usd_30mins'
#         elif contract.secType == 'IND':
#             if contract.symbol == 'HSI':
#                 tmp_table = 'hsi_30mins_tmp'
#                 table = 'hsi_30mins'
#             sql = "select min(date) from %s;" % table
#             cur.execute(sql, (10, 1000000, False, False))
#             rows = cur.fetchall()
#             end_date = rows[0][0]
#             bars = ib.reqHistoricalData(contract, endDateTime=end_date, durationStr='200 D', barSizeSetting='30 mins', whatToShow='TRADES', useRTH=True)
#
#         # convert to pandas dataframe:
#         df = util.df(bars)
#         # print(df[['date', 'open', 'high', 'low', 'close']])
#
#         engine = create_engine('postgresql+psycopg2://chesp:Chesp2021@postgres.ripple-tech.com:5432/panda_quant',echo=True,client_encoding='utf8')
#
#         print("collecting %s" % table)
#         # get last 2000 bars
#         df.tail(2000).to_sql(tmp_table,engine,chunksize=1000,if_exists='replace');
#
#         #不再清空表
#         # sql = "delete from %s;" % table
#
#         sql = "insert into " + table + " select * from " + tmp_table +  " b where not exists (select 1 from " + table + " a where a.date = b.date);"
#
#         cur.execute(sql, (10, 1000000, False, False))
#         conn.commit()
#         conn.close()
#
#         s.enter(60, 1, get_index_1min, (date_time,))

if __name__ == '__main__':
    d1 = datetime.date(2020,7,12)
    d2 = datetime.date(2020,10,2)
    diff = d2 - d1
    for i in range(diff.days + 1):
        end_date = (d1 + datetime.timedelta(i))
        get_index_1min(end_date)
