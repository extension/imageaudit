# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

# join class for content <=> links

class ArticleLink < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'links'

  has_many :article_linkings, :foreign_key => "link_id"

end
