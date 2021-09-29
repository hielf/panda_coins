class OrdersCloseJob < ApplicationJob
  queue_as :high_priority

  # after_perform :around_check

  def perform(*args)
    count_2 = ApplicationController.helpers.huobi_orders_close
  end

  private
  def around_check

  end

end
