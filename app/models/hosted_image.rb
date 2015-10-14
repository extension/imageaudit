# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class HostedImage < ActiveRecord::Base
  has_many :hosted_image_links
  has_many :links, :through => :hosted_image_links
  has_many :linkings, :through => :links
  has_many :page_hosted_images
  has_many :pages, :through => :page_hosted_images
  has_many :group_images
  has_many :groups, :through => :group_images

  belongs_to :is_stock_reviewer,  :class_name => "Contributor", :foreign_key => "is_stock_by"
  belongs_to :community_reviewer,  :class_name => "Contributor", :foreign_key => "community_reviewed_by"
  belongs_to :staff_reviewer,      :class_name => "Contributor", :foreign_key => "staff_reviewed_by"
  has_many :audit_logs, :as => :auditable


  scope :from_copwiki, -> {where(source: 'copwiki')}
  scope :from_create, -> {where(source: 'create')}
  scope :with_copyright, -> {where("copyright IS NOT NULL")}
  scope :without_copyright, -> {where("copyright IS NULL or LENGTH(copyright) = 0")}

  has_many :audit_logs, :as => :auditable

  def create_file
    CreateFile.where(fid: self.source_id).first
  end

  def filemime
    MimeMagic.by_magic(File.open(self.filesys_path))
  end

  def filesize
    File.size(self.filesys_path)
  end

  def filetype
    case self.filemime.mediatype
    when 'application'
      'document'
    when 'image'
      self.filemime.mediatype
    when 'video'
      self.filemime.mediatype
    when 'audio'
      self.filemime.mediatype
    else
      'undefined'
    end
  end


  def self.linked
    joins(:hosted_image_links).uniq
  end

  # viewed
  def self.viewed(viewed = true)
    if(viewed)
      joins(:pages).where("pages.mean_unique_pageviews >= 1").uniq
    else
      joins(:pages).where("pages.mean_unique_pageviews < 1").uniq
    end
  end

  def self.keep(keep = true)
    joins(:pages).where("pages.keep_published = ?",keep).uniq
  end

  def self.search_copyright_terms(searchstring)
    terms = searchstring.split(',').map{|t| t.strip}.compact
    whereclause = terms.map{|t| "copyright RLIKE '[[:<:]]#{t}[[:>:]]'"}.join(' OR ')
    where("#{whereclause}")
  end

  def self.stock(stock = 'All')
    case stock.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      where('is_stock IN (1,0)')
    when 'Unreviewed'
      reviewed = self.stock('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Yes'
      where('is_stock = 1')
    when 'No'
      where('is_stock = 0')
    else
      where('true')
    end
  end

  def self.community_reviewed(community_reviewed = 'All')
    case community_reviewed.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      where('hosted_images.community_reviewed IN (1,0)')
    when 'Unreviewed'
      reviewed = self.community_reviewed('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Complete'
      where('hosted_images.community_reviewed = 1')
    when 'Incomplete'
      where('hosted_images.community_reviewed = 0')
    else
      where('true')
    end
  end

  def self.staff_reviewed(staff_reviewed = 'All')
    case staff_reviewed.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      where('hosted_images.staff_reviewed IN (1,0)')
    when 'Unreviewed'
      reviewed = self.staff_reviewed('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Complete'
      where('hosted_images.staff_reviewed = 1')
    when 'Incomplete'
      where('hosted_images.staff_reviewed = 0')
    else
      where('true')
    end
  end


  # keepers





  def filesys_path
    if(self.source == 'copwiki')
      "#{Settings.drupal_file_source_path}/w#{self.path}"
    else
      ''
    end
  end

  def create_uri
    if(source == 'create')
      self.path
    elsif(source == 'copwiki')
      "public://w#{self.path}"
    end
  end

  def src_path
    if(self.source == 'copwiki')
      URI.escape("http://create.extension.org/sites/default/files/w#{self.path}")
    elsif(self.source == 'create')
      if(%r{^public:} =~ self.path)
        URI.escape(self.path.gsub('public://','http://create.extension.org/sites/default/files/'))
      else
        ''
      end
    else
      ''
    end
  end



  def self.update_from_create
    # DOES NOT UPDATE COPYRIGHT - that is in a separate procedure
    create_database = CreateFile.connection.current_database
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{self.connection.current_database}.#{self.table_name} (source_id, source, filename, path, description, copyright, created_at, updated_at)
    SELECT fid, 'create', filename, uri, field_media_description_value, field_copyright_value, NOW(), NOW()
    FROM (
      SELECT fid, filename, uri, field_media_description_value, field_copyright_value
      FROM (
            #{create_database}.file_managed
            LEFT JOIN #{create_database}.field_data_field_media_description
            ON #{create_database}.field_data_field_media_description.entity_type = 'file'
            AND #{create_database}.field_data_field_media_description.entity_id = #{create_database}.file_managed.fid
          )
          LEFT JOIN #{create_database}.field_data_field_copyright
          ON #{create_database}.field_data_field_copyright.entity_type = 'file'
          AND #{create_database}.field_data_field_copyright.entity_id = #{create_database}.file_managed.fid
          WHERE #{create_database}.file_managed.type = 'image'
    ) AS create_image_data
    ON DUPLICATE KEY UPDATE
    filename = create_image_data.filename,
    path = create_image_data.uri,
    description = create_image_data.field_media_description_value,
    updated_at = NOW()
    END_SQL

    CreateFile.connection.execute(query)
  end

  def self.update_copyrights
    create_file_copyrights = {}
    CreateFile.joins(:copyright).select(['fid','field_data_field_copyright.field_copyright_value as copyright_text']).map{|cf| create_file_copyrights[cf.fid] = cf.copyright_text}
    HostedImage.where(source: 'create').all.each do |hi|
      if(create_copyright = create_file_copyrights[hi.source_id])
        if hi.copyright != create_copyright
          previous_copyright = hi.copyright
          hi.update_attribute(:copyright, create_copyright)
          # log copyright change
          AuditLog.create(contributor_id: 1,
                          auditable: hi,
                          changed_item: 'copyright',
                          previous_notes: previous_copyright,
                          current_notes: create_copyright)

          if(!hi.community_reviewed.nil?)
            hi.update_attributes({:community_reviewed => nil, :community_reviewed_by => nil})
            AuditLog.create(contributor_id: 1,
                            auditable: hi,
                            changed_item: 'community_reviewed',
                            previous_check_value: hi.community_reviewed?,
                            current_check_value: nil)
          end

          if(!hi.staff_reviewed.nil?)
            hi.update_attributes({:staff_reviewed => nil, :staff_reviewed_by => nil})
            AuditLog.create(contributor_id: 1,
                            auditable: hi,
                            changed_item: 'staff_reviewed',
                            previous_check_value: hi.staff_reviewed?,
                            current_check_value: nil)
          end
        end
      end
    end
    true
  end


  def self.link_by_path(matchpath,link_id,source)
    case source
      when 'copwiki'
        # somehow there are /a/aa/filename/some_other_file_name paths
        matchpath_breakdown = matchpath.split('/')
        searchpath = "/#{matchpath_breakdown[1]}/#{matchpath_breakdown[2]}/#{matchpath_breakdown[3]}"
        id = self.where(original_path: searchpath).where(original_wiki: true).first
        if(id.nil?)
          id = self.where(path: searchpath).where(source: 'copwiki').first
        end
        if(id)
          begin
            id.hosted_image_links.create(link_id: link_id)
          rescue ActiveRecord::RecordNotUnique
            # already linked
          end
        end
      when 'create'
        if(id = self.where(path: "public://#{matchpath}").where(source: 'create').first)
          begin
            id.hosted_image_links.create(link_id: link_id)
          rescue ActiveRecord::RecordNotUnique
            # already linked
          end
        end
      else
        # nothing for now
    end
  end

  def self.bio_images
    self.joins(:pages => :tags).where("tags.name = 'bio'")
  end

  # temporary method to facilitate copyright updates
  def self.update_bio_copyrights
    total_count = self.bio_images.count
    changed_count = 0
    self.bio_images.without_copyright.readonly(false).each do |hi|
      if(create_file = hi.create_file)
        changed_count += 1
        previous_staff_review_status = hi.staff_reviewed
        hi.update_attributes(copyright: 'Photo provided for eXtension bio page', staff_reviewed: true, staff_reviewed_by: 1)
        create_file.create_copyright_update_query(hi.copyright)
        AuditLog.create(contributor_id: Contributor::SYSTEM_ACCOUNT,
                        auditable: hi,
                        changed_item: 'staff_reviewed',
                        previous_check_value: previous_staff_review_status,
                        current_check_value: hi.staff_reviewed)
        # log
        AuditLog.create(contributor_id: Contributor::SYSTEM_ACCOUNT,
                        auditable: hi,
                        changed_item: 'copyright',
                        previous_notes: nil,
                        current_notes: hi.copyright)
      end
    end
    {total_count: total_count, changed_count: changed_count}
  end


end
