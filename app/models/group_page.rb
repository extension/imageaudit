# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GroupPage < ActiveRecord::Base
  belongs_to :group
  belongs_to :page


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{self.connection.current_database}.#{self.table_name} (page_id, group_id)
    SELECT pages.id, groups.id
    FROM pages,groups,tags,page_taggings
    WHERE
    pages.id = page_taggings.page_id
    AND page_taggings.tag_id = tags.id
    AND tags.group_id = groups.id
    END_SQL
    self.connection.execute("#{query}")
  end

end
