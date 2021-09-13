class ModifyColumsOnTrades < ActiveRecord::Migration[5.2]
  def change
    remove_column :trades, :exec_id
    remove_column :trades, :perm_id
    remove_column :trades, :action
    remove_column :trades, :symbol
    remove_column :trades, :last_trade_date_or_contract_month
    remove_column :trades, :currency
    remove_column :trades, :shares
    remove_column :trades, :price
    remove_column :trades, :time
    remove_column :trades, :commission
    remove_column :trades, :realized_pnl

    add_column :trades, :symbol, :string
    add_column :trades, :fee_currency, :string
    add_column :trades, :match_id, :integer
    add_column :trades, :order_id, :string
    add_column :trades, :price, :float
    add_column :trades, :created_time, :datetime
    add_column :trades, :role, :string
    add_column :trades, :trade_id, :integer
    add_column :trades, :filled_amount, :float
    add_column :trades, :filled_fees, :float
    add_column :trades, :filled_points, :float
    add_column :trades, :fee_deduct_currency, :string
    add_column :trades, :fee_deduct_state, :string
    add_column :trades, :tid, :string
    add_column :trades, :trade_type, :string
  end
  add_index :trades, :symbol
end
