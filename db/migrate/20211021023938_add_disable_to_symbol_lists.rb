class AddDisableToSymbolLists < ActiveRecord::Migration[5.2]
  def change
    add_column :symbol_lists, :disabled, :boolean, :default => false
  end
end
