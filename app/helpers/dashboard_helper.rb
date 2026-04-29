module DashboardHelper
  DAILY_TARGET = 1_500
  WEEKLY_TARGET_LOWER = 10_150
  WEEKLY_TARGET_UPPER = 11_550
  MONTHLY_TARGET = 40_600
  DAILY_PROTEIN_TARGET = 60
  WEEKLY_PROTEIN_TARGET = 420

  BUTTON_BASE_CLASSES = "inline-flex min-h-11 items-center justify-center rounded-full px-4 text-sm font-semibold transition duration-200 hover:-translate-y-0.5"

  def panel_classes
    "rounded-[28px] border border-stone-200/80 bg-white/75 p-6 shadow-[0_18px_50px_rgba(54,31,18,0.12)] backdrop-blur-xl md:p-7"
  end

  def primary_button_classes
    "#{BUTTON_BASE_CLASSES} bg-gradient-to-br from-orange-500 to-orange-700 text-orange-50 shadow-[0_12px_24px_rgba(154,52,18,0.22)] hover:from-orange-400 hover:to-orange-600"
  end

  def subtle_button_classes
    "#{BUTTON_BASE_CLASSES} border border-stone-200/80 bg-white/80 text-stone-700 shadow-sm shadow-stone-950/5 hover:border-orange-200 hover:bg-orange-50"
  end

  def danger_button_classes
    "#{BUTTON_BASE_CLASSES} bg-rose-600 text-rose-50 shadow-[0_12px_24px_rgba(159,18,57,0.18)] hover:bg-rose-500"
  end

  def section_tab_classes
    "inline-flex min-h-10 items-center justify-center rounded-full border border-orange-200/70 bg-white/85 px-4 py-2 text-sm font-semibold text-orange-900 transition duration-200 hover:-translate-y-0.5 hover:border-orange-300 hover:bg-orange-50"
  end

  def food_button_classes
    "w-full rounded-2xl border border-orange-200/70 bg-orange-50/80 px-4 py-3 text-sm font-semibold text-orange-950 transition duration-200 hover:-translate-y-0.5 hover:border-orange-300 hover:bg-white"
  end

  def input_classes
    "w-full rounded-2xl border border-stone-200/80 bg-white px-4 py-3 text-sm text-stone-900 shadow-inner shadow-stone-950/5 focus:border-orange-300 focus:outline-none focus:ring-4 focus:ring-orange-100"
  end

  def progress_percent(current, target)
    [ (current.to_f / target * 100).round, 100 ].min
  end

  def calorie_tone_classes(calories)
    case calories
    when 2501.. then "border-rose-300/80 bg-rose-50/90 text-rose-950"
    when 2001..2500 then "border-amber-300/80 bg-amber-50/90 text-amber-950"
    else "border-stone-200/80 bg-white/80 text-stone-950"
    end
  end

  def section_tone_classes(calories)
    case calories
    when 2501.. then "border-rose-300/80 bg-rose-50/90"
    when 2001..2500 then "border-amber-300/80 bg-amber-50/90"
    else "border-stone-200/80 bg-white/75"
    end
  end

  def meal_badge_classes(meal_type)
    case meal_type
    when "breakfast" then "bg-amber-100 text-amber-900"
    when "lunch" then "bg-orange-100 text-orange-900"
    when "dinner" then "bg-rose-100 text-rose-900"
    else "bg-violet-100 text-violet-900"
    end
  end
end
