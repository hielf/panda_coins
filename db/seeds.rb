# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ts = TraderSetting.find_or_initialize_by(account_id: ENV["huobi_accounts"])
ts.attributes = { days_after_symbol_listing: "90",
  max_opened_orders: "10",
  first_share_divide: "3",
  divide_shares: "5",
  up_floor_limit: "0.01",
  up_up_limit: "0.05",
  first_up_up_limit: "0.05",
  down_limit: "-0.03",
  up_limit: "0.06",
  pnl_interval: "3",
  close_timer_up: "60",
  tickers_check_interval: "120",
  daily_balance_up_limit: "0.01",
  daily_start_time: "00:00:05",
  daily_clear_all_time: "00:05",
  buy_accept_start_time: "23:59",
  buy_accept_end_time: "00:03" }
ts.save
