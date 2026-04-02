# db/seeds.rb

foods_by_category = {
  breakfast: [
    { name: "食パン6枚切り", calories: 149 },
    { name: "ご飯150g", calories: 234 },
    { name: "納豆", calories: 90 },
    { name: "ゆで卵", calories: 80 },
    { name: "味噌汁", calories: 40 },
    { name: "ヨーグルト", calories: 110 },
    { name: "バナナ", calories: 86 },
    { name: "みかん", calories: 35 },
    { name: "いちご", calories: 34 },
    { name: "いちご（2粒）", calories: 12 }
  ],
  lunch_dinner: [
    { name: "ご飯150g", calories: 234 },
    { name: "味噌汁", calories: 40 },
    { name: "noshのお弁当", calories: 350 },
    { name: "おにぎり", calories: 180 },
    { name: "うどん", calories: 380 },
    { name: "そば", calories: 320 },
    { name: "ミートソース", calories: 500 },
    { name: "豚肉と玉ねぎ煮込み", calories: 350 },
    { name: "鶏・豚の酒蒸し", calories: 250 },
    { name: "鶏むねサラダ", calories: 260 },
    { name: "親子丼", calories: 400 },
    { name: "カレーライス", calories: 840 },
    { name: "ハンバーグ定食", calories: 780 },
    { name: "焼き魚定食", calories: 540 },
    { name: "しょうが焼き定食", calories: 690 }
  ],
  snack: [
    { name: "ミックスナッツ(少量)", calories: 15 },
    { name: "チーズ", calories: 60 },
    { name: "ゆで卵", calories: 80 }
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
    food.save!
  end
end

puts "Seeded #{Food.count} foods."
