class SymbolList < ApplicationRecord

  def self.black_list
    where(disabled: true)
  end

  def is_disabled
    if disabled
      "是"
    else
      "否"
    end
  end
end
