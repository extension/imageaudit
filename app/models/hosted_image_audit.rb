# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class HostedImageAudit < ActiveRecord::Base
  belongs_to :hosted_image
  has_many :pages, :through => :hosted_image
  belongs_to :is_stock_reviewer,  :class_name => "Contributor", :foreign_key => "is_stock_by"
  belongs_to :community_reviewer,  :class_name => "Contributor", :foreign_key => "community_reviewed_by"
  belongs_to :staff_reviewer,      :class_name => "Contributor", :foreign_key => "staff_reviewed_by"
  has_many :audit_logs, :as => :auditable

end
