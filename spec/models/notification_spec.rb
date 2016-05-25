require 'rails_helper'

RSpec.describe Notification, type: :model do
  it 'count the user unread notifications' do
    user = create(:basic_user, :with_notifications)
    expect(user.reload.unread_notifications_count).to eq 5
    user.notifications.first.read!
    expect(user.reload.unread_notifications_count).to eq 4
  end

  it 'change unread after read' do
    notification = create(:notification)
    notification.read!
    expect(notification.unread?).to eq false
  end
end