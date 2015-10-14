# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file
require 'fileutils'

class CreateFile < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name = 'file_managed'
  self.primary_key = "fid"
  self.inheritance_column = "inheritance_type"

  has_one :copyright, :class_name => 'CreateFileCopyright', :foreign_key => :entity_id


  def create_copyright_update_query(copyright_string)
    ['data','revision'].each do |data_or_revision|
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{self.class.connection.current_database}.field_#{data_or_revision}_field_copyright (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_copyright_value, field_copyright_format)
      SELECT 'file',
             #{ActiveRecord::Base.quote_value("#{self.type}")},
             0,
             #{self.fid},
             #{self.fid},
             'und',
             0,
             #{ActiveRecord::Base.quote_value(copyright_string)},
             'NULL'
      ON DUPLICATE KEY
      UPDATE field_copyright_value=#{ActiveRecord::Base.quote_value(copyright_string)}
      END_SQL
      self.class.connection.execute(query)
    end
    true
  end


end
