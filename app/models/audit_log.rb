# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class AuditLog < ActiveRecord::Base
  belongs_to :auditable, :polymorphic => true
  belongs_to :contributor
  
end
