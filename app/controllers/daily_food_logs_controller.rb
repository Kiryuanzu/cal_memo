class DailyFoodLogsController < ApplicationController
  before_action :set_selected_date
  before_action :set_selected_tab
  before_action :set_daily_food_log, only: :destroy

  def index
    load_dashboard
  end

  def create
    food = Food.find(daily_food_log_params[:food_id])
    @daily_food_log = DailyFoodLog.new(
      food: food,
      meal_type: daily_food_log_params[:meal_type],
      eaten_on: @selected_date,
      calories: food.manual_calories_enabled? ? daily_food_log_params[:calories] : food.calories
    )

    if @daily_food_log.save
      @daily_food_log = nil
      load_dashboard

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "#{food.name}を登録しました。"
          render_dashboard_updates
        end
        format.html { redirect_to root_path(date: @selected_date.iso8601, tab: @selected_tab), notice: "#{food.name}を登録しました。" }
      end
    else
      load_dashboard

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @daily_food_log.errors.full_messages.to_sentence
          render_dashboard_updates(status: :unprocessable_entity)
        end
        format.html do
          flash.now[:alert] = @daily_food_log.errors.full_messages.to_sentence
          render :index, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    eaten_on = @daily_food_log.eaten_on
    @daily_food_log.destroy!
    load_dashboard

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "記録を削除しました。"
        render_dashboard_updates
      end
      format.html { redirect_to root_path(date: eaten_on.iso8601, tab: @selected_tab), notice: "記録を削除しました。", status: :see_other }
    end
  end

  private
    def set_daily_food_log
      @daily_food_log = DailyFoodLog.find(params.expect(:id))
    end

    def set_selected_date
      @selected_date = parse_date(params[:date] || params.dig(:daily_food_log, :eaten_on)) || Time.zone.today
    end

    def set_selected_tab
      @selected_tab = params[:tab].in?(%w[day week month]) ? params[:tab] : "day"
    end

    def daily_food_log_params
      params.expect(daily_food_log: [ :food_id, :meal_type, :eaten_on, :calories ])
    end

    def parse_date(value)
      return if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def load_dashboard
      @daily_logs = DailyFoodLog.includes(:food).for_date(@selected_date).order(:meal_type, :created_at)
      logs_by_meal_type = @daily_logs.group_by(&:meal_type)

      @meal_sections = DailyFoodLog.meal_types.keys.map do |meal_type|
        meal_logs = logs_by_meal_type.fetch(meal_type, [])

        {
          key: meal_type,
          label: DailyFoodLog.meal_label(meal_type),
          foods: Food.available_for_meal_type(meal_type),
          logs: meal_logs,
          total_calories: meal_logs.sum(&:calories)
        }
      end

      @period_totals = {
        day: DailyFoodLog.total_for(@selected_date),
        week: DailyFoodLog.total_for(@selected_date.all_week),
        month: DailyFoodLog.total_for(@selected_date.all_month)
      }
      @summary_rows = summary_rows_for(@selected_tab)
      @daily_summary_text = DailyFoodLog.natural_language_for(@selected_date, @daily_logs)
    end

    def summary_rows_for(tab)
      case tab
      when "week"
        weekly_rows
      when "month"
        monthly_rows
      else
        daily_rows
      end
    end

    def daily_rows
      range = (@selected_date - 9.days)..@selected_date
      totals = DailyFoodLog.within(range).group(:eaten_on).sum(:calories)

      range.to_a.reverse.map do |date|
        {
          label: "#{date.month}/#{date.day}",
          subtitle: japanese_wday(date),
          calories: totals.fetch(date, 0),
          tone: calorie_tone(totals.fetch(date, 0))
        }
      end
    end

    def weekly_rows
      starts = 7.times.map { |offset| @selected_date.beginning_of_week - offset.weeks }
      range = starts.last..@selected_date.end_of_week
      totals_by_week = DailyFoodLog.within(range).group_by { |log| log.eaten_on.beginning_of_week }

      starts.map do |week_start|
        week_end = week_start.end_of_week

        {
          label: "#{week_start.month}/#{week_start.day} - #{week_end.month}/#{week_end.day}",
          subtitle: "週合計",
          calories: totals_by_week.fetch(week_start, []).sum(&:calories),
          tone: :normal
        }
      end
    end

    def monthly_rows
      starts = 6.times.map { |offset| (@selected_date.beginning_of_month << offset) }
      range = starts.last.beginning_of_month..@selected_date.end_of_month
      totals_by_month = DailyFoodLog.within(range).group_by { |log| log.eaten_on.beginning_of_month }

      starts.map do |month_start|
        {
          label: "#{month_start.year}/#{month_start.month}",
          subtitle: "月合計",
          calories: totals_by_month.fetch(month_start, []).sum(&:calories),
          tone: :normal
        }
      end
    end

    def calorie_tone(calories)
      return :alert if calories > 2500
      return :warning if calories > 2000

      :normal
    end

    def japanese_wday(date)
      %w[日 月 火 水 木 金 土][date.wday]
    end

    def render_dashboard_updates(status: :ok)
      render turbo_stream: [
        turbo_stream.replace("flash", partial: "shared/flash"),
        turbo_stream.update("dashboard", partial: "daily_food_logs/dashboard")
      ], status: status
    end
end
