# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticlePage < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'pages'
  JOINER = ", "
  SPLITTER = Regexp.new(/\s*,\s*/)

  has_one :article_link_stat, :foreign_key => "page_id"

  def link_counts
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(!self.article_link_stat.nil?)
      linkcounts.keys.each do |key|
        linkcounts[key] = self.article_link_stat.send(key)
      end
    end
    return linkcounts
  end

end
