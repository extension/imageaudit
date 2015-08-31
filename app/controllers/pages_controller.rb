# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file


class PagesController < ApplicationController

  def show
    @page = Page.includes(:page_stat).find_by_id(params[:id])
    if(@page.nil?)
      return do_404
    end
    @stats = @page.page_stat
    if(!@page_audit = @page.page_audit)
      @page_audit = @page.create_page_audit
    end
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

    if(params[:eligible] and TRUE_VALUES.include?(params[:eligible]))
      @pagination_params[:eligible] = params[:eligible]
      @filter_strings << "Eligible pages"
      @filtered = true
      page_scope = page_scope.eligible
    end

    if(params[:viewed] and TRUE_VALUES.include?(params[:viewed]))
      @pagination_params[:viewed] = params[:viewed]
      @filter_strings << "Viewed pages"
      @filtered = true
      page_scope = page_scope.viewed.joins(:page_stat).order('mean_unique_pageviews desc')
    end

    if(params[:unviewed] and TRUE_VALUES.include?(params[:unviewed]))
      @pagination_params[:copyright] = params[:copyright]
      @filter_strings << "Unviewed pages"
      @filtered = true
      page_scope = page_scope.unviewed.joins(:page_stat).order('mean_unique_pageviews asc')
    end

    if(params[:missing] and TRUE_VALUES.include?(params[:missing]))
      @pagination_params[:copyright] = params[:copyright]
      @filter_strings << "Missing pages"
      @filtered = true
      page_scope = page_scope.missing
    end
    @pages = page_scope.page(params[:page]).per(25)
  end


  def change_keeppublished
    @page = Page.find(params[:id])
    @page_audit = @page.page_audit
    if(!params[:keep_published].nil?)
      previous_value = @page_audit.keep_published?
      is_stock = TRUE_VALUES.include?(params[:keep_published])
      @page_audit.update_attributes({keep_published: keep_published, keep_published_by: @currentcontributor.id})
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @page_audit,
                      changed_item: 'keep_published',
                      previous_check_value: previous_value,
                      current_check_value: @page_audit.keep_published?)
    end
  end

  def set_notes
    @page = Page.find(params[:id])
    if(!@page_audit = @page.page_audit)
      @page_audit = @page.create_page_audit
    end

    if(params[:commit] == 'Save Changes')
      previous_notes = @page_audit.notes
      @page_audit.update_attribute(:notes,params[:page_audit][:notes])
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @page_audit,
                      changed_item: 'notes',
                      previous_notes: previous_notes,
                      current_notes: @page_audit.notes)
    end
    respond_to do |format|
      format.js
    end
  end

end
