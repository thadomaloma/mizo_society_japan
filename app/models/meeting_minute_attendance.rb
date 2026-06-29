class MeetingMinuteAttendance < ApplicationRecord
  belongs_to :meeting_minute
  belongs_to :user

  enum :status, { present: 0, absent: 1, apology: 2 }, default: :present

  validates :user_id, uniqueness: { scope: :meeting_minute_id }
end
