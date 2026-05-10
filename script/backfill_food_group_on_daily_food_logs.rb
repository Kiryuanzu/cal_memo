# Usage:
#   bin/rails runner script/backfill_food_group_on_daily_food_logs.rb
#
# AddFoodGroupToFoodsAndDailyFoodLogs migration より前に作成された
# DailyFoodLog レコードは food_group が default の 0 (=staple) のまま。
# 紐づく Food の food_group をコピーして実態に合わせる一回限りの補正。

updated = 0
DailyFoodLog.includes(:food).find_each do |log|
  next unless log.food
  next if log.food_group == log.food.food_group

  log.update_columns(food_group: log.food.food_group)
  updated += 1
end

puts "Backfilled food_group on #{updated} daily_food_logs."
puts "Distribution: #{DailyFoodLog.group(:food_group).count.inspect}"
