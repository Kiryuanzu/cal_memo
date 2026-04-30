class FoodsController < ApplicationController
  CATEGORY_LABELS = {
    "breakfast" => "朝食",
    "lunch_dinner" => "昼・夜食",
    "snack" => "間食"
  }.freeze

  SORT_OPTIONS = %w[count_desc count_asc recent].freeze
  RECENT_CATEGORIES = %w[breakfast lunch_dinner snack].freeze

  def index
    @sort = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "count_desc"
    @recent_category = RECENT_CATEGORIES.include?(params[:category]) ? params[:category] : "lunch_dinner"
    @log_counts = DailyFoodLog.group(:food_id).count
    @last_eaten_on = DailyFoodLog.group(:food_id).maximum(:eaten_on)

    scope = Food.where(id: @log_counts.keys)
    scope = scope.where(category: @recent_category) if @sort == "recent"
    @foods = scope.to_a.sort_by { |food| sort_key_for(food) }
  end

  private
    def sort_key_for(food)
      count = @log_counts.fetch(food.id, 0)
      last_jd = @last_eaten_on[food.id]&.jd || 0

      case @sort
      when "count_asc" then [ count, food.name ]
      when "recent"    then [ -last_jd, -count, food.name ]
      else                  [ -count, food.name ]
      end
    end
end
