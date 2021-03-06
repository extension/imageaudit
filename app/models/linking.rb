# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file


# join class for content <=> links

class Linking < ActiveRecord::Base
  belongs_to :link
  belongs_to :page

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    self.connection.execute("INSERT INTO #{self.table_name} SELECT * from #{ArticleLinking.connection.current_database}.#{ArticleLinking.table_name};")
  end

end
