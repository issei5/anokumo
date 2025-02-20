require 'aws-sdk-bedrockruntime'

class TypeAnalyzer
  REGION = 'ap-northeast-1'
  MODEL_ID = 'anthropic.claude-3-haiku-20240307-v1:0'
  PROMPT = <<~PROMPT
            この画像の真ん中の方にある雲の種類を教えてください。以下の選択肢から選んでその言葉だけ出力してください。
            [巻雲, 巻積雲, 巻層雲, 高積雲, 高層雲, 乱層雲, 層積雲, 層雲, 積雲, 積乱雲]
            雲ではない場合は「雲ではない」と出力してください。
          PROMPT

  def self.call(image_data, file_extension)
    new(image_data, file_extension).call
  end

  def initialize(image_data, file_extension)
    @image_data = image_data
    @file_extension = file_extension
  end

  def call
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
          { text: PROMPT }
        ]
      }
    ]
  end
end
