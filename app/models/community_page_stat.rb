# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding from the eXtension Foundation
# === LICENSE:
#
#  see LICENSE file

class CommunityPageStat < ActiveRecord::Base
  serialize :viewed_percentiles
  belongs_to :group

  # hardcoded right now
  START_DATE = Date.parse('2014-08-24')
  END_DATE = Date.parse('2015-08-22')

  def update_stats
    pc = self.group
    self.update_attributes(pc.page_stat_attributes)
  end

  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    PageStat.overall_stat_attributes # rebuild all stats

    # get stat sets
    pages_set = Group.publishing.joins(:pages).group('groups.id').count
    eligible_pages_set = Group.publishing.joins(:page_stats).where("weeks_published >= ?",1).group("groups.id").count
    viewed_pages_set = Group.publishing.joins(:page_stats).where("mean_unique_pageviews >= ?",1).group("groups.id").count
    image_link_set = Group.publishing.joins(:links).where('links.linktype = ?',Link::IMAGE).group('groups.id').count('distinct links.id')
    viewed_image_link_set = Group.publishing.joins(:viewed_links).where("mean_unique_pageviews >= ?",1).where('links.linktype = ?',Link::IMAGE).group('groups.id').count('distinct links.id')
    hosted_image_set = Group.publishing.joins(:hosted_images).group('groups.id').count('distinct hosted_images.id')
    viewed_hosted_image_set = Group.publishing.joins(:viewed_images).where("mean_unique_pageviews >= ?",1).group('groups.id').count('distinct hosted_images.id')
    keep_pages_set = Group.publishing.joins(:page_audits).where("page_audits.keep_published = 1").group("groups.id").count
    keep_image_link_set = Group.publishing.joins(:keep_links).where("page_audits.keep_published = 1").where('links.linktype = ?',Link::IMAGE).group('groups.id').count('distinct links.id')
    keep_hosted_image_set = Group.publishing.joins(:keep_images).where("page_audits.keep_published = 1").group('groups.id').count('distinct hosted_images.id')
    keep_stock_image_set = Group.publishing.joins(:keep_images => :hosted_image_audit)
                                               .where("page_audits.keep_published = 1")
                                               .where("hosted_image_audits.is_stock = 1")
                                               .group('groups.id').count('distinct hosted_images.id')

    keep_not_stock_image_set = Group.publishing.joins(:keep_images => :hosted_image_audit)
                                               .where("page_audits.keep_published = 1")
                                               .where("hosted_image_audits.is_stock = 0")
                                               .group('groups.id').count('distinct hosted_images.id')



    insert_columns = ['group_id','total_pages','eligible_pages','viewed_pages','viewed_percentiles',
                      'image_links','viewed_image_links','hosted_images','viewed_hosted_images',
                      'created_at','updated_at',
                      'keep_pages','keep_image_links','keep_hosted_images','keep_stock_images','keep_not_stock_images']
    insert_values = []
    Group.publishing.all.each do |group|
      insert_list = []
      insert_list << group.id
      insert_list << (pages_set[group.id].nil? ? 0 : pages_set[group.id])
      insert_list << (eligible_pages_set[group.id].nil? ? 0 : eligible_pages_set[group.id])
      insert_list << (viewed_pages_set[group.id].nil? ? 0 : viewed_pages_set[group.id])
      insert_list << ActiveRecord::Base.quote_value(group.mup_percentiles.to_yaml)
      insert_list << (image_link_set[group.id].nil? ? 0 : image_link_set[group.id])
      insert_list << (viewed_image_link_set[group.id].nil? ? 0 : viewed_image_link_set[group.id])
      insert_list << (hosted_image_set[group.id].nil? ? 0 : hosted_image_set[group.id])
      insert_list << (viewed_hosted_image_set[group.id].nil? ? 0 : viewed_hosted_image_set[group.id])
      insert_list << 'NOW()'
      insert_list << 'NOW()'
      insert_list << (keep_pages_set[group.id].nil? ? 0 : keep_pages_set[group.id])
      insert_list << (keep_image_link_set[group.id].nil? ? 0 : keep_image_link_set[group.id])
      insert_list << (keep_hosted_image_set[group.id].nil? ? 0 : keep_hosted_image_set[group.id])
      insert_list << (keep_stock_image_set[group.id].nil? ? 0 : keep_stock_image_set[group.id])
      insert_list << (keep_not_stock_image_set[group.id].nil? ? 0 : keep_not_stock_image_set[group.id])
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} (#{insert_columns.join(', ')}) VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
    true
  end

end
