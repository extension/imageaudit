class AddCommunityKeeperCounts < ActiveRecord::Migration
  def change
    add_column(:community_page_stats, "keep_pages", :integer)
    add_column(:community_page_stats, "keep_image_links", :integer)
    add_column(:community_page_stats, "keep_hosted_images", :integer)
    add_column(:community_page_stats, "keep_stock_images", :integer)
    add_column(:community_page_stats, "keep_not_stock_images", :integer)

    CommunityPageStat.reset_column_information
    Rebuild.do_it('all')
  end
end
