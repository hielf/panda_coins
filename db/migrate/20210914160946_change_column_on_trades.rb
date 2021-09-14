class ChangeColumnOnTrades < ActiveRecord::Migration[5.2]
  def change
    change_column :trades, :match_id, :string
    change_column :trades, :trade_id, :string
  end
end
