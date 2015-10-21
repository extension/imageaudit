# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file
class CommunitiesController < ApplicationController

  def index
    @group_stats = Group.stats_by_group.sort_by{|id,data| data['group_name']} 
  end

  def show
    @community = Group.find(params[:id])
    @summary_data = @community.page_stat_attributes
  end

end
