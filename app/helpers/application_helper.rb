module ApplicationHelper
  def calorie_tone_class(calories)
    case calories
    when 2501.. then "is-alert"
    when 2001..2500 then "is-warning"
    else "is-normal"
    end
  end

  def meal_type_badge(meal_type)
    "meal-#{meal_type.dasherize}"
  end
end
