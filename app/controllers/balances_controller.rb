class BalancesController < ApplicationController
  ALLOWED_RANGE_DAYS = [ 7, 30, 90 ].freeze
  DEFAULT_RANGE_DAYS = 30
  STALE_THRESHOLD_DAYS = 10

  GROUP_LABELS = {
    "staple" => "主食",
    "main" => "主菜",
    "side" => "副菜",
    "fruit" => "果物",
    "dairy" => "乳製品",
    "sweet" => "嗜好品"
  }.freeze

  def show
    @range_days = parse_range_days(params[:range])
    range = (@range_days - 1).days.ago.to_date..Date.current

    @group_counts = DailyFoodLog
      .within(range)
      .group(:food_group)
      .distinct
      .count(:eaten_on)

    @stale_foods_by_group = stale_foods_by_group
  end

  private
    def parse_range_days(value)
      days = value.to_i
      ALLOWED_RANGE_DAYS.include?(days) ? days : DEFAULT_RANGE_DAYS
    end

    def stale_foods_by_group
      threshold = STALE_THRESHOLD_DAYS.days.ago.to_date
      last_eaten_on = DailyFoodLog.group(:food_id).maximum(:eaten_on)
      stale_food_ids = last_eaten_on.select { |_, last| last < threshold }.keys
      foods = Food.where(id: stale_food_ids).index_by(&:id)
      today = Date.current

      last_eaten_on
        .filter_map do |food_id, last|
          next if last >= threshold

          food = foods[food_id]
          next unless food

          { food: food, last_eaten_on: last, days_ago: (today - last).to_i }
        end
        .group_by { |item| item[:food].food_group }
        .transform_values { |items| items.sort_by { |item| -item[:days_ago] } }
    end
end
