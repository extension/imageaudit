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


end
