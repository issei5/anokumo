require 'json'
require 'base64'
require_relative 'analyzer'

HEADERS = {
  'Access-Control-Allow-Origin' => '*',
  'Access-Control-Allow-Headers' => 'Content-Type'
}.freeze

def lambda_handler(event:, context:)
  # body = JSON.parse(event['body'])
  # image_data = body['image']
  # file_extension = File.extname(body['filename'])[1..]

  # まずはローカルの画像ファイルで検証
  file_path = './clouds-7382221_1280.jpeg'

  file_name = File.basename(file_path)
  file_extension = File.extname(file_name)[1..]
  image_data = File.read(file_path, mode: 'rb')

  # file_extension = 'jpeg' if file_extension == 'jpg'

  raise "#{file_extension} is unsupported file type" unless ['jpeg', 'png'].include?(file_extension)

  analysis_result = Analyzer.analyze(image_data, file_extension)

  {
    statusCode: 200,
    headers: HEADERS,
    body: JSON.generate({
      result: analysis_result
    })
  }
end
