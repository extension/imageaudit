# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Group < ActiveRecord::Base

  EXTENSION_STAFF = 30


  has_many :tags
  has_many :pages, :through => :tags
  has_many :hosted_images, :through => :pages, :uniq => true
  has_many :page_stats, :through => :pages
  has_many :page_audits, :through => :pages
  has_many :links, :through => :pages
  has_many :keep_images, :through => :page_audits, :source => :images_hosted, :uniq => true
  has_many :viewed_images, :through => :page_stats, :source => :images_hosted, :uniq => true
  has_many :keep_links, :through => :page_audits, :source => :links, :uniq => true
  has_many :viewed_links, :through => :page_stats, :source => :links, :uniq => true
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
    eligible_pages = self.page_stats.eligible_pages.count
    viewed_pages = self.page_stats.viewed.count
    viewed_percentiles = self.mup_percentiles
    attributes = {}
    attributes[:total_pages] = total_pages
    attributes[:eligible_pages] = eligible_pages
    attributes[:viewed_pages] = viewed_pages
    attributes[:viewed_percentiles] = viewed_percentiles
    attributes[:image_links] = self.links.image.count("distinct links.id")
    attributes[:viewed_image_links] = self.links.image.joins(:page_stats).where("page_stats.mean_unique_pageviews >= 1").count("distinct links.id")
    attributes[:hosted_images] = self.hosted_images.published_count
    attributes[:viewed_hosted_images] = self.viewed_images.viewed_count
    attributes[:keep_pages] = self.pages.keep.count
    attributes[:keep_image_links] = self.keep_links.image.joins(:page_audits).where("page_audits.keep_published = 1").count("distinct links.id")
    attributes[:keep_hosted_images] = self.keep_images.keep.count
    attributes[:keep_stock_images] = self.keep_images.keep_stock.count
    attributes[:keep_not_stock_images] = self.keep_images.keep_stock({:is_stock => false}).count
    attributes
  end

  def mup_percentiles
    mups = self.page_stats.pluck(:mean_unique_pageviews)
    viewed_percentiles = []
    PageStat::PERCENTILES.each do |percentile|
      viewed_percentiles << mups.nist_percentile(percentile)
    end
    viewed_percentiles
  end




end
