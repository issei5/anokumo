class PositionCalculator
  EARTH_RADIUS = 6371 * 1000 # 地球の半径（メートル）
  MAX_DISTANCE_TO_CLOUD = 300_000 # 雲までの最大距離（メートル）

  def self.call(captured_location, orientation, cloud_height)
    new(captured_location, orientation, cloud_height).call
  end

  def initialize(captured_location, orientation, cloud_height)
    @latitude = captured_location["latitude"] * Math::PI / 180 # 緯度（ラジアン）
    @longitude = captured_location["longitude"] * Math::PI / 180 # 経度（ラジアン）
    @cloud_height = cloud_height # 推定雲の高さ（メートル）

    # オイラー角度（alpha: 縦軸、beta: 横軸、gamma: ロール）
    @alpha = orientation["alpha"] * Math::PI / 180 # 水平回転（ラジアン）
    @beta = orientation["beta"] * Math::PI / 180 # 垂直回転（ラジアン）
  end

  def call
    # 雲までの距離を計算（仮定: βが雲までの方向を指す）
    distance_to_cloud = [@cloud_height / Math.tan(@beta), MAX_DISTANCE_TO_CLOUD].min

    # カメラの基準位置からの相対位置
    delta_x = distance_to_cloud * Math.sin(@alpha) # 東西方向
    delta_y = distance_to_cloud * Math.cos(@alpha) # 南北方向

    # 緯度・経度の変換
    delta_latitude = delta_y / EARTH_RADIUS * (180 / Math::PI)
    delta_longitude = delta_x / (EARTH_RADIUS * Math.cos(@latitude)) * (180 / Math::PI)

    {
      latitude: @latitude * 180 / Math::PI + delta_latitude,
      longitude: @longitude * 180 / Math::PI + delta_longitude,
      altitude: @cloud_height,
      distance_to_cloud: distance_to_cloud
    }
  end
end
