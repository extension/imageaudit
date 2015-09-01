# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'net/https'

class Link < ActiveRecord::Base
  serialize :last_check_information
  include Rails.application.routes.url_helpers # so that we can generate URLs out of the model

  belongs_to :page
  has_many :linkings
  has_one :hosted_image_link, :dependent => :destroy
  has_one :hosted_image, :through => :hosted_image_link
  # this is the association for items that link to this item
  has_many :linkedpages, :through => :linkings, :source => :page
  has_many :page_stats, :through => :linkedpages

  # link types
  WANTED = 1
  INTERNAL = 2
  EXTERNAL = 3
  MAILTO = 4
  CATEGORY = 5
  DIRECTFILE = 6
  LOCAL = 7
  IMAGE = 8

  # status codes
  OK = 1
  OK_REDIRECT = 2
  WARNING = 3
  BROKEN = 4
  IGNORED = 5

  # maximum number of times a broken link reports broken before warning goes to error
  MAX_WARNING_COUNT = 3

  # maximum number of times we'll check a broken link before giving up
  MAX_ERROR_COUNT = 10

  scope :checklist, -> {where("linktype IN (#{EXTERNAL},#{LOCAL},#{IMAGE})")}
  scope :external, -> {where(:linktype => EXTERNAL)}
  scope :internal, -> {where(:linktype => INTERNAL)}
  scope :unpublished, -> {where(:linktype => WANTED)}
  scope :local, -> {where(:linktype => LOCAL)}
  scope :file, -> {where(:linktype => DIRECTFILE)}
  scope :category, -> {where(:linktype => CATEGORY)}
  scope :image, -> {where(:linktype => IMAGE)}
  scope :unlinked_images, -> { image.includes(:hosted_image).where('hosted_images.id' => nil) }

  scope :checked, -> {where("last_check_at IS NOT NULL")}
  scope :unchecked, -> {where("last_check_at IS NULL")}
  scope :good, -> {where(:status => OK)}
  scope :broken, -> {where(:status => BROKEN)}
  scope :warning, -> {where(:status => WARNING)}
  scope :redirected, -> {where(:status => OK_REDIRECT)}

  scope :checked_yesterday_or_earlier, -> {where("DATE(last_check_at) <= ?",Date.yesterday)}
  scope :checked_over_one_month_ago, -> {where("DATE(last_check_at) <= DATE_SUB(?,INTERVAL 1 MONTH)",Date.yesterday)}

  def self.image_cleanup
    list = Link.image.joins("LEFT join linkings on linkings.link_id = links.id").where("linkings.id IS NULL")
    list.each do |l|
      l.destroy
    end
    true
  end


  def self.update_list
    self.connection.execute("INSERT IGNORE INTO #{self.table_name} SELECT * from #{ArticleLink.connection.current_database}.#{ArticleLink.table_name};")
  end


  def self.is_create?(host)
    (host == 'create.extension.org' or host == 'create.demo.extension.org')
  end

  def self.is_copwiki?(host)
    (host == 'cop.extension.org' or host == 'cop.demo.extension.org')
  end

  def self.is_www?(host)
    (host == 'www.extension.org' or host == 'www.demo.extension.org')
  end

  def is_create?
    self.class.is_create?(self.host)
  end

  def is_copwiki?
    self.class.is_copwiki?(self.host)
  end

  def is_copwiki_or_create?
    self.class.is_create?(self.host) or self.class.is_copwiki?(self.host)
  end

  # note to the future humorless, the www site is currently (as of this commit)
  # the extension.org site that "has no name" (and multiple
  # attempts in the staff to attempt to give it a name) - so in an effort to
  # encapsulate something that needs to resolve to "www" - I called it
  # voldemort.  <jayoung>
  def self.is_voldemort?(host)
    self.is_create?(host) or self.is_copwiki?(host) or self.is_www?(host)
  end




  def status_to_s
    if(self.status.blank?)
      return 'Not yet checked'
    end

    case self.status
    when OK
      return 'OK'
    when OK_REDIRECT
      return 'Redirect'
    when WARNING
      return 'Warning'
    when BROKEN
      return 'Broken'
    when IGNORED
      return 'Ignored'
    else
      return 'Unknown'
    end
  end

  def href_url
    default_url_options[:host] = Settings.urlwriter_host
    default_url_options[:protocol] = Settings.urlwriter_protocol
    if(default_port = Settings.urlwriter_port)
     default_url_options[:port] = default_port
    end

    case self.linktype
    when WANTED
      return ''
    when INTERNAL
      self.page.href_url
    when EXTERNAL
      self.url
    when LOCAL
      self.url
    when MAILTO
      self.url
    when CATEGORY
      if(self.path =~ /^\/wiki\/Category\:(.+)/)
        content_tag = $1.gsub(/_/, ' ')
        category_tag_index_url(:content_tag => Tag.url_display_name(content_tag))
      elsif(self.is_create? and self.path =~ %r{^/taxonomy/term/(\d+)})
        # special case for Create taxonomy terms
        if(taxonomy_term = CreateTaxonomyTerm.find($1))
          category_tag_index_url(:content_tag => Tag.url_display_name(taxonomy_term.name))
        else
          ''
        end
      else
        ''
      end
    when DIRECTFILE
      self.path
    when IMAGE
      if(self.is_copwiki_or_create?)
        "https://www.extension.org#{self.path}"
      else
        self.url
      end
    end
  end

  def change_to_wanted
    if(self.linktype == INTERNAL)
      self.update_attribute(:linktype,WANTED)
      self.linkedpages.each do |linked_page|
        linked_page.store_content # parses links and images again and saves it.
      end
    end
  end

  def change_alternate_url
    if(self.page.alternate_source_url != self.page.source_url)
      begin
        alternate_source_uri = URI.parse(page.alternate_source_url)
        alternate_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(alternate_source_uri.to_s.downcase))
      rescue
        # do nothing
      end
    end

    if(alternate_source_uri)
      self.alternate_url = alternate_source_uri.to_s
      self.alternate_fingerprint = alternate_source_uri_fingerprint
      self.save
    end
  end

  def self.create_from_page(page)
    if(page.source_url.blank?)
      return nil
    end

    # make sure the URL is valid format
    begin
      source_uri = URI.parse(page.source_url)
      source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(source_uri.to_s.downcase))
    rescue
      return nil
    end

    # special case for where the alternate != source_url
    if(page.alternate_source_url != page.source_url)
      begin
        alternate_source_uri = URI.parse(page.alternate_source_url)
        alternate_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(alternate_source_uri.to_s.downcase))
      rescue
        # do nothing
      end
    end

    # specical case for create urls - does this have an alias_uri?
    if(page.page_source and page.page_source.name == 'create')
      if(!page.old_source_url.blank?)
        begin
          old_source_uri = URI.parse(page.old_source_url)
          old_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(old_source_uri.to_s.downcase))
        rescue
          # do nothing
        end
      elsif(migrated_url = MigratedUrl.find_by_target_url_fingerprint(source_uri_fingerprint))
        old_source_uri = migrated_url.alias_url
        old_source_uri_fingerprint = migrated_url = migrated_url.alias_url_fingerprint
      end
    end

    find_condition = "fingerprint = '#{source_uri_fingerprint}'"
    if(alternate_source_uri)
      find_condition += " OR alternate_fingerprint = '#{alternate_source_uri_fingerprint}'"
    end
    if(old_source_uri)
      find_condition += " OR alias_fingerprint = '#{old_source_uri_fingerprint}'"
    end


    if(this_link = self.where(find_condition).first)
      # this was a wanted link - we need to update the link now - and kick off the process of updating everything
      # that links to this page
      this_link.update_attributes(:page => page, :linktype => INTERNAL)
      this_link.linkedpages.each do |linked_page|
        linked_page.store_content # parses links and images again and saves it.
      end
    else
      this_link = self.new(:page => page, :url => source_uri.to_s, :fingerprint => source_uri_fingerprint)

      if(alternate_source_uri)
        this_link.alternate_url = alternate_source_uri.to_s
        this_link.alternate_fingerprint = alternate_source_uri_fingerprint
      end

      if(old_source_uri)
        this_link.alias_url = old_source_uri.to_s
        this_link.alias_fingerprint = old_source_uri_fingerprint
      end

      this_link.source_host = source_uri.host
      this_link.linktype = INTERNAL

      # set host and path - mainly just for aggregation purposes
      if(!source_uri.host.blank?)
        this_link.host = source_uri.host
      end
      if(!source_uri.path.blank?)
        this_link.path = CGI.unescape(source_uri.path)
      end
      this_link.save
    end
    return this_link

    return returnlink
  end

  def reset_status
    self.update_attributes(:status => nil, :error_count => 0, :last_check_at => nil, :last_check_status => nil, :last_check_response => nil, :last_check_code => nil, :last_check_information => nil)
  end


  def self.linktype_to_description(linktype)
    case linktype
    when WANTED
      'wanted'
    when INTERNAL
      'internal'
    when EXTERNAL
      'external'
    when MAILTO
      'mailto'
    when CATEGORY
      'category'
    when DIRECTFILE
      'directfile'
    when LOCAL
      'local'
    when IMAGE
      'image'
    else
      'unknown'
    end
  end

  def self.count_by_linktype
    returnhash = {}
    linkcounts = Link.count(:group => :linktype)
    linkcounts.each do |linktype,count|
      returnhash[self.linktype_to_description(linktype)] = count
    end
    returnhash
  end

  def connect_to_hosted_image
    if(%r{^/mediawiki/files/thumb} =~ self.path)
      matchpath = self.path.gsub(%r{^/mediawiki/files/thumb},'')
      HostedImage.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/mediawiki/files} =~ self.path)
      matchpath = self.path.gsub(%r{^/mediawiki/files},'')
      HostedImage.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/w/thumb} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/w/thumb},'')
      HostedImage.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/w} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/w},'')
      HostedImage.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/styles/\w+/public/}  =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/styles/\w+/public/},'')
      HostedImage.link_by_path(matchpath,self.id,'create')
    elsif(%r{^/sites/default/files/} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/},'')
      HostedImage.link_by_path(matchpath,self.id,'create')
    else
      # nothing for now
    end
  end

  def self.connect_unlinked_images
    self.unlinked_images.each do |image_link|
      image_link.connect_to_hosted_image
    end
    true
  end


end
