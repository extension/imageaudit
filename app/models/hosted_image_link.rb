# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class HostedImageLink < ActiveRecord::Base
  belongs_to :link
  belongs_to :hosted_image


  def self.update_list
    Link.connect_unlinked_images
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    Link.connect_unlinked_images
  end

end
