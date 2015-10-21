# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Group < ActiveRecord::Base
  include CacheTools

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
    self.class.stats_by_group[self.id]
  end

  def mup_percentiles
    mups = self.pages.pluck(:mean_unique_pageviews)
    viewed_percentiles = []
    Page::PERCENTILES.each do |percentile|
      viewed_percentiles << mups.nist_percentile(percentile)
    end
    viewed_percentiles
  end

  def self.stats_by_group
      # get stat sets
      all_group_stats = {}
      pages_set = Group.publishing.joins(:pages).group('groups.id').count
      eligible_pages_set = Group.publishing.joins(:pages).where("pages.weeks_published >= ?",1).group("groups.id").count
      viewed_pages_set = Group.publishing.joins(:pages).where("pages.mean_unique_pageviews >= ?",1).group("groups.id").count
      image_link_set = Group.publishing.joins(:links => :linkedpages).where('links.linktype = ?',Link::IMAGE).group('groups.id').count('distinct links.id')
      hosted_image_set = Group.publishing.joins(:hosted_images).group('groups.id').count('distinct hosted_images.id')
      stock_hosted_image_set = Group.publishing.joins(:hosted_images).where("hosted_images.is_stock = 1").group('groups.id').count('distinct hosted_images.id')
      unreviewed_stock_hosted_image_set = Group.publishing.joins(:hosted_images).where("hosted_images.is_stock is NULL").group('groups.id').count('distinct hosted_images.id')
      staff_reviewed_hosted_image_set = Group.publishing.joins(:hosted_images).where("hosted_images.staff_reviewed is NOT NULL").group('groups.id').count('distinct hosted_images.id')
      staff_unreviewed_hosted_image_set = Group.publishing.joins(:hosted_images).where("hosted_images.staff_reviewed is NULL").group('groups.id').count('distinct hosted_images.id')
      staff_complete_hosted_image_set = Group.publishing.joins(:hosted_images).where("hosted_images.staff_reviewed = 1").group('groups.id').count('distinct hosted_images.id')
      staff_incomplete_hosted_image_set  = Group.publishing.joins(:hosted_images).where("hosted_images.staff_reviewed = 0").group('groups.id').count('distinct hosted_images.id')


      Group.publishing.all.each do |group|
        group_stats = {}
        group_stats['total_pages']= (pages_set[group.id].nil? ? 0 : pages_set[group.id])
        group_stats['eligible_pages']= (eligible_pages_set[group.id].nil? ? 0 : eligible_pages_set[group.id])
        group_stats['viewed_pages']= (viewed_pages_set[group.id].nil? ? 0 : viewed_pages_set[group.id])
        group_stats['image_links']= (image_link_set[group.id].nil? ? 0 : image_link_set[group.id])
        group_stats['hosted_images']= (hosted_image_set[group.id].nil? ? 0 : hosted_image_set[group.id])
        group_stats['stock_hosted_images']= (stock_hosted_image_set[group.id].nil? ? 0 : stock_hosted_image_set[group.id])
        group_stats['unreviewed_stock_hosted_images']= (unreviewed_stock_hosted_image_set[group.id].nil? ? 0 : unreviewed_stock_hosted_image_set[group.id])
        group_stats['staff_reviewed_hosted_images']= (staff_reviewed_hosted_image_set[group.id].nil? ? 0 : staff_reviewed_hosted_image_set[group.id])
        group_stats['staff_unreviewed_hosted_images']= (staff_unreviewed_hosted_image_set[group.id].nil? ? 0 : staff_unreviewed_hosted_image_set[group.id])
        group_stats['staff_complete_hosted_images']= (staff_complete_hosted_image_set[group.id].nil? ? 0 : staff_complete_hosted_image_set[group.id])
        group_stats['staff_incomplete_hosted_images']= (staff_incomplete_hosted_image_set[group.id].nil? ? 0 : staff_incomplete_hosted_image_set[group.id])
        all_group_stats[group.id] = group_stats
        all_group_stats[group.id]['group_name'] = group.name
      end
      all_group_stats
  end


end
