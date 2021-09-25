class CreateTraderSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :trader_settings do |t|
      t.integer :account_id
      t.string :days_after_symbol_listing
      t.string :max_opened_orders
      t.string :first_share_divide
      t.string :divide_shares
      t.string :up_floor_limit
      t.string :up_up_limit
      t.string :first_up_up_limit
      t.string :down_limit
      t.string :up_limit
      t.string :pnl_interval
      t.string :close_timer_up
      t.string :tickers_check_interval
      t.string :daily_balance_up_limit
      t.string :daily_start_time
      t.string :daily_clear_all_time
      t.string :buy_accept_start_time
      t.string :buy_accept_end_time

      t.timestamps
    end
    add_index :trader_settings, :account_id, unique: true
  end
end
