class OrdersCheckJob < ApplicationJob
  queue_as :high_priority

  # after_perform :around_check

  def perform(*args)
    count_1 = ApplicationController.helpers.huobi_orders_check
    count_2 = ApplicationController.helpers.huobi_orders_close
  end

  private
  def around_check

  end

end
