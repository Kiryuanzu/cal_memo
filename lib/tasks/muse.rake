namespace :muse do
  desc "Upload all daily food logs to the Muse API Worker (MUSE_API_URL, MUSE_API_SYNC_TOKEN)"
  task sync: :environment do
    result = MuseSync.new(url: ENV["MUSE_API_URL"], token: ENV["MUSE_API_SYNC_TOKEN"]).push!
    puts "Synced #{result['log_count']} logs at #{result['last_synced_at']}"
  end
end
