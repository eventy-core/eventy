# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserEvent, type: :model do
  it { should belong_to(:event) }
  it { should belong_to(:user) }
  it { should validate_presence_of(:user_id) }
  it { should validate_uniqueness_of(:user_id).scoped_to(:event_id) }
  it { should validate_uniqueness_of(:priority).scoped_to(:user_id) }

  let(:events) { create_list(:event_with_recipients, 3) }

  let(:alice) { create(:user, user_name: "alice") }

  let(:user_events) { create_list(:user_event, 3, user: alice) }

  context "validate scopes" do
    let(:main_event) { create(:event_with_recipients_and_co_hosts, users_count: 2, co_hosts_count: 1) }

    it "should return partcipants when participant called" do
      expect(main_event.user_events.participant.count).to eql 2
    end
    it "should return admins when admin called" do
      expect(main_event.user_events.admin.count).to eql 1
    end
    it "should return co_hosts when co_host called" do
      expect(main_event.user_events.co_host.count).to eql 1
    end
  end

  context "validate event role instance methods" do
    let(:admin_event) { create(:user_event, event_role: "admin") }

    it "should return true when admin_event.admin?" do
      expect(admin_event.admin?).to be_truthy
    end
    it "should return fase when admin_event.participant?" do
      expect(admin_event.participant?).to be_falsey
    end
  end

  context "validate priority methods" do
    let(:user_event1) { user_events[0] }
    let(:user_event2) { user_events[1] }
    let(:user_event3) { user_events[2] }

    before do
      user_event2.update_columns(priority: 1)
      user_event3.update_columns(priority: 2)
    end

    it "should add priority ig toggle called" do
      user_event1.toggle_priority
      expect(user_event1.priority).to eql 3
    end

    it "should unassin priority if having priority" do
      user_event2.toggle_priority
      expect(user_event2.priority).to be_nil
    end

    it "should reorder priority when priority from middle updated" do
      user_event2.toggle_priority
      user_event3.reload
      expect(user_event3.priority).to eql 1
    end

    it "should reorder priority when user event having priority destroyed" do
      user_event2.destroy
      user_event3.reload
      expect(user_event3.priority).to eql 1
    end
  end

  context "order by priority" do
    it "test order by priority builds expected query" do
      order_by_priority_sql = UserEvent.order_by_priority.to_sql
      expect(order_by_priority_sql).to include(%{ORDER BY "user_events"."priority" DESC NULLS LAST})
    end
  end

  context "arel queries" do
    it "test priority arel query builds as expected" do
      priority_sql = UserEvent.priority_greater_than(5).to_sql
      expect(priority_sql).to include(%{"user_events"."priority" > 5})
    end
  end
end
