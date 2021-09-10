# huobi coins交易接口

### [API](https://github.com/hielf/panda_coins/blob/master/api.md)

## RULE OPEN
* 2分钟大于 3%, 如果小于4% 用4%的限价单买
* 如果大于4% 小于10% 用市价单
* 如果大于10% 不下单

## RULE CLOSE
* 开仓买入后, 3分钟后市价平仓
* 3分钟内, 如果跌幅大于-5% 市价平仓
* 连续下跌平仓逻辑保留
* 大于100%(翻倍) 市价平仓
