class SmsJob < ApplicationJob
  queue_as :low

  after_perform :around_check

  def perform(*args)
    cell     = args[0]
    @version = args[1]
    @message = args[2]

    last_sm = Sm.where("created_at > ?", 3.minutes.ago).last

    @var = {}
    @var["backtrader_version"] = @version
    @var["message"] = @message
    @status = nil

    if last_sm.nil?
      run_time = Time.zone.now
      current_time = run_time.strftime('%H:%M')
      uri             = URI.parse("https://api.mysubmail.com/message/xsend.json")
      sms_appid       = ENV['sms_appid']
      sms_signature   = ENV['sms_signature']
      sms_project     = ENV['sms_project']
      res             = Net::HTTP.post_form(uri, appid: sms_appid, to: cell, project: sms_project, signature: sms_signature, vars: @var.to_json)

      @status      = JSON.parse(res.body)["status"]
    end
  end
# SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], "无法连接"

  private
  def around_check
    Sm.create!(message: @version + @message, message_type: "alert") if @status
  end
end
