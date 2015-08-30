# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticleTag < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'tags'

  has_many :article_taggings, :foreign_key => "tag_id"
  has_many :article_communities, :through => :article_taggings, :source => :article_publishing_community, :uniq => true



  def self.community_resource_tags
    includes(:article_taggings).where("taggings.taggable_type = 'PublishingCommunity'").order(:name)
  end

end
