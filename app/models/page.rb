# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Page < ActiveRecord::Base
  include CacheTools
  has_many :year_analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  has_many :groups, :through => :tags
  has_one  :page_stat, dependent: :destroy
  has_many :linkings, dependent: :destroy
  has_many :links, :through => :linkings
  has_many :hosted_images, :through => :links
  has_one  :page_audit


  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2

  PERCENTILES = [99,95,90,75,50,25,10]
  DATATYPES = ['Article','Faq']

  scope :articles, where(:datatype => 'Article')
  scope :faqs, where(:datatype => 'Faq')
  scope :created_since, lambda{|date| where("#{self.table_name}.created_at >= ?",date)}
  scope :from_create, where(:source => 'create')

  def self.eligible(flag = true)
    if(flag)
      joins(:page_stat).where("page_stats.weeks_published > 0")
    else
      joins(:page_stat).where("page_stats.weeks_published = 0")
    end
  end

  def self.viewed(flag = true)
    if(flag)
      eligible.where("page_stats.mean_unique_pageviews >= 1")
    else
      eligible.where("page_stats.mean_unique_pageviews < 1")
    end
  end

  def self.missing
    eligible.where("page_stats.mean_unique_pageviews = 0")
  end

  def self.keep(flag = true)
    if(flag)
      joins(:page_audit).where("page_audits.keep_published = 1")
    else
      joins(:page_audit).where("page_audits.keep_published = 0")
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

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    ArticlePage.find_in_batches do |group|
      insert_values = []
      group.each do |page|
        insert_list = []
        insert_list << page.id
        insert_list << (page.migrated_id.blank? ? 0 : page.migrated_id)
        insert_list << ActiveRecord::Base.quote_value(page.datatype)
        insert_list << ActiveRecord::Base.quote_value(page.title)
        insert_list << ActiveRecord::Base.quote_value(page.url_title)
        insert_list << (page.content_length.blank? ? 0 : page.content_length)
        insert_list << (page.content_words.blank? ? 0 : page.content_words)
        insert_list << ActiveRecord::Base.quote_value(page.source_created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source_updated_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source)
        insert_list << ActiveRecord::Base.quote_value(page.source_url)
        insert_list << page.indexed
        insert_list << (page.is_dpl? ? 1 : 0)
        if(page.source == 'create' and page.source_url =~ %r{/node/(\d+)})
          insert_list << $1.to_i
        else
          insert_list << 0
        end
        insert_list << ActiveRecord::Base.quote_value(page.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
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

  def weeks_published(through_date = PageStat::END_DATE)
    if(self.created_at.to_date > through_date)
      0
    else
      (through_date - self.created_at.to_date).to_i / 7
    end
  end

  def page_stat_attributes
    pageviews = self.year_analytics.pluck(:pageviews).sum
    unique_pageviews = self.year_analytics.pluck(:unique_pageviews).sum
    weeks_published = self.weeks_published(PageStat::END_DATE)
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
    attributes[:hosted_images] = self.hosted_images.count
    attributes
  end

  def self.make_audits
    without_audit = Page.joins("LEFT JOIN page_audits on page_audits.page_id = pages.id").where("page_audits.id IS NULL")
    without_audit.each do |page|
      page.create_page_audit(keep_published: 1, keep_published_by: 1)
    end
    true
  end



end
