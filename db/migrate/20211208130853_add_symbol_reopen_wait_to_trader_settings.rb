class AddSymbolReopenWaitToTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :symbol_reopen_wait, :string
  end
end
