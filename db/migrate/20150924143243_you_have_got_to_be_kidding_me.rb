class YouHaveGotToBeKiddingMe < ActiveRecord::Migration
  def up
    remove_index "hosted_image_links", :name => "link_index"
    change_column("hosted_image_links","hosted_image_id",:integer)
    add_index "hosted_image_links", ["link_id", "hosted_image_id"], :name => "link_index", :unique => true
  end

end
