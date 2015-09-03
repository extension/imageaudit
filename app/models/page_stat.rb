# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding from the eXtension Foundation
# === LICENSE:
#
#  see LICENSE file

class PageStat < ActiveRecord::Base

  belongs_to :page
  has_many :images_hosted, :through => :page, :source => :hosted_images
  has_many :links, :through => :page


  # hardcoded right now
  START_DATE = Date.parse('2014-08-24')
  END_DATE = Date.parse('2015-08-22')

  PERCENTILES = [99,95,90,75,50,25,10]

  scope :eligible_pages, -> {where("weeks_published > 0")}
  scope :viewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews >= ?",view_base)}
  scope :unviewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews < ?",view_base)}
  scope :missing, -> {eligible_pages.where("mean_unique_pageviews = 0")}


  def update_stats
    p = self.page
    self.update_attributes(p.page_stat_attributes)
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    # get stat sets
    unique_pageviews_set = Page.joins(:year_analytics).group('pages.id').sum(:unique_pageviews)
    image_link_set = Page.joins(:links).where('links.linktype = ?',Link::IMAGE).group('pages.id').count
    hosted_image_set = Page.joins(:hosted_images).group('pages.id').count
    insert_columns = ['page_id','unique_pageviews','weeks_published','mean_unique_pageviews','image_links','hosted_images','created_at','updated_at']
    Page.find_in_batches do |group|
      insert_values = []
      group.each do |page|
        weeks_published = page.weeks_published
        insert_list = []
        insert_list << page.id
        insert_list << (unique_pageviews_set[page.id].nil? ? 0 : unique_pageviews_set[page.id])
        insert_list << weeks_published
        if(weeks_published > 52)
          insert_list << (unique_pageviews_set[page.id].nil? ? 0 : unique_pageviews_set[page.id] / 52 )
        elsif(weeks_published > 0)
          insert_list << (unique_pageviews_set[page.id].nil? ? 0 : unique_pageviews_set[page.id] / weeks_published )
        else
          insert_list << 0
        end
        insert_list << (image_link_set[page.id].nil? ? 0 : image_link_set[page.id])
        insert_list << (hosted_image_set[page.id].nil? ? 0 : hosted_image_set[page.id])
        insert_list << 'NOW()'
        insert_list << 'NOW()'
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (#{insert_columns.join(', ')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
    true
  end


  def self.overall_stat_attributes(rebuild = false)
    if(!rebuild and cps = CommunityPageStat.where(group_id: 0).first)
      cps.attributes
    else
      total_pages = self.count
      eligible_pages = self.eligible_pages.count
      viewed_pages = self.viewed.count
      viewed_percentiles = self.mup_percentiles
      keep_pages = Page.keep.count

      attributes = {}
      attributes[:total_pages] = total_pages
      attributes[:eligible_pages] = eligible_pages
      attributes[:viewed_pages] = viewed_pages
      attributes[:keep_pages] = keep_pages

      attributes[:viewed_percentiles] = viewed_percentiles
      attributes[:image_links] = Link.image.count("distinct links.id")
      attributes[:viewed_image_links] = Link.image.joins(:page_stats).where("page_stats.mean_unique_pageviews >= 1").count("distinct links.id")
      attributes[:keep_image_links] = Link.image.joins(:page_audits).where("page_audits.keep_published = 1").count("distinct links.id")

      attributes[:hosted_images] = HostedImage.published_count
      attributes[:viewed_hosted_images] = HostedImage.viewed_count

      attributes[:keep_hosted_images] = HostedImage.keep.count
      attributes[:keep_stock_images] = HostedImage.keep_stock.count
      attributes[:keep_not_stock_images] = HostedImage.keep_stock({:is_stock => false}).count

      if(cps = CommunityPageStat.where(group_id: 0).first)
        cps.update_attributes(attributes)
      else
        cps = CommunityPageStat.create(attributes.merge({:group_id => 0}))
      end
      cps.attributes
    end
  end

  def self.mup_percentiles
    mups = self.pluck(:mean_unique_pageviews)
    viewed_percentiles = []
    PageStat::PERCENTILES.each do |percentile|
      viewed_percentiles << mups.nist_percentile(percentile)
    end
    viewed_percentiles
  end

end
