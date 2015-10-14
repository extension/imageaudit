# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Tag < ActiveRecord::Base
  has_many :analytics
  has_many :page_taggings
  has_many :pages, :through => :page_taggings
  has_many :analytics, :through => :pages
  belongs_to :group

  scope :grouptags, where("group_id > 0")

  SPLITTER = Regexp.new(/\s*,\s*/)
  JOINER = ", "

  # normalize tag names
  # convert whitespace to single space, underscores to space, Yank everything that's not alphanumeric except colon, hyphen, or whitespace (which is now single spaces)
  def self.normalizename(name)
    # make an initial downcased copy - don't want to modify name as a side effect
    returnstring = name.downcase
    # now, use the replacement versions of gsub and strip on returnstring
    # convert underscores to spaces
    returnstring.gsub!('_',' ')
    # get rid of anything that's not a "word", not space, not : and not -
    returnstring.gsub!(/[^\w :-]/,'')
    # reduce multiple spaces to a single space
    returnstring.gsub!(/ +/,' ')
    # remove leading and trailing whitespace
    returnstring.strip!
    returnstring
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    ArticleTag.find_in_batches do |group|
      insert_values = []
      group.each do |tag|
        insert_list = []
        insert_list << tag.id
        insert_list << ActiveRecord::Base.quote_value(tag.name)
        insert_list << ActiveRecord::Base.quote_value(tag.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (id,name,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # set groups
    ArticleTag.community_resource_tags.each do |community_tag|
      if(tag_group = community_tag.article_communities.first)
        group_id = tag_group.id
        update_sql = "UPDATE #{self.table_name} SET group_id = #{group_id} WHERE #{self.table_name}.id = #{community_tag.id}"
        self.connection.execute(update_sql)
      end
    end
    true
  end

  def self.pagetags_for_group(group)
    idlist = group.pages.pluck('pages.id')
    self.where('group_id IS NULL').joins(:page_taggings).where("page_taggings.page_id IN (#{idlist.join(',')})")
  end


  def self.castlist_to_array(obj,normalizestring=true,processnots=false)
    returnarray = []
    if(processnots)
      returnnotarray = []
    end

    case obj
      when Array
        obj.each do |item|
          case item
            when /^\d+$/, Fixnum then returnarray << Tag.find(item).name # This will be slow if you use ids a lot.
            when Tag then returnarray << item.name
            when String
              if(processnots and item.starts_with?('!'))
                returnnotarray << (normalizestring ? Tag.normalizename(item) : item.strip)
              else
                returnarray << (normalizestring ? Tag.normalizename(item) : item.strip)
              end
            else
              raise "Invalid type"
          end
        end
      when String
        obj.split(Tag::SPLITTER).each do |tag_name|
          if(!tag_name.empty?)
            if(processnots and tag_name.starts_with?('!'))
              returnnotarray << (normalizestring ? Tag.normalizename(tag_name) : tag_name.strip)
            else
              returnarray << (normalizestring ? Tag.normalizename(tag_name) : tag_name.strip)
            end
          end
        end
      else
        raise "Invalid object of class #{obj.class} as tagging method parameter"
    end

    returnarray.flatten!
    returnarray.compact!
    returnarray.uniq!


    if(processnots)
      returnnotarray.flatten!
      returnnotarray.compact!
      returnnotarray.uniq!
      return [returnarray,returnnotarray]
    else
      return returnarray
    end
  end

end
