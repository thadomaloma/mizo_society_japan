class DashboardCache
  class << self
    def expire_community
      Rails.cache.delete("dashboard/community_overview/v2")
    end

    def expire_finance
      Rails.cache.delete("admin_dashboard/finance_chart/#{Date.current.year}-#{Date.current.month}")
    end

    def expire_payments
      Rails.cache.delete("admin_dashboard/membership_payment_summary/#{Date.current}")
    end
  end
end
