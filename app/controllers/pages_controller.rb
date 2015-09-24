# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

require 'csv'

class PagesController < ApplicationController

  def show
    @page = Page.find(params[:id])
  end

  def index
    @pagination_params = {}
    @filter_strings = []
    @filtered = false

    if(params[:community_id] and @community = Group.find_by_id(params[:community_id]))
      @pagination_params[:community_id] = params[:community_id]
      @filter_strings << "Community: #{@community.name}"
      @filtered = true
      page_scope = @community.pages
    else
      page_scope = Page.scoped({})
    end


    if(@page_status = params[:page_status])
      @filtered = true
      @filter_strings << "Page Status: #{@page_status}"
      case @page_status
      when 'All'
        @filtered = false
      when 'Eligible'
        page_scope = page_scope.eligible(true)
      when 'New'
        page_scope = page_scope.eligible(false)
      when 'Viewed'
        page_scope = page_scope.viewed(true).order('mean_unique_pageviews desc')
      when 'Unviewed'
        page_scope = page_scope.viewed(false).order('mean_unique_pageviews asc')
      when 'Missing'
        page_scope = page_scope.missing
      when 'Keep'
        page_scope = page_scope.keep(true).order('mean_unique_pageviews desc')
      when 'Unpublish'
        page_scope = page_scope.keep(false).order('mean_unique_pageviews asc')
      else
        @filtered = false
      end
    end

    if(!params[:download].nil? and params[:download] == 'csv')
      @page_title_display = "pagelist-"
      if(@filter_strings)
        @page_title_display << @filter_strings.join('-')
      end
      @page_title_display += "-" + Time.now.strftime("%Y-%m-%d")
      @pages = page_scope.all
      send_data(csv_output(@pages),
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{@page_title_display.downcase.gsub(' ','_')}.csv")
    else
      @pages = page_scope.page(params[:page]).per(25)
    end
  end


  def change_keeppublished
    @page = Page.find(params[:id])
    if(!params[:keep_published].nil?)
      keep_published = TRUE_VALUES.include?(params[:keep_published])
      previous_value = @page.keep_published
      is_stock = TRUE_VALUES.include?(params[:keep_published])
      @page.update_attributes({keep_published: keep_published, keep_published_by: @currentcontributor.id})
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @page,
                      changed_item: 'keep_published',
                      previous_check_value: previous_value,
                      current_check_value: @page.keep_published?)
    end
  end

  def set_notes
    @page = Page.find(params[:id])

    if(params[:commit] == 'Save Changes')
      previous_notes = @page.notes
      @page.update_attribute(:notes,params[:page][:notes])
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @page,
                      changed_item: 'notes',
                      previous_notes: previous_notes,
                      current_notes: @page.notes)
    end
    respond_to do |format|
      format.js
    end
  end

  protected

  def csv_output(pages)
    CSV.generate do |csv|
      headers = []
      headers << 'Page ID#'
      headers << 'Keep Published'
      headers << 'Page Type'
      headers << "Weeks Published (Prior to #{Page::END_DATE})"
      headers << 'Unique Pageviews'
      headers << 'Mean Unique Pageviews'
      headers << 'Page Source'
      headers << 'Source URL'
      headers << 'Pageinfo URL'
      headers << 'Image Links'
      headers << 'Hosted Images'
      headers << 'Communities'
      headers << 'Tags'
      headers << 'Notes'
      csv << headers
      pages.each do |page|
        row = []
        row << page.id
        if(page.keep_published.nil?)
          row << 'Unreviewed'
        elsif(page.keep_published?)
          row << 'Yes'
        else
          row << 'No'
        end
        row << "#{page.datatype}"
        row << page.weeks_published
        if(page.weeks_published > 0)
          row << page.unique_pageviews
          row << page.mean_unique_pageviews
        else
          row << 'n/a'
          row << 'n/a'
        end
        row << "#{page.source}"
        row << "#{page.source_url}"
        row << "http://#{Settings.articles_site}/pageinfo/#{page.id}"
        row << page.image_links
        row << page.hosted_images
        row << "#{page.groups.publishing.map(&:name).join(',')}"
        row << "#{page.tags.map(&:name).join(',')}"
        if(!page.notes.blank?)
          row << "#{page.html_to_pretty_text(page.notes)}"
        else
          row << ''
        end
        csv << row
      end
    end
  end

end
