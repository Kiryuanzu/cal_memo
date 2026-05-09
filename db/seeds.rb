# db/seeds.rb

foods_by_category = {
  breakfast: [
    { name: "食パン6枚切り", calories: 149, protein_g: 6, manual_calories_enabled: false },
    { name: "ご飯100g", calories: 156, protein_g: 3, manual_calories_enabled: false },
    { name: "ご飯120g", calories: 187, protein_g: 3, manual_calories_enabled: false },
    { name: "ご飯150g", calories: 234, protein_g: 4, manual_calories_enabled: false },
    { name: "納豆", calories: 90, protein_g: 8, manual_calories_enabled: false },
    { name: "ゆで卵", calories: 80, protein_g: 6, manual_calories_enabled: false },
    { name: "味噌汁", calories: 40, protein_g: 3, manual_calories_enabled: false },
    { name: "豆腐入り味噌汁", calories: 70, protein_g: 6, manual_calories_enabled: false },
    { name: "ヨーグルト", calories: 110, protein_g: 5, manual_calories_enabled: false },
    { name: "バナナ", calories: 86, protein_g: 1, manual_calories_enabled: false },
    { name: "みかん", calories: 35, protein_g: 1, manual_calories_enabled: false },
    { name: "いちご（2粒）", calories: 12, protein_g: 0, manual_calories_enabled: false }
  ],
  lunch_dinner: [
    { name: "ご飯100g", calories: 156, protein_g: 3, manual_calories_enabled: false },
    { name: "ご飯120g", calories: 187, protein_g: 3, manual_calories_enabled: false },
    { name: "ご飯150g", calories: 234, protein_g: 4, manual_calories_enabled: false },
    { name: "味噌汁", calories: 40, protein_g: 3, manual_calories_enabled: false },
    { name: "豆腐入り味噌汁", calories: 70, protein_g: 6, manual_calories_enabled: false },
    { name: "noshのお弁当", calories: 350, protein_g: 25, manual_calories_enabled: true },
    { name: "うどん", calories: 230, protein_g: 7, manual_calories_enabled: false },
    { name: "そば", calories: 320, protein_g: 11, manual_calories_enabled: false },
    { name: "ミートソース", calories: 500, protein_g: 20, manual_calories_enabled: false },
    { name: "豚肉と玉ねぎ煮込み", calories: 200, protein_g: 15, manual_calories_enabled: false },
    { name: "鶏・豚の酒蒸し", calories: 200, protein_g: 25, manual_calories_enabled: false },
    { name: "鶏むねサラダ", calories: 200, protein_g: 25, manual_calories_enabled: false },
    { name: "鶏ささみ（2本）", calories: 100, protein_g: 22, manual_calories_enabled: false },
    { name: "サラダチキン（3切れ）", calories: 60, protein_g: 12, manual_calories_enabled: false },
    { name: "鶏のさっぱり煮（手羽元1本）", calories: 220, protein_g: 10, manual_calories_enabled: false },
    { name: "親子丼", calories: 400, protein_g: 20, manual_calories_enabled: false },
    { name: "カレーライス", calories: 840, protein_g: 20, manual_calories_enabled: false },
    { name: "外食", calories: 900, protein_g: 25, manual_calories_enabled: true },
    { name: "ハンバーグ", calories: 300, protein_g: 18, manual_calories_enabled: false },
    { name: "ポトフ", calories: 300, protein_g: 12, manual_calories_enabled: false },
    { name: "クリームシチュー", calories: 400, protein_g: 15, manual_calories_enabled: false },
    { name: "焼き魚", calories: 200, protein_g: 25, manual_calories_enabled: false },
    { name: "しょうが焼き", calories: 150, protein_g: 15, manual_calories_enabled: false },
    { name: "きゅうりの漬物", calories: 15, protein_g: 0, manual_calories_enabled: false },
    { name: "茹でブロッコリー", calories: 20, protein_g: 3, manual_calories_enabled: false },
    { name: "茹でほうれん草", calories: 15, protein_g: 2, manual_calories_enabled: false },
    { name: "きんぴらごぼう", calories: 40, protein_g: 1, manual_calories_enabled: false },
    { name: "レバニラ卵炒め", calories: 200, protein_g: 15, manual_calories_enabled: false },
    { name: "トマトと卵炒め", calories: 100, protein_g: 7, manual_calories_enabled: false },
    { name: "無脂肪ヨーグルト", calories: 25, protein_g: 3, manual_calories_enabled: false },
    { name: "納豆", calories: 90, protein_g: 8, manual_calories_enabled: false },
    { name: "いちご（2粒）", calories: 12, protein_g: 0, manual_calories_enabled: false },
    { name: "アジフライ（小さめ1尾）", calories: 250, protein_g: 12 },
    { name: "千切りキャベツ", calories: 15, protein_g: 1 },
    { name: "青椒肉絲", calories: 300, protein_g: 15 }
  ],
  snack: [
    { name: "ミックスナッツ(少量)", calories: 15, protein_g: 1, manual_calories_enabled: false },
    { name: "チーズ", calories: 60, protein_g: 4, manual_calories_enabled: false },
    { name: "ゆで卵", calories: 80, protein_g: 6, manual_calories_enabled: false },
    { name: "和菓子", calories: 200, protein_g: 4, manual_calories_enabled: true },
    { name: "洋菓子", calories: 300, protein_g: 4, manual_calories_enabled: true }
  ]
}

foods_by_category.each do |category, foods|
  foods.each do |attrs|
    food = Food.find_or_initialize_by(
      name: attrs[:name],
      category: category
    )

    food.calories = attrs[:calories]
    food.protein_g = attrs[:protein_g]
    food.manual_calories_enabled = attrs.fetch(:manual_calories_enabled, false)
    food.save!
  end
end

puts "Seeded #{Food.count} foods."
