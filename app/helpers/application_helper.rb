# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file
module ApplicationHelper

  def imageaudit_link(image,options = {})
    link_to(image_tag(image.src_path, class: 'imageaudit'), image.src_path, options).html_safe
  end

  def imageaudit_sourcelink(image)
    if(image.source == 'copwiki')
      'copwiki'
    elsif(image.source == 'create')
      link_to('create',"http://#{Settings.create_site}/file/#{image.source_id}", target: '_blank').html_safe
    else
      ''
    end
  end

  def pageinfo_link(page_id,link_text = 'page info')
    link_to(link_text,"http://#{Settings.articles_site}/pageinfo/#{page_id}", target: '_blank').html_safe
  end



  def percentage_display(partial,total)
    if(total == 0)
      'n/a'
    else
      number_to_percentage((partial /total) * 100, :precision => 1 )
    end
  end

  def twitter_alert_class(type)
    baseclass = "alert"
    case type
    when :alert
      "#{baseclass} alert-warning"
    when :error
      "#{baseclass} alert-error"
    when :notice
      "#{baseclass} alert-info"
    when :success
      "#{baseclass} alert-success"
    else
      "#{baseclass} #{type.to_s}"
    end
  end

  def nav_item(path,label)
    list_item_class = current_page?(path) ? " class='active'" : ''
    "<li#{list_item_class}>#{link_to(label,path)}</li>".html_safe
  end

  def audit_log_itemlink(audit_log)
    ao = audit_log.changed_object
    if(ao.nil?)
      "#{audit_log.audit_type} ID# Unknown (item has been removed from imageaudit database)"
    elsif(ao.class.name == 'HostedImage')
      link_to("Image ID# #{ao.id}",image_path(id: ao.id)).html_safe
    elsif(ao.class.name == 'Page')
      link_to("Page ID# #{ao.id}",page_path(id: ao.id)).html_safe
    else
      "#{audit_log.audit_type} ID# #{ao.id}"
    end
  end


end
