require 'aws-sdk-bedrockruntime'

class Analyzer
  REGION = 'ap-northeast-1'
  MODEL_ID = 'anthropic.claude-3-haiku-20240307-v1:0'
  PROMPT_TEXT = <<~PROMPT
    What type of cloud is in the image? Also, what is the average altitude?
    If it's not a cloud, answer with Cloud:false.
    Otherwise, please respond in the format below.
    Cloud:true/false
    Type:XX
    height:XX
  PROMPT

  def self.analyze(image_data, file_extension)
    new(image_data, file_extension).analyze
  end

  def initialize(image_data, file_extension)
    @image_data = image_data
    @file_extension = file_extension
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
          { text: PROMPT_TEXT }
        ]
      }
    ]
  end
end
