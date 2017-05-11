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
      image_scope = HostedImage.linked
    end


    if(@page_status = params[:page_status])
      @filtered = true
      @filter_strings << "Page Status: #{@page_status}"
      case @page_status
      when 'All'
        @filtered = false
        image_scope = (@community.nil? ? HostedImage.linked : @community.hosted_images)
      when 'Viewed'
        image_scope = (@community.nil? ? HostedImage.viewed(true) : @community.hosted_images.viewed(true))
      when 'Unviewed'
        image_scope = (@community.nil? ? HostedImage.viewed(false) : @community.hosted_images.viewed(false))
      else
        @filtered = false
        image_scope = (@community.nil? ? HostedImage.linked : @community.hosted_images)
      end
    end


    if(@stock = params[:stock])
      if(TRUE_VALUES.include?(params[:stock]))
        @stock = 'Yes'
      elsif(FALSE_VALUES.include?(params[:stock]))
        @stock = 'No'
      end
      @pagination_params[:stock] = @stock
      @filter_strings << "Stock status: #{@stock}"
      @filtered = true
      image_scope = image_scope.stock(@stock)
    end

    if(@community_reviewed = params[:community_reviewed])
      @pagination_params[:community_reviewed] = @community_reviewed
      @filter_strings << "Community copyright review status: #{@community_reviewed}"
      @filtered = true
      image_scope = image_scope.community_reviewed(@community_reviewed)
    end

    if(@staff_reviewed = params[:staff_reviewed])
      @pagination_params[:staff_reviewed] = @staff_reviewed
      @filter_strings << "Staff copyright review status: #{@staff_reviewed}"
      @filtered = true
      image_scope = image_scope.staff_reviewed(@staff_reviewed)
    end

    if(!params[:copyrightsearch].blank?)
      @pagination_params[:copyrightsearch] = params[:copyrightsearch]
      @filter_strings << "Copyright text has following terms: #{params[:copyrightsearch]}"
      @filtered = true
      image_scope = image_scope.search_copyright_terms(params[:copyrightsearch])
    end

    if(@community.nil? and !@filtered)
      image_scope = image_scope.linked
    end

    @images = image_scope.order("hosted_images.id desc").page(params[:page]).per(10)
  end

  def show
    @image = HostedImage.find(params[:id])
  end

  def change_communityreview
    @image = HostedImage.find(params[:id])
    if(!params[:community_reviewed].nil?)
      previous_value = @image.community_reviewed
      if(params[:community_reviewed] == 'clear')
        @image.update_attributes({community_reviewed: nil, community_reviewed_by: nil})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'community_reviewed',
                        previous_check_value: previous_value,
                        current_check_value: nil)
      else
        community_reviewed = TRUE_VALUES.include?(params[:community_reviewed])
        @image.update_attributes({community_reviewed: community_reviewed, community_reviewed_by: @currentcontributor.id})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'community_reviewed',
                        previous_check_value: previous_value,
                        current_check_value: @image.community_reviewed?)
      end
    end
  end

  def change_staffreview
    @image = HostedImage.find(params[:id])
    if(!params[:staff_reviewed].nil?)
      previous_value = @image.staff_reviewed
      if(params[:staff_reviewed] == 'clear')
        @image.update_attributes({staff_reviewed: nil, staff_reviewed_by: nil})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'staff_reviewed',
                        previous_check_value: previous_value,
                        current_check_value: nil)
      else
        staff_reviewed = TRUE_VALUES.include?(params[:staff_reviewed])
        @image.update_attributes({staff_reviewed: staff_reviewed, staff_reviewed_by: @currentcontributor.id})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'staff_reviewed',
                        previous_check_value: previous_value,
                        current_check_value: @image.staff_reviewed?)
      end
    end
  end


  def change_stock
    @image = HostedImage.find(params[:id])
    if(!params[:is_stock].nil?)
      previous_value = @image.is_stock
      if(params[:is_stock] == 'clear')
        @image.update_attributes({is_stock: nil, is_stock_by: nil})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'is_stock',
                        previous_check_value: previous_value,
                        current_check_value: nil)
      else
        is_stock = TRUE_VALUES.include?(params[:is_stock])
        @image.update_attributes({is_stock: is_stock, is_stock_by: @currentcontributor.id})
        AuditLog.create(contributor: @currentcontributor,
                        auditable: @image,
                        changed_item: 'is_stock',
                        previous_check_value: previous_value,
                        current_check_value: @image.is_stock)
      end

    end
  end

  def set_notes
    @image = HostedImage.find(params[:id])

    if(params[:commit] == 'Save Changes')
      previous_notes = @image.notes
      @image.update_attribute(:notes,params[:hosted_image][:notes])
      AuditLog.create(contributor: @currentcontributor,
                      auditable: @image,
                      changed_item: 'notes',
                      previous_notes: previous_notes,
                      current_notes: @image.notes)
    end
    respond_to do |format|
      format.js
    end
  end

  def bulk_change_stock_and_staff_review
    selected_images = params[:selected_image_ids]

    if !selected_images.nil?
      selected_images.each do |image|
        HostedImage.bulk_change_stock_and_staff_review(image, @currentcontributor.id)
      end
    end

    redirect_to images_path(staff_reviewed: "Unreviewed")
  end

end
