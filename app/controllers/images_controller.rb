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

    # viewed, keep, keep_stock are mutually exclusive
    if(params[:viewed] and TRUE_VALUES.include?(params[:viewed]))
      @pagination_params[:viewed] = params[:viewed]
      @filter_strings << "Viewed images only"
      @filtered = true
      if(@community)
        image_scope = @community.viewed_images.viewed
      else
        image_scope = HostedImage.viewed
      end
    end

    if(params[:keep] and TRUE_VALUES.include?(params[:keep]))
      @pagination_params[:keep] = params[:keep]
      @filter_strings << "Kept images only"
      @filtered = true
      if(@community)
        image_scope = @community.keep_images.keep
      else
        image_scope = HostedImage.keep
      end
    end

    if(params[:keep_stock] and TRUE_VALUES.include?(params[:keep_stock]))
      @pagination_params[:keep_stock] = params[:keep_stock]
      @filter_strings << "Kept images only"
      @filter_strings << "Stock images"
      @filtered = true
      if(@community)
        image_scope = @community.keep_images.keep_stock
      else
        image_scope = HostedImage.keep_stock
      end
    end

    if(params[:keep_stock] and FALSE_VALUES.include?(params[:keep_stock]))
      @pagination_params[:keep_stock] = params[:keep_stock]
      @filter_strings << "Kept images only"
      @filter_strings << "Non-Stock images"
      @filtered = true
      if(@community)
        image_scope = @community.keep_images.keep_stock(:is_stock => false)
      else
        image_scope = HostedImage.keep_stock(:is_stock => false)
      end
    end

    if(params[:keep_unreviewed_stock] and TRUE_VALUES.include?(params[:keep_unreviewed_stock]))
      @pagination_params[:keep_unreviewed_stock] = params[:keep_unreviewed_stock]
      @filter_strings << "Kept images only"
      @filter_strings << "Not yet reviewed for Stock"
      @filtered = true
      if(@community)
        image_scope = @community.keep_images.keep_stock({is_stock: 'unreviewed'})
      else
        image_scope = HostedImage.keep_stock({is_stock: 'unreviewed'})
      end
    end

    if(params[:copyright] and TRUE_VALUES.include?(params[:copyright]))
      @pagination_params[:copyright] = params[:copyright]
      @filter_strings << "With copyright"
      @filtered = true
      image_scope = image_scope.with_copyright
    end


    if(@community.nil? and !@filtered)
      image_scope = image_scope.linked
    end

    @images = image_scope.order("hosted_images.id desc").page(params[:page]).per(10)
  end

  def show
    @image = HostedImage.find(params[:id])
    if(!@image_audit = @image.hosted_image_audit)
      @image_audit = @image.create_hosted_image_audit
    end
  end

  def change_communityreview
    @image = HostedImage.find(params[:id])
    @image_audit = @image.hosted_image_audit
    if(!params[:community_reviewed].nil?)
      previous_value = @image_audit.community_reviewed?
      community_reviewed = TRUE_VALUES.include?(params[:community_reviewed])
      @image_audit.update_attributes({community_reviewed: community_reviewed, community_reviewed_by: @currentcontributor.id})
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @image_audit,
                      changed_item: 'community_reviewed',
                      previous_check_value: previous_value,
                      current_check_value: @image_audit.community_reviewed?)
    end
  end

  def change_staffreview
    @image = HostedImage.find(params[:id])
    @image_audit = @image.hosted_image_audit
    if(!params[:staff_reviewed].nil?)
      previous_value = @image_audit.staff_reviewed?
      staff_reviewed = TRUE_VALUES.include?(params[:staff_reviewed])
      @image_audit.update_attributes({staff_reviewed: staff_reviewed, staff_reviewed_by: @currentcontributor.id})
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @image_audit,
                      changed_item: 'staff_reviewed',
                      previous_check_value: previous_value,
                      current_check_value: @image_audit.staff_reviewed?)
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
