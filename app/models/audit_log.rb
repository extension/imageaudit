# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class AuditLog < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  default_url_options[:host] = Settings.urlwriter_host

  belongs_to :auditable, :polymorphic => true
  belongs_to :contributor
  after_create :queue_slack_notification

  NOTES_SOURCES = ['notes','copyright','source']

  def audit_type
    if(self.auditable_type == "HostedImage")
      'Image'
    elsif(self.auditable_type == "HostedImageAudit")
      'Image'
    elsif(self.auditable_type == "PageAudit")
      'Page'
    else
      self.auditable_type
    end
  end

  def auditable_type_string
    case self.audit_type
    when 'Image'
      'an image'
    when 'Page'
      'a page'
    else
      "a #{self.audit_type.downcase}"
    end
  end

  def notification_url
    audit_log_url(self)
  end

  def changed_object
    if(self.auditable_type == 'PageAudit')
      self.auditable.page
    elsif(self.auditable_type == 'HostedImageAudit')
      self.auditable.hosted_image
    elsif(self.auditable_type == 'HostedImage')
      self.auditable
    else
      self.auditable
    end
  end


  def queue_slack_notification
    if(Settings.sidekiq_enabled)
      self.class.delay.delayed_slack_notification(self.id)
    else
      self.slack_notification
    end
  end

  def self.delayed_slack_notification(record_id)
    if(record = find_by_id(record_id))
      record.slack_notification
    end
  end

  def audit_action_string
    return_string_array = []
    if(NOTES_SOURCES.include?(self.changed_item))
      if(self.changed_item == 'copyright')
        return_string_array << "The copyright value for #{auditable_type_string} was changed."
      elsif(self.changed_item == 'notes')
        return_string_array << "#{self.contributor.fullname} audited #{auditable_type_string} changing the notes."
      elsif(self.changed_item == 'source')
        return_string_array << "The source for #{auditable_type_string} was changed to `#{self.current_notes}` from `#{self.previous_notes}`"
      else
        return_string_array << "#{self.contributor.fullname} audited #{auditable_type_string}"
      end
    elsif
      return_string_array << "#{self.contributor.fullname} audited #{auditable_type_string}"
      if(current_check_value.nil?)
        return_string_array << "clearing the value for `#{self.changed_item}`"
      elsif(previous_check_value.nil?)
        return_string_array << "setting the value of `#{self.changed_item}`"
        return_string_array << "to #{(self.current_check_value? ? '`True`' : '`False`')}"
      else
        return_string_array << "changing the value of #{self.changed_item}"
        return_string_array << "from #{(self.previous_check_value? ? '`True`' : '`False`')}"
        return_string_array << "to #{(self.current_check_value? ? '`True`' : '`False`')}"
      end
    end
    return_string_array.join(' ')
  end


  def slack_notification
    return false if self.changed_item == 'source'
    ao = self.changed_object
    post_options = {}
    post_options[:channel] = Settings.imageaudit_slack_channel
    post_options[:username] = "ImageAudit Log Notification"

    attachment = { "fallback" => "#{self.contributor.fullname} audited #{auditable_type_string}  Details [TBD].",
    "mrkdwn_in" => ["fields"],
    "text" => "ImageAudit Log Notification",
    "fields" => [
      {
        "title" => "Who",
        "value" => "#{self.contributor.fullname}",
        "short" => true
      },
      {
        "title" => "What",
        "value" =>  "#{self.audit_type.capitalize} #{ao.nil? ? "ID# Unknown (removed #{self.audit_type.downcase})" : "ID# #{ao.id}" }",
        "short" =>  true
      }
    ],
    "color" => "good"
    }

    attachment["fields"].push({"title" => "Action", "value" => self.audit_action_string, "short" => false})
    if(self.changed_item == 'notes')
      attachment["fields"].push({"title" => "Previous Notes", "value" => (self.previous_notes.blank? ? 'n/a' : self.previous_notes), "short" => false})
      attachment["fields"].push({"title" => "Current Notes", "value" => (self.current_notes.blank? ? 'n/a' : self.current_notes), "short" => false})
    elsif(self.changed_item == 'copyright')
      attachment["fields"].push({"title" => "Previous Copyright", "value" => (self.previous_notes.blank? ? 'n/a' : self.previous_notes), "short" => false})
      attachment["fields"].push({"title" => "Current Copyright", "value" => (self.current_notes.blank? ? 'n/a' : self.current_notes), "short" => false})
    end
    attachment["fields"].push({"title" => "Details", "value" => self.notification_url, "short" => false})
    post_options[:attachment] = attachment
    SlackNotification.post(post_options)
    true
  end





end
