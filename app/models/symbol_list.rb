class SymbolList < ApplicationRecord

  def self.black_list
    where(disabled: true)
  end
end
