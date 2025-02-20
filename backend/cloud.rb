class Cloud
  DEFAULT_NAME = "積雲"
  DATA = [
    { name: "巻雲", height: 9000, info: "空高くにできる薄い雲。羽毛のような形状で、天気の変化を知らせることも。" },
    { name: "巻積雲", height: 9000, info: "空高くにできる、小さな白い塊が集まった雲。魚の鱗に似ているため「うろこ雲」とも呼ばれる。" },
    { name: "巻層雲", height: 9000, info: "薄く広がった雲で、空をベールのように覆う。太陽や月に光環（ハロ）が見られることがある。" },
    { name: "高積雲", height: 5000, info: "ひとつひとつが小さな塊で、群れを成している。いわゆる「ひつじ雲」として知られる。" },
    { name: "高層雲", height: 5000, info: "灰色の層を成した雲で、薄いベールのように空を覆う。太陽や月がぼんやり見えることがある。" },
    { name: "乱層雲", height: 5000, info: "濃い灰色で厚みのある雲。広範囲に広がり、雨や雪をもたらす。" },
    { name: "層積雲", height: 1000, info: "低い高度で塊状に集まる雲。曇りの日によく見られる。" },
    { name: "層雲", height: 1000, info: "霧のように広がり、空全体を覆うことが多い。非常に低い高度で発生する。" },
    { name: "積雲", height: 1000, info: "青空に浮かぶ白い雲。形がはっきりしていて、良い天気の象徴。" },
    { name: "積乱雲", height: 6000, info: "非常に大きく成長する雲で、雷雨や激しい天候を伴うことが多い。入道雲としても知られる。" }
  ].freeze

  attr_reader :height

  def initialize(name)
    cloud = DATA.find { |c| c[:name] == name }
    @undefined_cloud = cloud.nil?
    cloud = DATA.find { |c| c[:name] == DEFAULT_NAME } if @undefined_cloud
    @name = cloud[:name]
    @height = cloud[:height]
    @info = cloud[:info]
  end

  def generate_description(alpha, beta, distance_to_cloud)
    [
      cloud_info,
      search_conditions(alpha, beta),
      distance_info(distance_to_cloud)
    ].join
  end

  def self.exists?(name)
    DATA.any? { |cloud| cloud[:name] == name }
  end

  private

  def cloud_info
    if @undefined_cloud
      "解析結果が不明なため、一般的な雲、#{@name}として扱います。この雲は#{@info}"
    else
      "この雲は#{@name}です。#{@info}"
    end
  end

  def search_conditions(alpha, beta)
    "以下の条件で雲を探しました！方角: #{direction(alpha)}, 水平線からの角度: #{beta.to_i}度, 雲の高さ: #{@height}m."
  end

  def distance_info(meters)
    prefix = "-> 雲まではおよそ "
    suffix = "。地図で表すとここです！"

    distance = format_distance(meters)
    [prefix, distance, suffix].join
  end

  def format_distance(meters)
    if meters >= 1000
      "#{format('%.2f', meters / 1000)}km"
    else
      "#{meters}m"
    end
  end

  def direction(alpha)
    case alpha
    when 337.5..360, 0...22.5 then "北 (N)"
    when 22.5...67.5 then "北東 (NE)"
    when 67.5...112.5 then "東 (E)"
    when 112.5...157.5 then "南東 (SE)"
    when 157.5...202.5 then "南 (S)"
    when 202.5...247.5 then "南西 (SW)"
    when 247.5...292.5 then "西 (W)"
    when 292.5...337.5 then "北西 (NW)"
    else "不明な方角"
    end
  end
end
