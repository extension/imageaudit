# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GroupImage < ActiveRecord::Base
  belongs_to :group
  belongs_to :hosted_image


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{self.connection.current_database}.#{self.table_name} (hosted_image_id, group_id)
    SELECT hosted_images.id, groups.id
    FROM hosted_images,groups,group_pages,page_hosted_images,pages
    WHERE
    hosted_images.id = page_hosted_images.hosted_image_id
    AND page_hosted_images.page_id = pages.id
    AND pages.id = group_pages.page_id
    AND group_pages.group_id = groups.id
    END_SQL
    self.connection.execute("#{query}")
  end

end
