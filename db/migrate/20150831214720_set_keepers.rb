class SetKeepers < ActiveRecord::Migration

  def up
    # yes this is a data only migration, sometimes you gotta do what you gotta do
    Page.includes(:page_stat).find_each do |p|
      keep_page = true
      if(p.page_stat.weeks_published > 0 and p.page_stat.mean_unique_pageviews < 1)
        keep_page = false
        tags = p.tags.map(&:name)
        if(tags.include?('bio') or tags.include?('homage') or tags.include?('contents'))
          keep_page = true
        end
      end
      p.create_page_audit(keep_published: keep_page, keep_published_by: 1)
    end
  end

end
