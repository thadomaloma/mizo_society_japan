class GlobalSearch
  Section = Data.define(:key, :label, :icon, :records)

  def self.call(user:, query:)
    new(user:, query:).call
  end

  def initialize(user:, query:)
    @user = user
    @query = query.to_s.strip
  end

  def call
    return [] if query.blank?

    [
      Section.new(key: :members, label: "Members", icon: :members, records: members),
      Section.new(key: :minutes, label: "Minutes", icon: :documents, records: minutes),
      Section.new(key: :documents, label: "Letters", icon: :documents, records: documents),
      Section.new(key: :events, label: "Events", icon: :events, records: events),
      Section.new(key: :announcements, label: "Announcements", icon: :announcements, records: announcements)
    ].reject { |section| section.records.empty? }
  end

  private

  attr_reader :user, :query

  def members
    return MemberProfile.none unless user.super_admin?

    MemberProfile.search(query).includes(:user).latest.limit(5)
  end

  def minutes
    MeetingMinutePolicy::Scope.new(user, MeetingMinute)
      .resolve
      .search(query)
      .latest
      .limit(5)
  end

  def documents
    DocumentPolicy::Scope.new(user, Document)
      .resolve
      .search(query)
      .latest
      .limit(5)
  end

  def events
    EventPolicy::Scope.new(user, Event)
      .resolve
      .includes(:event_category)
      .search(query)
      .latest
      .limit(5)
  end

  def announcements
    AnnouncementPolicy::Scope.new(user, Announcement)
      .resolve
      .search(query)
      .latest
      .limit(5)
  end
end
