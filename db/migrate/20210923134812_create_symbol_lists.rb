class CreateSymbolLists < ActiveRecord::Migration[5.2]
  def change
    create_table :symbol_lists do |t|
      t.string :symbol
      t.date :listing_date

      t.timestamps
    end
    add_index :symbol_lists, :symbol, unique: true
  end
end
