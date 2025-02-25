require 'json'
require 'base64'
require_relative 'cloud'
require_relative 'type_analyzer'
require_relative 'position_calculator'

def lambda_handler(event:, context:)
  handler = Handler.new(event, context)
  handler.call
end

class Handler
  HEADERS = {
    'Access-Control-Allow-Origin' => '*',
    "Access-Control-Allow-Methods" => "POST, OPTIONS",
    'Access-Control-Allow-Headers' => 'Content-Type'
  }.freeze

  SUPPORTED_FILE_TYPES = ['jpeg', 'png'].freeze
  MAX_FILE_SIZE = 5_000_000

  def initialize(event, context)
    @event = event
    Encoding.default_external = Encoding::UTF_8 # 本当は環境変で設定した方がいい
  end

  def call
    return option_response if preflight_request?

    parse_request_data
    validate!

    cloud_position, cloud_description = generate_cloud_info

    success_response(cloud_position, cloud_description)
  end

  private

  def preflight_request?
    @event.dig("requestContext", "http", "method") == "OPTIONS"
  end

  def option_response
    {
      statusCode: 200,
      headers: HEADERS,
      body: nil
    }
  end

  def parse_request_data
    body = JSON.parse(@event['body'])
    encoded_image = body['image']
    @image_data = Base64.decode64(encoded_image)
    @file_extension = body['image_type']
    @location = body['location']
    @orientation = body['orientation']
    @orientation["beta"] = [@orientation["beta"], 1].max
  end

  def validate!
    raise 'Invalid request' unless @image_data && @file_extension && @location && @orientation
    raise "#{@file_extension} is unsupported file type" unless SUPPORTED_FILE_TYPES.include?(@file_extension)
    raise "file size must be 5mb or less" if @image_data.bytesize > MAX_FILE_SIZE
  end

  def generate_cloud_info
    cloud_name = TypeAnalyzer.call(@image_data, @file_extension)

    cloud = Cloud.new(cloud_name)

    cloud_position = PositionCalculator.call(@location, @orientation, cloud.height)

    cloud_description = cloud.generate_description(@orientation["alpha"], @orientation["beta"], cloud_position[:distance_to_cloud])

    [cloud_position, cloud_description]
  end

  def success_response(cloud_position, cloud_description)
    {
      statusCode: 200,
      headers: HEADERS,
      body: JSON.generate({position: cloud_position, description: cloud_description})
    }
  end
end
