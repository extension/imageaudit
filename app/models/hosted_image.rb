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
  has_many :pages, :through => :linkings
  has_many :page_stats, :through => :pages
  has_many :page_audits, :through => :pages
  has_one  :hosted_image_audit

  scope :from_copwiki, -> {where(source: 'copwiki')}
  scope :from_create, -> {where(source: 'create')}
  scope :with_copyright, -> {where("copyright IS NOT NULL")}

  has_many :audit_logs, :as => :auditable

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
      joins(:page_stats).where("page_stats.mean_unique_pageviews >= 1").uniq
    else
      joins(:page_stats).where("page_stats.mean_unique_pageviews < 1").uniq
    end
  end

  def self.keep(keep = true)
    joins(:page_audits).where("page_audits.keep_published = ?",keep).uniq
  end

  def self.stock(stock = 'All')
    case stock.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      joins(:hosted_image_audit).where('hosted_image_audits.is_stock IN (1,0)')
    when 'Unreviewed'
      reviewed = self.stock('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Yes'
      joins(:hosted_image_audit).where('hosted_image_audits.is_stock = 1')
    when 'No'
      joins(:hosted_image_audit).where('hosted_image_audits.is_stock = 0')
    else
      where('true')
    end
  end

  def self.community_reviewed(community_reviewed = 'All')
    case community_reviewed.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      joins(:hosted_image_audit).where('hosted_image_audits.community_reviewed IN (1,0)')
    when 'Unreviewed'
      reviewed = self.community_reviewed('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Yes'
      joins(:hosted_image_audit).where('hosted_image_audits.community_reviewed = 1')
    when 'No'
      joins(:hosted_image_audit).where('hosted_image_audits.community_reviewed = 0')
    else
      where('true')
    end
  end

  def self.staff_reviewed(staff_reviewed = 'All')
    case staff_reviewed.capitalize
    when 'All'
      where('true')
    when 'Reviewed'
      joins(:hosted_image_audit).where('hosted_image_audits.staff_reviewed IN (1,0)')
    when 'Unreviewed'
      reviewed = self.staff_reviewed('Reviewed').pluck('hosted_images.id')
      if(!reviewed.blank?)
        where('hosted_images.id NOT IN (?)',reviewed)
      else
        where('true')
      end
    when 'Yes'
      joins(:hosted_image_audit).where('hosted_image_audits.staff_reviewed = 1')
    when 'No'
      joins(:hosted_image_audit).where('hosted_image_audits.staff_reviewed = 0')
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
          # clear validation if exists
          if(!image_audit = hi.hosted_image_audit)
            image_audit = hi.create_hosted_image_audit
          else
            # log copyright change
            AuditLog.create(contributor_id: 1,
                            auditable: hi,
                            changed_item: 'copyright',
                            previous_notes: previous_copyright,
                            current_notes: create_copyright)

            if(!image_audit.community_reviewed.nil?)
              image_audit.update_attributes({:community_reviewed => nil, :community_reviewed_by => nil})
              AuditLog.create(contributor_id: 1,
                              auditable: image_audit,
                              changed_item: 'community_reviewed',
                              previous_check_value: image_audit.community_reviewed?,
                              current_check_value: nil)
            end

            if(!image_audit.staff_reviewed.nil?)
              image_audit.update_attributes({:staff_reviewed => nil, :staff_reviewed_by => nil})
              AuditLog.create(contributor_id: 1,
                              auditable: image_audit,
                              changed_item: 'staff_reviewed',
                              previous_check_value: image_audit.staff_reviewed?,
                              current_check_value: nil)
            end
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


end
