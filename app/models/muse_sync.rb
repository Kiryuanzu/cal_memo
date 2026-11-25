require "net/http"

# Uploads every DailyFoodLog to the Cloudflare Worker in muse_api/, which serves
# them read-only to Meta Muse. The Worker replaces its copy wholesale on each sync.
class MuseSync
  class Error < StandardError; end

  def initialize(url:, token:)
    raise ArgumentError, "MuseSync url is missing" if url.blank?
    raise ArgumentError, "MuseSync token is missing" if token.blank?

    @endpoint = URI.join(url, "/sync")
    @token = token
  end

  def payload
    logs = DailyFoodLog.order(:eaten_on, :id).map do |log|
      {
        id: log.id,
        date: log.eaten_on.iso8601,
        meal_type: log.meal_type,
        food_name: log.food_name,
        calories: log.calories,
        protein_g: log.protein_g,
        food_group: log.food_group,
        comment: log.comment
      }
    end

    { logs: logs }
  end

  def push!
    request = Net::HTTP::Post.new(@endpoint)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: @endpoint.scheme == "https") do |http|
      http.request(request)
    end
    raise Error, "sync failed: HTTP #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
