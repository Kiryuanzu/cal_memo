require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entry = entries(:one)
  end

  test "should get index" do
    get root_url
    assert_response :success
    assert_match "86 kcal", @response.body
  end

  test "should get new" do
    get new_entry_url
    assert_response :success
  end

  test "should create entry" do
    assert_difference("Entry.count") do
      post entries_url, params: { entry: { calories: @entry.calories, eaten_at: @entry.eaten_at, name: @entry.name, note: @entry.note } }
    end

    assert_redirected_to entries_url
  end

  test "should get edit" do
    get edit_entry_url(@entry)
    assert_response :success
  end

  test "should update entry" do
    patch entry_url(@entry), params: { entry: { calories: @entry.calories, eaten_at: @entry.eaten_at, name: @entry.name, note: @entry.note } }
    assert_redirected_to entries_url
  end

  test "should destroy entry" do
    assert_difference("Entry.count", -1) do
      delete entry_url(@entry)
    end

    assert_redirected_to entries_url
  end
end
