class SymbolList < ApplicationRecord

  state_machine :disabled, :initial => :false do
    event :enable do
      transition :true => :false
    end
    event :disable do
      transition :false => :true
    end
  end

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
