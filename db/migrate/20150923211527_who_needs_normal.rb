class WhoNeedsNormal < ActiveRecord::Migration
  def up

    add_column(:hosted_images, "is_stock", :boolean)
    add_column(:hosted_images, "is_stock_by", :integer)
    add_column(:hosted_images, "community_reviewed", :boolean)
    add_column(:hosted_images, "community_reviewed_by", :integer)
    add_column(:hosted_images, "staff_reviewed", :boolean)
    add_column(:hosted_images, "staff_reviewed_by", :integer)
    add_column(:hosted_images, "notes", :text)

    hosted_image_query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE hosted_images, hosted_image_audits
    SET
    hosted_images.is_stock = hosted_image_audits.is_stock,
    hosted_images.is_stock_by = hosted_image_audits.is_stock_by,
    hosted_images.community_reviewed = hosted_image_audits.community_reviewed,
    hosted_images.community_reviewed_by = hosted_image_audits.community_reviewed_by,
    hosted_images.staff_reviewed = hosted_image_audits.staff_reviewed,
    hosted_images.staff_reviewed_by = hosted_image_audits.staff_reviewed_by,
    hosted_images.notes = hosted_image_audits.notes
    WHERE hosted_image_audits.hosted_image_id = hosted_images.id
    END_SQL

    execute "#{hosted_image_query}"

    add_column(:pages, "article_created_at", :datetime)
    add_column(:pages, "article_updated_at", :datetime)

    add_column(:pages, "keep_published", :boolean)
    add_column(:pages, "keep_published_by", :integer)
    add_column(:pages, "community_reviewed", :boolean)
    add_column(:pages, "community_reviewed_by", :integer)
    add_column(:pages, "staff_reviewed", :boolean)
    add_column(:pages, "staff_reviewed_by", :integer)
    add_column(:pages, "notes", :text)


    add_column(:pages, "unique_pageviews", :integer)
    add_column(:pages, "weeks_published", :integer)
    add_column(:pages, "mean_unique_pageviews", :float)
    add_column(:pages, "image_links", :integer)
    add_column(:pages, "hosted_image_count", :integer)

    remove_column(:pages, "node_id")
    remove_column(:pages, "migrated_id")
    remove_column(:pages, "url_title")
    remove_column(:pages, "content_length")
    remove_column(:pages, "content_words")
    remove_column(:pages, "indexed")
    remove_column(:pages, "is_dpl")

    page_audit_query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE pages, page_audits
    SET
    pages.keep_published = page_audits.keep_published,
    pages.keep_published_by = page_audits.keep_published_by,
    pages.community_reviewed = page_audits.community_reviewed,
    pages.community_reviewed_by = page_audits.community_reviewed_by,
    pages.staff_reviewed = page_audits.staff_reviewed,
    pages.staff_reviewed_by = page_audits.staff_reviewed_by,
    pages.notes = page_audits.notes
    WHERE page_audits.page_id = pages.id
    END_SQL

    execute "#{page_audit_query}"

    page_stat_query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE pages, page_stats
    SET
    pages.unique_pageviews = page_stats.unique_pageviews,
    pages.weeks_published = page_stats.weeks_published,
    pages.mean_unique_pageviews = page_stats.mean_unique_pageviews,
    pages.image_links = page_stats.image_links,
    pages.hosted_image_count = page_stats.hosted_images
    WHERE page_stats.page_id = pages.id
    END_SQL

    execute "#{page_stat_query}"

    execute "UPDATE audit_logs,page_audits SET auditable_type = 'Page', auditable_id = page_audits.page_id WHERE auditable_type = 'PageAudit' AND auditable_id = page_audits.id"
    execute "UPDATE audit_logs,hosted_image_audits SET auditable_type = 'HostedImage', auditable_id = hosted_image_audits.hosted_image_id WHERE auditable_type = 'HostedImageAudit' AND auditable_id = hosted_image_audits.id"

  end
end
