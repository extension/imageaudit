# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

# join class for content <=> links

class ArticleLinking < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'linkings'

  belongs_to :article_page, :foreign_key => "page_id"
  belongs_to :article_link, :foreign_key => "link_id"
end
