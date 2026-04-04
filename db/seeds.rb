# db/seeds.rb

foods_by_category = {
  breakfast: [
    { name: "食パン6枚切り", calories: 149, manual_calories_enabled: false },
    { name: "ご飯150g", calories: 234, manual_calories_enabled: false },
    { name: "納豆", calories: 90, manual_calories_enabled: false },
    { name: "ゆで卵", calories: 80, manual_calories_enabled: false },
    { name: "味噌汁", calories: 40, manual_calories_enabled: false },
    { name: "ヨーグルト", calories: 110, manual_calories_enabled: false },
    { name: "バナナ", calories: 86, manual_calories_enabled: false },
    { name: "みかん", calories: 35, manual_calories_enabled: false },
    { name: "いちご", calories: 34, manual_calories_enabled: false },
    { name: "いちご（2粒）", calories: 12, manual_calories_enabled: false }
  ],
  lunch_dinner: [
    { name: "ご飯150g", calories: 234, manual_calories_enabled: false },
    { name: "味噌汁", calories: 40, manual_calories_enabled: false },
    { name: "noshのお弁当", calories: 350, manual_calories_enabled: false },
    { name: "うどん", calories: 380, manual_calories_enabled: false },
    { name: "そば", calories: 320, manual_calories_enabled: false },
    { name: "ミートソース", calories: 500, manual_calories_enabled: false },
    { name: "豚肉と玉ねぎ煮込み", calories: 350, manual_calories_enabled: false },
    { name: "鶏・豚の酒蒸し", calories: 250, manual_calories_enabled: false },
    { name: "鶏むねサラダ", calories: 260, manual_calories_enabled: false },
    { name: "親子丼", calories: 400, manual_calories_enabled: false },
    { name: "カレーライス", calories: 840, manual_calories_enabled: false },
    { name: "外食", calories: 900, manual_calories_enabled: true },
    { name: "ハンバーグ", calories: 300, manual_calories_enabled: false },
    { name: "焼き魚", calories: 200, manual_calories_enabled: false },
    { name: "しょうが焼き", calories: 150, manual_calories_enabled: false },
    { name: "きゅうりの漬物", calories: 15, manual_calories_enabled: false },
    { name: "茹でブロッコリー", calories: 20, manual_calories_enabled: false },
    { name: "茹でほうれん草", calories: 15, manual_calories_enabled: false },
    { name: "きんぴらごぼう", calories: 40, manual_calories_enabled: false }
  ],
  snack: [
    { name: "ミックスナッツ(少量)", calories: 15, manual_calories_enabled: false },
    { name: "チーズ", calories: 60, manual_calories_enabled: false },
    { name: "ゆで卵", calories: 80, manual_calories_enabled: false }
  ]
}

foods_by_category.each do |category, foods|
  seeded_names = foods.map { |attrs| attrs[:name] }
  obsolete_foods = Food.where(category: category).where.not(name: seeded_names)

  DailyFoodLog.where(food_id: obsolete_foods.select(:id)).delete_all
  obsolete_foods.delete_all

  foods.each do |attrs|
    food = Food.find_or_initialize_by(
      name: attrs[:name],
      category: category
    )

    food.calories = attrs[:calories]
    food.manual_calories_enabled = attrs.fetch(:manual_calories_enabled, false)
    food.save!
  end
end

puts "Seeded #{Food.count} foods."
