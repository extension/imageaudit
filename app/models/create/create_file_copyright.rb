# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class CreateFileCopyright < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name = 'field_data_field_copyright'
  belongs_to :create_file, :foreign_key => :entity_id

end
