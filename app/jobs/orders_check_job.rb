class OrdersCheckJob < ApplicationJob
  queue_as :high

  # after_perform :around_check

  def perform(*args)
    count_1 = ApplicationController.helpers.huobi_orders_check
  end

  private
  def around_check

  end

end
