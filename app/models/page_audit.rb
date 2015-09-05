# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class PageAudit < ActiveRecord::Base
  include MarkupScrubber
  has_many :audit_logs, :as => :auditable
  belongs_to :page
  has_many :images_hosted, :through => :page, :source => :hosted_images
  has_many :links, :through => :page
  belongs_to :keep_published_reviewer,  :class_name => "Contributor", :foreign_key => "keep_published_by"
  belongs_to :community_reviewer,  :class_name => "Contributor", :foreign_key => "community_reviewed_by"
  belongs_to :staff_reviewer,      :class_name => "Contributor", :foreign_key => "staff_reviewed_by"
end
