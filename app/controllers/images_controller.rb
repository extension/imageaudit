# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file


class ImagesController < ApplicationController

  def index
    @pagination_params = {}
    @filter_strings = []
    @filtered = false

    if(params[:community_id] and @community = Group.find_by_id(params[:community_id]))
      @pagination_params[:community_id] = params[:community_id]
      @filter_strings << "Community: #{@community.name}"
      @filtered = true
      image_scope = @community.hosted_images
    else
      image_scope = HostedImage.scoped({})
    end

    if(params[:viewed] and TRUE_VALUES.include?(params[:viewed]))
      @pagination_params[:viewed] = params[:viewed]
      @filter_strings << "Viewed images only"
      @filtered = true
      if(@community)
        image_scope = @community.viewed_images.viewed
      else
        image_scope = image_scope.viewed
      end
    else
      if(@community.nil?)
        image_scope = image_scope.linked
      end
    end

    if(params[:copyright] and TRUE_VALUES.include?(params[:copyright]))
      @pagination_params[:copyright] = params[:copyright]
      @filter_strings << "With copyright"
      @filtered = true
      image_scope = image_scope.with_copyright
    end
    @images = image_scope.page(params[:page]).per(10)
  end

  def show
    @image = HostedImage.find(params[:id])
  end

end
