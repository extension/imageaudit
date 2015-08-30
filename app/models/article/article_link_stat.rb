# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticleLinkStat < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'link_stats'

  belongs_to :article_page, :foreign_key => "page_id"
end
