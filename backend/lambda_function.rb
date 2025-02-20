require 'json'
require 'base64'
require_relative 'cloud'
require_relative 'type_analyzer'
require_relative 'position_calculator'

HEADERS = {
  'Access-Control-Allow-Origin' => '*',
  "Access-Control-Allow-Methods" => "POST, OPTIONS",
  'Access-Control-Allow-Headers' => 'Content-Type'
}.freeze

def lambda_handler(event:, context:)
  @event = event
  Encoding.default_external = Encoding::UTF_8 # 本当は環境変で設定した方がいい
  return option_response if http_method == "OPTIONS" # preflight request

  parse_event_body
  validate!

  cloud_name = TypeAnalyzer.call(@image_data, @file_extension)
  # cloud_name = "積雲"
  cloud = Cloud.new(cloud_name)

  cloud_position = PositionCalculator.call(@location, @orientation, cloud.height)

  cloud_description = cloud.generate_description(@orientation["alpha"], @orientation["beta"], cloud_position[:distance_to_cloud])
  success_response(cloud_position, cloud_description)
end

private

def http_method
  @event.dig("requestContext", "http", "method")
end

def option_response
  {
    statusCode: 200,
    headers: HEADERS,
    body: nil
  }
end

def parse_event_body
  body = JSON.parse(@event['body'])
  p "body is #{body}"
  encoded_image = body['image']
  @image_data = Base64.decode64(encoded_image)
  @file_extension = body['image_type']
  @location = body['location']
  @orientation = body['orientation']
  @orientation["beta"] = [@orientation["beta"], 1].max
end

def validate!
  raise 'Invalid request' unless @image_data && @file_extension && @location && @orientation
  raise "#{@file_extension} is unsupported file type" unless ['jpeg', 'png'].include?(@file_extension)
  raise "file size must be 5mb or less" if @image_data.bytesize > 5_000_000
end

def success_response(cloud_position, cloud_description)
  {
    statusCode: 200,
    headers: HEADERS,
    body: JSON.generate({position: cloud_position, description: cloud_description})
  }
end
