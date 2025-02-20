require 'json'
require 'base64'
require_relative 'type_analyzer'
require_relative 'position_calculator'

HEADERS = {
  'Access-Control-Allow-Origin' => '*',
  "Access-Control-Allow-Methods" => "POST, OPTIONS",
  'Access-Control-Allow-Headers' => 'Content-Type'
}.freeze

CLOUD_DATA = [
  { name: "巻雲", height: 9000, description: "空高くにできる薄い雲。羽毛のような形状で、天気の変化を知らせることも。" },
  { name: "巻積雲", height: 9000, description: "空高くにできる、小さな白い塊が集まった雲。魚の鱗に似ているため「うろこ雲」とも呼ばれる。" },
  { name: "巻層雲", height: 9000, description: "薄く広がった雲で、空をベールのように覆う。太陽や月に光環（ハロ）が見られることがある。" },
  { name: "高積雲", height: 5000, description: "ひとつひとつが小さな塊で、群れを成している。いわゆる「ひつじ雲」として知られる。" },
  { name: "高層雲", height: 5000, description: "灰色の層を成した雲で、薄いベールのように空を覆う。太陽や月がぼんやり見えることがある。" },
  { name: "乱層雲", height: 5000, description: "濃い灰色で厚みのある雲。広範囲に広がり、雨や雪をもたらす。" },
  { name: "層積雲", height: 1000, description: "低い高度で塊状に集まる雲。曇りの日によく見られる。" },
  { name: "層雲", height: 1000, description: "霧のように広がり、空全体を覆うことが多い。非常に低い高度で発生する。" },
  { name: "積雲", height: 1000, description: "青空に浮かぶ白い雲。形がはっきりしていて、良い天気の象徴。" },
  { name: "積乱雲", height: 6000, description: "非常に大きく成長する雲で、雷雨や激しい天候を伴うことが多い。入道雲としても知られる。" }
].freeze


def lambda_handler(event:, context:)
  @event = event
  Encoding.default_external = Encoding::UTF_8
  return option_response if http_method == "OPTIONS" # preflight request

  parse_event_body
  validate!

  # cloud_name = TypeAnalyzer.call(@image_data, @file_extension)
  # puts "解析結果: #{analysis_result}"
  # cloud = CLOUD_DATA.find { |c| c[:name] == cloud_name }
  # cloud_height = cloud[:height]
  # cloud_description = cloud[:description]
  cloud_description = "tmp"
  cloud_height = 10000

  cloud_position = PositionCalculator.call(@location, @orientation, cloud_height)

  puts "雲の位置: #{cloud_position}"

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
