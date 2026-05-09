module FoodsHelper
  def food_list_item_classes
    "flex items-center justify-between gap-3 rounded-xl border border-stone-200/80 bg-white/85 px-3 py-2 shadow-sm shadow-stone-950/5"
  end

  def manual_food_badge_classes
    "inline-flex shrink-0 items-center rounded-full bg-orange-100 px-1.5 py-0.5 text-[10px] font-semibold text-orange-900"
  end

  def sort_toggle_classes(active)
    if active
      "inline-flex min-h-10 items-center justify-center rounded-full bg-gradient-to-br from-orange-500 to-orange-700 px-4 text-sm font-semibold text-orange-50 shadow-[0_12px_24px_rgba(154,52,18,0.22)]"
    else
      "inline-flex min-h-10 items-center justify-center rounded-full border border-stone-200/80 bg-white/85 px-4 text-sm font-semibold text-stone-700 shadow-sm shadow-stone-950/5 transition duration-200 hover:-translate-y-0.5 hover:border-orange-200 hover:bg-orange-50"
    end
  end

  def category_filter_classes(active)
    if active
      "inline-flex min-h-9 items-center justify-center rounded-full border border-orange-300 bg-orange-50 px-3 text-xs font-semibold text-orange-900 shadow-sm shadow-stone-950/5"
    else
      "inline-flex min-h-9 items-center justify-center rounded-full border border-stone-200/80 bg-white/85 px-3 text-xs font-semibold text-stone-700 shadow-sm shadow-stone-950/5 transition duration-200 hover:-translate-y-0.5 hover:border-orange-200 hover:bg-orange-50"
    end
  end
end
