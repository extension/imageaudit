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
    @images = image_scope.order("hosted_images.id desc").page(params[:page]).per(10)
  end

  def show
    @image = HostedImage.find(params[:id])
    if(!@image_audit = @image.hosted_image_audit)
      @image_audit = @image.create_hosted_image_audit
    end
  end

  def change_stock
    @image = HostedImage.find(params[:id])
    @image_audit = @image.hosted_image_audit
    if(!params[:is_stock].nil?)
      previous_value = @image_audit.is_stock
      is_stock = TRUE_VALUES.include?(params[:is_stock])
      @image_audit.update_attributes({is_stock: is_stock, is_stock_by: @currentcontributor.id})
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @image_audit,
                      changed_item: 'is_stock',
                      previous_check_value: previous_value,
                      current_check_value: @image_audit.is_stock)
    end
  end

  def set_notes
    @image = HostedImage.find(params[:id])
    if(!@image_audit = @image.hosted_image_audit)
      @image_audit = @image.create_hosted_image_audit
    end

    if(params[:commit] == 'Save Changes')
      previous_notes = @image_audit.notes
      @image_audit.update_attribute(:notes,params[:hosted_image_audit][:notes])
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @image_audit,
                      changed_item: 'notes',
                      previous_notes: previous_notes,
                      current_notes: @image_audit.notes)
    end
    respond_to do |format|
      format.js
    end
  end

end
