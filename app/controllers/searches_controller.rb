class SearchesController < ApplicationController
  def index
    authorize :search, :index?

    @query = params[:q].to_s.strip
    @sections = GlobalSearch.call(user: current_user, query: @query)

    render partial: "searches/results" if turbo_frame_request?
  end
end
