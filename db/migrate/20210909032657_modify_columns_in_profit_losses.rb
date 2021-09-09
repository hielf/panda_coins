class ModifyColumnsInProfitLosses < ActiveRecord::Migration[5.2]
  def change
    remove_column :profit_losses, :current
    remove_column :profit_losses, :open
    remove_column :profit_losses, :close
    remove_column :profit_losses, :unrealized_pnl

    add_column :profit_losses, :symbol, :string
    add_column :profit_losses, :change, :float
  end
end
