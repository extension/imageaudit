class PageHostedImages < ActiveRecord::Migration
  def up
    create_table "page_hosted_images", :force => true do |t|
      t.integer  "page_id",         :null => false
      t.integer  "hosted_image_id", :null => false
    end
    add_index "page_hosted_images", ["page_id", "hosted_image_id"], :name => "image_page_ndx", :unique => true


    create_table "group_pages", :force => true do |t|
      t.integer  "page_id",         :null => false
      t.integer  "group_id", :null => false
    end
    add_index "group_pages", ["page_id", "group_id"], :name => "group_page_ndx", :unique => true

    create_table "group_images", :force => true do |t|
      t.integer  "hosted_image_id",         :null => false
      t.integer  "group_id", :null => false
    end
    add_index "group_images", ["hosted_image_id", "group_id"], :name => "group_image_ndx", :unique => true

  end

  def down
  end
end
