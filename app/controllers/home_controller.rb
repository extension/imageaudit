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
      @summary_data = Page.overall_stat_attributes
      @group_stats = Group.stats_by_group.sort_by{|id,data| data['group_name']} 
    end
  end
end
