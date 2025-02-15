const captureButton = document.getElementById("capture-btn");
const resultDiv = document.getElementById("result");
const video = document.getElementById("video");
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

// カメラの映像を取得
async function startCamera() {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });
        video.srcObject = stream;
    } catch (err) {
        resultDiv.innerHTML = "カメラの起動に失敗しました。";
    }
}

// 撮影ボタンが押された時の処理
captureButton.addEventListener("click", async () => {
    console.log("capture button clicked");
    // canvasに現在のビデオフレームを描画
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    // 画像データをBase64に変換
    const imageData = canvas.toDataURL("image/jpeg");

    // 現在地と角度の取得
    const position = await getGeolocation();
    const angle = await getDeviceOrientation();

    // APIに画像データを送信
    const response = await fetch("https://n54istqshdgcez3erucqt4ddge0bokqi.lambda-url.ap-northeast-1.on.aws/", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            image: imageData, // Base64エンコードされた画像
            latitude: position.latitude,
            longitude: position.longitude,
            angle: angle
        })
    });

    const result = await response.json();
    resultDiv.innerHTML = `解析結果: ${result.analysis}`;
});

// 現在地を取得する関数
function getGeolocation() {
    return new Promise((resolve, reject) => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(position => {
                resolve({
                    latitude: position.coords.latitude,
                    longitude: position.coords.longitude
                });
            }, reject);
        } else {
            reject("現在地が取得できません。");
        }
    });
}

// スマホの角度を取得する関数
function getDeviceOrientation() {
    return new Promise((resolve, reject) => {
        if (window.DeviceOrientationEvent) {
            window.addEventListener("deviceorientation", (event) => {
                resolve(event.alpha);
            });
        } else {
            reject("角度が取得できません。");
        }
    });
}

// カメラを起動
startCamera();
