module PaginatesRelations
  extend ActiveSupport::Concern

  ALLOWED_PAGE_SIZES = [ 25, 50, 100 ].freeze

  private

  def paginate_relation(scope, default_per_page: 25)
    per_page = params[:per_page].to_i
    per_page = default_per_page unless ALLOWED_PAGE_SIZES.include?(per_page)

    total_count = scope.count
    total_pages = [ (total_count.to_f / per_page).ceil, 1 ].max
    current_page = params[:page].to_i.clamp(1, total_pages)
    offset = (current_page - 1) * per_page

    @pagination = {
      page: current_page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      from: total_count.zero? ? 0 : offset + 1,
      to: [ offset + per_page, total_count ].min
    }

    scope.offset(offset).limit(per_page)
  end
end
