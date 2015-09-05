# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file
require 'fileutils'

class CreateFile < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name = 'file_managed'
  self.primary_key = "fid"
  self.inheritance_column = "inheritance_type"

  has_one :copyright, :class_name => 'CreateFileCopyright', :foreign_key => :entity_id


  def self.create_from_hosted_copwiki_image(hosted_image)
    return nil if (hosted_image.source != 'copwiki')

    # validate that the original file exists
    current_filsys_path = hosted_image.filesys_path
    return nil if !File.exists?(current_filsys_path)

    # new target file
    target_filename = "copwiki_#{hosted_image.filename}"
    file_move_target = "#{Settings.drupal_file_source_path}/#{target_filename}"
    return nil if File.exists?(file_move_target)

    # move the file, symlink the old file
    file_move_target = "#{Settings.drupal_file_source_path}/#{target_filename}"
    file_move_source = "#{Settings.drupal_file_source_path}/w#{hosted_image.path}"


    new_create_uri = "public://#{target_filename}"

    attributes = {uid: 1,
                  status: 1,
                  filesize: hosted_image.filesize,
                  filemime: hosted_image.filemime.type,
                  filename: hosted_image.filename,
                  type: hosted_image.filetype,
                  uri: new_create_uri}
    begin
      cf = self.create(attributes.merge({timestamp: Time.now.utc.to_i}))
    rescue ActiveRecord::RecordNotUnique
      return nil
    end



    if(!cf.nil? and cf.valid?)
      FileUtils.move(file_move_source,file_move_target)
      FileUtils.ln_s(file_move_target,file_move_source)

      ['data','revision'].each do |data_or_revision|
        self.connection.execute(create_copyright_update_query(hosted_image,cf.id,data_or_revision))
        self.connection.execute(create_description_update_query(hosted_image,cf.id,data_or_revision))
      end

      hosted_image.update_attributes({filename: target_filename,
                                      path: new_create_uri,
                                      source_id: cf.fid,
                                      source: 'create'})
      # not going to log after all
      # AuditLog.create(contributor_id: 1,
      #                 auditable: hosted_image,
      #                 changed_item: 'source',
      #                 previous_notes: 'copwiki',
      #                 current_notes: 'create')
    end
    true
  end

  def self.create_copyright_update_query(hosted_image,fid,data_or_revision)
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{CreateFile.connection.current_database}.field_#{data_or_revision}_field_copyright (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_copyright_value, field_copyright_format)
    SELECT 'file',
           #{ActiveRecord::Base.quote_value("#{hosted_image.filetype}")},
           0,
           #{fid},
           #{fid},
           'und',
           0,
           #{ActiveRecord::Base.quote_value(hosted_image.copyright)},
           'NULL'
    ON DUPLICATE KEY
    UPDATE field_copyright_value=#{ActiveRecord::Base.quote_value(hosted_image.copyright)}
    END_SQL
    query
  end

  def self.create_description_update_query(hosted_image,fid,data_or_revision)
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{CreateFile.connection.current_database}.field_#{data_or_revision}_field_media_description (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_media_description_value, field_media_description_format)
    SELECT 'file',
           #{ActiveRecord::Base.quote_value("#{hosted_image.filetype}")},
           0,
           #{fid},
           #{fid},
           'und',
           0,
           #{ActiveRecord::Base.quote_value(hosted_image.description)},
           'NULL'
    ON DUPLICATE KEY
    UPDATE field_media_description_value=#{ActiveRecord::Base.quote_value(hosted_image.description)}
    END_SQL
    query
  end


end
