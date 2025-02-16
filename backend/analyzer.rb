require 'aws-sdk-bedrockruntime'

class Analyzer
  REGION = 'ap-northeast-1'
  MODEL_ID = 'anthropic.claude-3-haiku-20240307-v1:0'

  def self.analyze(image_data:, file_extension:, location:, orientation:)
    new(image_data, file_extension, location, orientation).analyze
  end

  def initialize(image_data, file_extension, location, orientation)
    @image_data = image_data
    @file_extension = file_extension
    @location = location
    @orientation = orientation
  end

  def analyze
    response = bedrock_client.converse({
      model_id: MODEL_ID,
      messages: messages
    })

    response.output.message.content[0].text
  end

  private

  def bedrock_client
    Aws::BedrockRuntime::Client.new(region: REGION)
  end

  def messages
    [
      {
        role: 'user',
        content: [
          {
            image: {
              format: @file_extension,
              source: {
                bytes: @image_data
              }
            }
          },
          { text: generate_prompt }
        ]
      }
    ]
  end

  def generate_prompt
    # 位置情報
    latitude, longitude = @location[:latitude], @location[:longitude]

    # 方角・傾き情報
    alpha, beta, gamma = @orientation[:alpha], @orientation[:beta], @orientation[:gamma]

    # プロンプト生成
    prompt = <<~PROMPT
      You are an AI assistant specialized in cloud analysis. Based on the given information, please provide:
      1. The type of cloud in the provided image.
      2. The estimated position (latitude and longitude) of the cloud in the sky.

      Input data:
      - Image: A binary image data (Base64 encoded).
      - Location: Current position of the device in latitude and longitude.
      - Orientation: The orientation of the smartphone (alpha: horizontal direction, beta: vertical tilt, gamma: sideways tilt).

      Provided information:
      - Latitude: #{latitude}
      - Longitude: #{longitude}
      - Orientation:
        - Alpha (direction): #{alpha} degrees
        - Beta (vertical tilt): #{beta} degrees
        - Gamma (side tilt): #{gamma} degrees

      Additional notes:
      - Assume the cloud is at an altitude of 10,000 meters.
      - Estimate the cloud's position using the location and orientation provided.

      Please respond with a JSON object in the following format:
      {
        "cloud_type": "string",
        "cloud_position": {
          "latitude": float,
          "longitude": float
        }
      }

    PROMPT

    prompt
  end
end
