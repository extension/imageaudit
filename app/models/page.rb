# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Page < ActiveRecord::Base
  include CacheTools
  include MarkupScrubber
  has_many :year_analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  has_many :group_pages
  has_many :groups, :through => :group_pages
  has_many :linkings, dependent: :destroy
  has_many :links, :through => :linkings
  has_many :page_hosted_images
  has_many :hosted_images, :through => :page_hosted_images

  belongs_to :keep_published_reviewer,  :class_name => "Contributor", :foreign_key => "keep_published_by"
  belongs_to :community_reviewer,  :class_name => "Contributor", :foreign_key => "community_reviewed_by"
  belongs_to :staff_reviewer,      :class_name => "Contributor", :foreign_key => "staff_reviewed_by"


  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2

  # hardcoded right now
  START_DATE = Date.parse('2014-08-24')
  END_DATE = Date.parse('2015-08-22')

  PERCENTILES = [99,95,90,75,50,25,10]
  DATATYPES = ['Article','Faq']

  scope :articles, where(:datatype => 'Article')
  scope :faqs, where(:datatype => 'Faq')
  scope :created_since, lambda{|date| where("#{self.table_name}.created_at >= ?",date)}
  scope :from_create, where(:source => 'create')

  scope :eligible_pages, -> {where("weeks_published > 0")}
  scope :viewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews >= ?",view_base)}
  scope :unviewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews < ?",view_base)}
  scope :missing, -> {eligible_pages.where("mean_unique_pageviews = 0")}

  scope :tagged_with, lambda{|tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id").having("COUNT(#{self.table_name}.id) = #{tag_list.size}")
  }

  scope :tagged_with_any, lambda { |tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id")
  }

  def self.eligible(flag = true)
    if(flag)
      where("weeks_published > 0")
    else
    where("weeks_published = 0")
    end
  end

  def self.viewed(flag = true)
    if(flag)
      eligible.where("mean_unique_pageviews >= 1")
    else
      eligible.where("mean_unique_pageviews < 1")
    end
  end

  def self.missing
    eligible.where("mean_unique_pageviews = 0")
  end

  def self.keep(flag = true)
    if(flag)
      where("keep_published = 1")
    else
      where("keep_published = 0")
    end
  end

  def display_title(options = {})
    truncate_it = options[:truncate].nil? ? true : options[:truncate]

    if(self.title.blank?)
      display_title = '(blank)'
    elsif(truncate_it)
      display_title = self.title.truncate(80, :separator => ' ')
    else
      display_title = self.title
    end
    display_title
  end

  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end

  def self.update_from_articles
    article_database = ArticlePage.connection.current_database
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{self.connection.current_database}.#{self.table_name} (id, datatype, title, source_created_at, source_updated_at, source, source_url, article_created_at, article_updated_at,created_at,updated_at)
    SELECT id, datatype, title, source_created_at, source_updated_at, source, source_url, created_at, updated_at, NOW(), NOW()
    FROM #{article_database}.pages
    ON DUPLICATE KEY UPDATE
    datatype = #{article_database}.pages.datatype,
    title = #{article_database}.pages.title,
    source_created_at = #{article_database}.pages.source_created_at,
    source_updated_at = #{article_database}.pages.source_updated_at,
    source = #{article_database}.pages.source,
    source_url = #{article_database}.pages.source_url,
    article_created_at = #{article_database}.pages.created_at,
    article_updated_at = #{article_database}.pages.updated_at
    END_SQL
    self.connection.execute(query)
    true
  end

  def self.remove_deleted_pages
    article_database = ArticlePage.connection.current_database
    page_list = self.joins("LEFT join #{article_database}.pages on #{article_database}.pages.id = #{self.connection.current_database}.#{self.table_name}.id")
                    .where("#{article_database}.pages.id IS NULL")
                    .select("#{self.connection.current_database}.#{self.table_name}.*")
    page_list.each do |p|
      p.destroy
    end
    true
  end

  def self.tag_counts(cache_options= {})
    cache_key = self.get_cache_key(__method__)
    Rails.cache.fetch(cache_key,cache_options) do
      joins(:tags).group('tags.id').order('count_all DESC').count
    end
  end

  def self.counts_by_group_for_datatype(datatype,cache_options= {})
    cache_key = self.get_cache_key(__method__,{datatype: datatype})
    Rails.cache.fetch(cache_key,cache_options) do
      pagecounts = {}
      pagecounts['all'] = Page.by_datatype(datatype).count
      Group.launched.each do |group|
        pagecounts[group.id] = group.pages.by_datatype(datatype).count
      end
      pagecounts
    end
  end

  def weeks_published(through_date = Page::END_DATE)
    if(self.article_created_at.to_date > through_date)
      0
    else
      (through_date - self.article_created_at.to_date).to_i / 7
    end
  end

  def page_stat_attributes
    pageviews = self.year_analytics.pluck(:pageviews).sum
    unique_pageviews = self.year_analytics.pluck(:unique_pageviews).sum
    weeks_published = self.weeks_published(Page::END_DATE)
    if(weeks_published > 52)
      mean_pageviews = pageviews / 52.to_f
      mean_unique_pageviews = unique_pageviews / 52.to_f
    elsif(weeks_published > 0)
      mean_pageviews = pageviews / weeks_published.to_f
      mean_unique_pageviews = unique_pageviews / weeks_published.to_f
    else
      mean_pageviews = 0
      mean_unique_pageviews = 0
    end

    attributes = {}
    attributes[:unique_pageviews] = unique_pageviews
    attributes[:weeks_published] = weeks_published
    attributes[:mean_unique_pageviews] = mean_unique_pageviews
    attributes[:image_links] = self.links.image.count
    attributes[:hosted_image_count] = self.hosted_images.count
    attributes
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
      attributes[:viewed_image_links] = Link.image.joins(:linkedpages).where("mean_unique_pageviews >= 1").count("distinct links.id")
      attributes[:keep_image_links] = Link.image.joins(:linkedpages).where("keep_published = 1").count("distinct links.id")

      attributes[:hosted_images] = HostedImage.linked.count
      attributes[:viewed_hosted_images] = HostedImage.viewed.count

      attributes[:keep_hosted_images] = HostedImage.keep.count
      attributes[:keep_stock_images] = HostedImage.keep.stock('Yes').count
      attributes[:keep_not_stock_images] = HostedImage.keep.stock('No').count

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
    PERCENTILES.each do |percentile|
      viewed_percentiles << mups.nist_percentile(percentile)
    end
    viewed_percentiles
  end

  def update_stats
    self.update_attributes(self.page_stat_attributes)
  end

  def self.rebuild_stats
    # get stat sets
    unique_pageviews_set = Page.joins(:year_analytics).group('year_analytics.page_id').sum('year_analytics.unique_pageviews')
    image_link_set = Page.joins(:links).where('links.linktype = ?',Link::IMAGE).group('pages.id').count
    hosted_image_set = Page.joins(:hosted_images).group('pages.id').count
    self.find_in_batches(:batch_size => 100) do |page_group|
      update_statement_set = []
      page_group.each do |page|
        weeks_published = page.weeks_published
        hosted_image_count = (hosted_image_set[page.id].nil? ? 0 : hosted_image_set[page.id])
        unique_pageviews = (unique_pageviews_set[page.id].nil? ? 0 : unique_pageviews_set[page.id])
        if(weeks_published > 52)
          mean_unique_pageviews = ( unique_pageviews / 52.to_f )
        elsif(weeks_published > 0)
          mean_unique_pageviews = ( unique_pageviews / weeks_published.to_f )
        else
          mean_unique_pageviews = 0
        end
        image_links  = (image_link_set[page.id].nil? ? 0 : image_link_set[page.id])
        # custom build update statement
        query = <<-END_SQL.gsub(/\s+/, " ").strip
        UPDATE #{self.table_name}
        SET
          unique_pageviews = #{unique_pageviews},
          hosted_image_count = #{hosted_image_count},
          weeks_published = #{weeks_published},
          image_links = #{image_links},
          mean_unique_pageviews = #{mean_unique_pageviews},
          updated_at = NOW()
        WHERE id = #{page.id}
        END_SQL
        update_statement_set << query
      end
      self.transaction do
        update_statement_set.each do |statement|
          self.connection.execute(statement)
        end
      end
    end
    true
  end


end
