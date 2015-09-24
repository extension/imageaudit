# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PageHostedImage < ActiveRecord::Base
  belongs_to :hosted_image
  belongs_to :page


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{self.connection.current_database}.#{self.table_name} (page_id, hosted_image_id)
    SELECT pages.id, hosted_images.id
    FROM pages,hosted_images,hosted_image_links,links,linkings
    WHERE
    pages.id = linkings.page_id
    AND linkings.link_id = links.id
    AND links.id = hosted_image_links.link_id
    AND hosted_image_links.hosted_image_id = hosted_images.id
    END_SQL
    self.connection.execute("#{query}")
  end

end
