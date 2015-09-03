# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150903142335) do

  create_table "audit_logs", :force => true do |t|
    t.string   "auditable_type",       :null => false
    t.integer  "auditable_id",         :null => false
    t.integer  "contributor_id",       :null => false
    t.string   "changed_item",         :null => false
    t.boolean  "previous_check_value"
    t.boolean  "current_check_value"
    t.text     "previous_notes"
    t.text     "current_notes"
    t.datetime "created_at"
  end

  add_index "audit_logs", ["auditable_type", "auditable_id", "contributor_id"], :name => "audit_ndx"

  create_table "community_page_stats", :force => true do |t|
    t.integer  "group_id"
    t.integer  "total_pages"
    t.integer  "eligible_pages"
    t.integer  "viewed_pages"
    t.text     "viewed_percentiles"
    t.integer  "image_links"
    t.integer  "viewed_image_links"
    t.integer  "hosted_images"
    t.integer  "viewed_hosted_images"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "keep_pages"
    t.integer  "keep_image_links"
    t.integer  "keep_hosted_images"
    t.integer  "keep_stock_images"
    t.integer  "keep_not_stock_images"
  end

  add_index "community_page_stats", ["group_id"], :name => "community_ndx", :unique => true

  create_table "contributor_groups", :force => true do |t|
    t.integer  "contributor_id"
    t.integer  "group_id"
    t.datetime "created_at"
  end

  add_index "contributor_groups", ["group_id", "contributor_id"], :name => "connection_ndx", :unique => true

  create_table "contributors", :force => true do |t|
    t.string   "idstring",           :limit => 80,                    :null => false
    t.string   "openid_uid"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",              :limit => 96
    t.string   "title"
    t.integer  "account_status"
    t.datetime "last_login_at"
    t.integer  "position_id"
    t.integer  "location_id"
    t.integer  "county_id"
    t.boolean  "retired",                          :default => false
    t.boolean  "is_admin",                         :default => false
    t.integer  "primary_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributors", ["openid_uid"], :name => "openid_ndx"

  create_table "groups", :force => true do |t|
    t.integer  "create_gid"
    t.string   "name"
    t.boolean  "is_launched"
    t.boolean  "publishing_community", :default => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "groups", ["create_gid"], :name => "create_group_ndx"

  create_table "hosted_image_audits", :force => true do |t|
    t.integer  "hosted_image_id",       :null => false
    t.boolean  "is_stock"
    t.integer  "is_stock_by"
    t.boolean  "community_reviewed"
    t.integer  "community_reviewed_by"
    t.boolean  "staff_reviewed"
    t.integer  "staff_reviewed_by"
    t.text     "notes"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "hosted_image_audits", ["hosted_image_id"], :name => "image_ndx", :unique => true

  create_table "hosted_image_links", :force => true do |t|
    t.integer "link_id",         :null => false
    t.string  "hosted_image_id", :null => false
  end

  add_index "hosted_image_links", ["link_id", "hosted_image_id"], :name => "link_index", :unique => true

  create_table "hosted_images", :force => true do |t|
    t.string   "filename"
    t.text     "path"
    t.integer  "source_id"
    t.string   "source"
    t.text     "description"
    t.text     "copyright"
    t.boolean  "original_wiki"
    t.string   "original_filename"
    t.text     "original_path"
    t.integer  "original_source_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "hosted_images", ["source_id", "source"], :name => "source_id_index", :unique => true

  create_table "linkings", :force => true do |t|
    t.integer  "link_id"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "linkings", ["link_id", "page_id"], :name => "recordsignature", :unique => true

  create_table "links", :force => true do |t|
    t.integer  "linktype"
    t.integer  "page_id"
    t.string   "host"
    t.string   "source_host"
    t.text     "path"
    t.string   "fingerprint"
    t.text     "url"
    t.string   "alias_fingerprint"
    t.text     "alias_url"
    t.string   "alternate_fingerprint"
    t.text     "alternate_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.integer  "error_count",            :default => 0
    t.datetime "last_check_at"
    t.integer  "last_check_status"
    t.boolean  "last_check_response"
    t.string   "last_check_code"
    t.text     "last_check_information"
  end

  add_index "links", ["alias_fingerprint"], :name => "alias_fingerprint_ndx"
  add_index "links", ["alternate_fingerprint"], :name => "alternate_fingerprint_ndx"
  add_index "links", ["fingerprint"], :name => "index_content_links_on_original_fingerprint", :unique => true
  add_index "links", ["page_id", "status", "linktype"], :name => "coreindex"

  create_table "page_audits", :force => true do |t|
    t.integer  "page_id",                                 :null => false
    t.boolean  "keep_published",        :default => true, :null => false
    t.integer  "keep_published_by"
    t.boolean  "community_reviewed"
    t.integer  "community_reviewed_by"
    t.boolean  "staff_reviewed"
    t.integer  "staff_reviewed_by"
    t.text     "notes"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "page_audits", ["page_id"], :name => "page_ndx", :unique => true

  create_table "page_stats", :force => true do |t|
    t.integer  "page_id"
    t.integer  "unique_pageviews"
    t.integer  "weeks_published"
    t.float    "mean_unique_pageviews"
    t.integer  "image_links"
    t.integer  "hosted_images"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "page_stats", ["page_id"], :name => "index_page_stats_on_page_id", :unique => true

  create_table "page_taggings", :force => true do |t|
    t.integer  "page_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_taggings", ["page_id", "tag_id"], :name => "pt_ndx"

  create_table "pages", :force => true do |t|
    t.integer  "migrated_id"
    t.string   "datatype"
    t.text     "title"
    t.string   "url_title",         :limit => 101
    t.integer  "content_length"
    t.integer  "content_words"
    t.datetime "source_created_at"
    t.datetime "source_updated_at"
    t.string   "source"
    t.text     "source_url"
    t.integer  "indexed",                          :default => 1
    t.boolean  "is_dpl",                           :default => false
    t.integer  "node_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["created_at", "datatype", "indexed"], :name => "page_type_ndx"
  add_index "pages", ["datatype"], :name => "index_pages_on_datatype"
  add_index "pages", ["migrated_id"], :name => "index_pages_on_migrated_id"
  add_index "pages", ["node_id"], :name => "node_ndx"
  add_index "pages", ["title"], :name => "index_pages_on_title", :length => {"title"=>255}

  create_table "rebuilds", :force => true do |t|
    t.string   "group"
    t.string   "single_model"
    t.string   "single_action"
    t.boolean  "in_progress"
    t.datetime "started"
    t.datetime "finished"
    t.float    "run_time"
    t.string   "current_model"
    t.string   "current_action"
    t.datetime "current_start"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rebuilds", ["created_at"], :name => "created_ndx"

  create_table "tags", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "group_id"
    t.datetime "created_at"
  end

  add_index "tags", ["group_id"], :name => "group_ndx"
  add_index "tags", ["name"], :name => "name_idx", :unique => true

  create_table "update_times", :force => true do |t|
    t.integer  "rebuild_id"
    t.string   "item"
    t.string   "operation"
    t.float    "run_time"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "update_times", ["item"], :name => "item_ndx"

  create_table "year_analytics", :force => true do |t|
    t.integer  "page_id"
    t.text     "analytics_url"
    t.string   "url_type"
    t.integer  "url_page_id"
    t.string   "url_wiki_title"
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "year_analytics", ["page_id"], :name => "page_ndx"

end
