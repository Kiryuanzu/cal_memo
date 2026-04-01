foods = {
  breakfast: [
    [ "ごはん", 234 ],
    [ "納豆ごはん", 320 ],
    [ "食パン", 160 ],
    [ "トースト", 220 ],
    [ "ヨーグルト", 110 ],
    [ "ゆで卵", 80 ],
    [ "バナナ", 86 ],
    [ "味噌汁", 45 ]
  ],
  lunch_dinner: [
    [ "おにぎり", 180 ],
    [ "鮭おにぎり", 210 ],
    [ "鶏むねサラダ", 260 ],
    [ "親子丼", 620 ],
    [ "からあげ弁当", 720 ],
    [ "ハンバーグ定食", 780 ],
    [ "カレーライス", 840 ],
    [ "うどん", 380 ],
    [ "パスタ", 680 ]
  ],
  snack: [
    [ "プロテインバー", 185 ],
    [ "チョコレート", 120 ],
    [ "ポテトチップス", 336 ],
    [ "カフェラテ", 130 ],
    [ "アイスクリーム", 240 ],
    [ "ミックスナッツ", 180 ],
    [ "どら焼き", 284 ]
  ]
}

foods.each do |category, items|
  items.each do |name, calories|
    food = Food.find_or_initialize_by(category: category, name: name)
    food.calories = calories
    food.save!
  end
end
