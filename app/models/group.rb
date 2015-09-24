# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Group < ActiveRecord::Base

  EXTENSION_STAFF = 30


  has_many :tags
  has_many  :group_pages
  has_many :pages, :through => :group_pages
  has_many :group_images
  has_many :hosted_images, :through => :group_images
  has_many :paged_images, :through => :pages, :source => :hosted_images, :uniq => true

  has_many :links, :through => :pages
  has_one  :community_page_stat

  scope :launched, -> {where(is_launched: true)}
  scope :publishing,-> {where(publishing_community: true)}

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    PeopleCommunity.where("drupal_node_id IS NOT NULL").each do |group|
      insert_list = []
      insert_list << group.id
      insert_list << group.drupal_node_id
      insert_list << ActiveRecord::Base.quote_value(group.name)
      if(group.publishing_community? and pc = ArticlePublishingCommunity.find_by_id(group.id))
        insert_list << pc.is_launched
      else
        insert_list << 0
      end
      insert_list << group.publishing_community
      insert_list << ActiveRecord::Base.quote_value(group.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(group.updated_at.to_s(:db))
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
    true
  end


  def page_stat_attributes
    total_pages = self.pages.count
    eligible_pages = self.pages.eligible_pages.count
    viewed_pages = self.pages.viewed.count
    viewed_percentiles = self.mup_percentiles
    attributes = {}
    attributes[:total_pages] = total_pages
    attributes[:eligible_pages] = eligible_pages
    attributes[:viewed_pages] = viewed_pages
    attributes[:viewed_percentiles] = viewed_percentiles
    attributes[:image_links] = self.links.image.count("distinct links.id")
    attributes[:viewed_image_links] = self.links.image.joins(:linkedpages).where("pages.mean_unique_pageviews >= 1").count("distinct links.id")
    attributes[:hosted_images] = self.hosted_images.linked.count
    attributes[:viewed_hosted_images] = self.hosted_images.viewed.count
    attributes[:keep_pages] = self.pages.keep.count
    attributes[:keep_image_links] = self.links.image.joins(:linkedpages).where("pages.keep_published = 1").count("distinct links.id")
    attributes[:keep_hosted_images] = self.hosted_images.keep.count
    attributes[:keep_stock_images] = self.hosted_images.keep.stock('Yes').count
    attributes[:keep_not_stock_images] = self.hosted_images.keep.stock('No').count
    attributes
  end

  def mup_percentiles
    mups = self.pages.pluck(:mean_unique_pageviews)
    viewed_percentiles = []
    Page::PERCENTILES.each do |percentile|
      viewed_percentiles << mups.nist_percentile(percentile)
    end
    viewed_percentiles
  end




end
