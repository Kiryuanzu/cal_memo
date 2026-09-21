exercises_by_type = {
  home: [
    { name: "スクワット", body_part: :lower_body },
    { name: "プランク", body_part: :core },
    { name: "サイドベント", body_part: :core },
    { name: "ダンベルカール", body_part: :chest_arms }
  ],
  gym: [
    { name: "ジム・肩", body_part: :shoulder },
    { name: "ジム・胸・上腕", body_part: :chest_arms },
    { name: "ジム・腹回り", body_part: :core },
    { name: "ジム・下半身", body_part: :lower_body }
  ]
}

exercises_by_type.each do |training_type, exercises|
  exercises.each do |attrs|
    exercise = TrainingExercise.find_or_initialize_by(name: attrs[:name], training_type: training_type)
    exercise.body_part = attrs[:body_part]
    exercise.save!
  end
end

puts "Seeded #{TrainingExercise.count} training exercises."
