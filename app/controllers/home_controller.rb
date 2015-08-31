# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :check_for_rebuild,  only: [:index]

  def index
    @rebuild = Rebuild.latest
    if(@rebuild.in_progress?)
      @hide_navbar = true
      return render :template => 'home/rebuild_in_progress'
    else
      @summary_data = PageStat.overall_stat_attributes
      #@summary_data['viewed_stock_images'] = HostedImage.viewed_stock_count
    end
  end
end
