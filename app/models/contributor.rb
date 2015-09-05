# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Contributor < ActiveRecord::Base
  has_many :contributor_groups
  has_many :groups, through: :contributor_groups
  has_many :audit_logs

  # duplicated from darmok
  # TODO - sanity check this
  scope :patternsearch, lambda {|searchterm|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    # strip parens '()' to keep it from messing up mysql query
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').strip

    if sanitizedsearchterm == ''
      return nil
    end

    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1)
      findvalues = {
       :firstword => words[0],
       :secondword => words[1]
      }
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    elsif(sanitizedsearchterm.cast_to_i != 0)
      # special case of an id search - needed in admin/colleague searches
      conditions = ["id = #{sanitizedsearchterm.cast_to_i}"]
    else
      findvalues = {
       :findlogin => sanitizedsearchterm,
       :findemail => sanitizedsearchterm,
       :findfirst => sanitizedsearchterm,
       :findlast => sanitizedsearchterm
      }
      conditions = ["(email rlike :findemail OR idstring rlike :findlogin OR first_name rlike :findfirst OR last_name rlike :findlast)",findvalues]
    end
    {:conditions => conditions}
  }


  def self.find_by_uid(uid,provider)
    case provider
    when 'extension'
      Contributor.find_by_openid_uid(uid)
    else
      nil
    end
  end

  def login
    # do nothing
    true
  end

  def fullname
    "#{self.first_name} #{self.last_name}"
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    Person.where(:vouched => true).all.each do |p|
      insert_list = []
      insert_list << p.id
      insert_list << ActiveRecord::Base.quote_value(p.idstring)
      insert_list << ActiveRecord::Base.quote_value("https://people.extension.org/#{p.idstring}")
      insert_list << ActiveRecord::Base.quote_value(p.first_name)
      insert_list << ActiveRecord::Base.quote_value(p.last_name)
      insert_list << ActiveRecord::Base.quote_value(p.email)
      insert_list << ActiveRecord::Base.quote_value(p.title)
      insert_list << (p.account_status || 0)
      last_login = p.last_activity_at || p.created_at
      insert_list << ActiveRecord::Base.quote_value(last_login.to_s(:db))
      insert_list << (p.position_id || 0)
      insert_list << (p.location_id || 0)
      insert_list << (p.county_id || 0)
      insert_list << p.retired
      insert_list << p.is_admin
      insert_list << (p.primary_account_id || 0)
      insert_list << ActiveRecord::Base.quote_value(p.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(p.updated_at.to_s(:db))
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end

end
