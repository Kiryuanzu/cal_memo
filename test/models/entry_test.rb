require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "is invalid when calories is zero" do
    entry = Entry.new(name: "水", calories: 0, eaten_at: Time.zone.now)

    assert_not entry.valid?
    assert_includes entry.errors[:calories], "must be greater than 0"
  end

  test "sets eaten_at when blank" do
    freeze_time do
      entry = Entry.create!(name: "カフェラテ", calories: 130, eaten_at: nil)

      assert_equal Time.zone.now, entry.eaten_at
    end
  end
end
