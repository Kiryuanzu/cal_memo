namespace :daily_food_logs do
  desc "Backfill DailyFoodLog#protein_g from related Food#protein_g (one-shot)"
  task backfill_protein_g: :environment do
    updated = 0
    skipped = 0

    DailyFoodLog.includes(:food).find_each do |log|
      if log.food.nil?
        skipped += 1
        next
      end

      log.update_columns(protein_g: log.food.protein_g)
      updated += 1
    end

    puts "Backfilled protein_g on #{updated} logs. Skipped #{skipped} (no associated Food)."
  end
end
