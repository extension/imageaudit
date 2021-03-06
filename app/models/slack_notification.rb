# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file

class SlackNotification

  attr_accessor :message, :attachment, :slack, :icon_emoji

  def initialize(options = {})
    username = options[:username] || "EngBot"
    channel = options[:channel] || Settings.default_slack_channel
    @slack = Slack::Notifier.new(Settings.slack_webhook)
    @slack.username = username
    @slack.channel = channel
    @message = options[:message] || ''
    @attachment = options[:attachment]
    @icon_emoji = options[:icon_emoji]
    self
  end

  def post
    post_parameters = {}
    if(self.attachment)
      post_parameters[:attachments] = [self.attachment]
    end

    if(self.icon_emoji)
      post_parameters[:icon_emoji] = self.icon_emoji
    else
      post_parameters[:icon_emoji] = ':engbot:'
    end

    self.slack.ping(self.message, post_parameters)

  end

  def self.post(options = {})
    if(notification = self.new(options))
      notification.post
    end
  end

end
