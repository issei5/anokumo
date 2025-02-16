require 'json'
require 'base64'
require_relative 'analyzer'

HEADERS = {
  'Access-Control-Allow-Origin' => '*',
  "Access-Control-Allow-Methods" => "POST, OPTIONS",
  'Access-Control-Allow-Headers' => 'Content-Type'
}.freeze

def lambda_handler(event:, context:)
  @event = event
  Encoding.default_external = Encoding::UTF_8
  return option_response if http_method == "OPTIONS" # preflight request

  parse_event_body
  validate!

  analysis_result = Analyzer.analyze(
    image_data: @image_data,
    file_extension: @file_extension,
    location: @location,
    orientation: @orientation
  )
  success_response(analysis_result)
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
end

def validate!
  raise 'Invalid request' unless @image_data && @file_extension && @location && @orientation
  raise "#{@file_extension} is unsupported file type" unless ['jpeg', 'png'].include?(@file_extension)
  raise "file size must be 5mb or less" if @image_data.bytesize > 5_000_000
end

def success_response(analysis_result)
  {
    statusCode: 200,
    headers: HEADERS,
    body: JSON.generate({result: analysis_result})
  }
end
