class AuditChanges < ActiveRecord::Migration
  def up
    # rebuild them
    drop_table(:hosted_image_audits)
    drop_table(:audit_logs)
    drop_table(:page_audits)


    create_table "hosted_image_audits", :force => true do |t|
      t.integer   "hosted_image_id",:null => false
      t.boolean   "is_stock", :null => true
      t.integer   "is_stock_by", :null => true
      t.boolean   "community_reviewed", :null => true
      t.integer   "community_reviewed_by", :null => true
      t.boolean   "staff_reviewed", :null => true
      t.integer   "staff_reviewed_by", :null => true
      t.text      "notes",:null => true
      t.timestamps
    end
    add_index "hosted_image_audits", ["hosted_image_id"], :name => "image_ndx", :unique => true

    create_table "page_audits", :force => true do |t|
      t.integer   "page_id",:null => false
      t.boolean   "keep_published", :null => false, :default => true
      t.integer   "keep_published_by", :null => true
      t.boolean   "community_reviewed", :null => true
      t.integer   "community_reviewed_by", :null => true
      t.boolean   "staff_reviewed", :null => true
      t.integer   "staff_reviewed_by", :null => true
      t.text      "notes",:null => true
      t.timestamps
    end
    add_index "page_audits", ["page_id"], :name => "page_ndx", :unique => true

    create_table "audit_logs", :force => true do |t|
      t.string  "auditable_type",:null => false
      t.integer "auditable_id",:null => false
      t.integer "contributor_id",:null => false
      t.string  "changed_item",:null => false
      t.boolean  "previous_check_value",:null => true
      t.boolean  "current_check_value",:null => true
      t.text     "previous_notes",:null => true
      t.text     "current_notes",:null => true
      t.datetime "created_at"
    end

    add_index "audit_logs", ["auditable_type","auditable_id","contributor_id"], :name => "audit_ndx"

  end

end
