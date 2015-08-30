# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file
class CommunitiesController < ApplicationController

  def index
  end

  def show
    @community = Group.find(params[:id])
    @summary_data = @community.community_page_stat.attributes
  end

end
