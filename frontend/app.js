const captureButton = document.getElementById("captureButton");
const sendButton = document.getElementById("sendButton");
const resultDiv = document.getElementById("result");
const video = document.getElementById("video");
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
const capturedImageContainer = document.getElementById("capturedImageContainer");
const capturedImage = document.getElementById("capturedImage");
const loadingSpinner = document.getElementById("loadingSpinner");

let stream = null;
let capturedImageData = null;
let capturedLocation = null;
let capturedOrientation = null;

// 1. OKボタンがクリックされたときの処理
document.getElementById('okButton').addEventListener('click', async function() {
    try {
        loadingSpinner.style.display = 'flex';
        await Promise.all([getLocation(), getCameraPermission()]);
        document.getElementById('permissionMessage').style.display = 'none';
        document.getElementById('captureSection').style.display = 'block';
        await startCamera();
    } catch (err) {
        alert('権限の取得に失敗しました: ' + err.message);
        console.error('Permission error:', err);
    } finally {
        loadingSpinner.style.display = 'none';
    }
});

async function startCamera() {
    try {
        if (stream) {
            stream.getTracks().forEach(track => track.stop());
        }
        stream = await navigator.mediaDevices.getUserMedia({ 
            video: { 
                facingMode: 'environment',  // 背面カメラを優先
                width: { ideal: 1920 },     // より高品質な画像を取得
                height: { ideal: 1080 }
            } 
        });
        video.srcObject = stream;
        video.style.display = 'block';
        capturedImageContainer.style.display = 'none';
        sendButton.style.display = 'none';
        captureButton.style.display = 'block';
        
        // エラー時のイベントリスナーを追加
        stream.oninactive = () => {
            console.log('Camera stream ended');
        };
    } catch (err) {
        alert("カメラの起動に失敗しました: " + err.message);
        console.error('Camera error:', err);
    }
}

// 2. 撮影ボタンがクリックされたときの処理
captureButton.addEventListener('click', async function() {
    if (!stream) {
        alert('カメラが起動していません。');
        return;
    }

    try {
        loadingSpinner.style.display = 'flex';

        // 位置情報と角度を並行して取得
        const [position, orientation] = await Promise.all([
            getLocation(),
            getOrientation()
        ]);

        capturedLocation = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy  // 精度情報を追加
        };

        capturedOrientation = orientation;

        // カメラを停止
        stream.getTracks().forEach(track => track.stop());
        stream = null;
        
        // 画像を取得
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        // 画像データを保存（品質を調整）
        capturedImageData = canvas.toDataURL("image/jpeg", 0.8);
        
        // UI更新
        capturedImage.src = capturedImageData;
        video.style.display = 'none';
        capturedImageContainer.style.display = 'block';
        sendButton.style.display = 'block';
        
        console.log('Captured Data:', {
            location: capturedLocation,
            orientation: capturedOrientation
        });
    } catch (err) {
        alert('データの取得に失敗しました: ' + err.message);
        console.error('Capture error:', err);
        // エラー時にカメラを再起動
        await startCamera();
    } finally {
        loadingSpinner.style.display = 'none';
    }
});

// 3. 送信ボタンがクリックされたときの処理
sendButton.addEventListener('click', async function() {
    if (!capturedImageData || !capturedLocation || !capturedOrientation) {
        alert('必要なデータが揃っていません。再度撮影してください。');
        return;
    }

    try {
        loadingSpinner.style.display = 'flex';
        resultDiv.innerHTML = '解析中...';

        const postData = {
            image: capturedImageData,
            location: capturedLocation,
            orientation: {
                alpha: capturedOrientation.alpha,
                beta: capturedOrientation.beta,
                gamma: capturedOrientation.gamma
            },
        };

        console.log('Send Data:', postData);

        const response = await fetch('https://n54istqshdgcez3erucqt4ddge0bokqi.lambda-url.ap-northeast-1.on.aws/', {
            method: 'POST',
            body: JSON.stringify(postData),
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        console.log('API Response:', data);
        resultDiv.innerHTML = `解析結果: ${data.result}`;

        // 送信成功後のクリーンアップ
        capturedImageData = null;
        capturedLocation = null;
        capturedOrientation = null;
        
        // カメラを再起動（次の撮影のため）
        await startCamera();
    } catch (err) {
        alert('送信に失敗しました: ' + err.message);
        console.error('Send error:', err);
    } finally {
        loadingSpinner.style.display = 'none';
    }
});

function getLocation() {
    return new Promise((resolve, reject) => {
        if (!navigator.geolocation) {
            reject(new Error('お使いのブラウザはGeolocationをサポートしていません。'));
            return;
        }

        navigator.geolocation.getCurrentPosition(
            resolve,
            (err) => reject(new Error('位置情報の取得に失敗しました: ' + err.message)),
            { 
                enableHighAccuracy: true,  // 高精度な位置情報を要求
                timeout: 10000,            // 10秒でタイムアウト
                maximumAge: 0              // キャッシュを使用しない
            }
        );
    });
}

function getOrientation() {
    return new Promise((resolve, reject) => {
        if (!window.DeviceOrientationEvent) {
            reject(new Error('お使いのブラウザはDeviceOrientationをサポートしていません。'));
            return;
        }

        const timeoutId = setTimeout(() => {
            reject(new Error('角度情報の取得がタイムアウトしました。'));
        }, 3000);

        window.addEventListener('deviceorientation', function handler(event) {
            clearTimeout(timeoutId);
            window.removeEventListener('deviceorientation', handler);
            
            if (event.alpha === null || event.beta === null || event.gamma === null) {
                reject(new Error('角度情報の取得に失敗しました。'));
                return;
            }

            resolve({
                alpha: event.alpha,
                beta: event.beta,
                gamma: event.gamma
            });
        });
    });
}

function getCameraPermission() {
    return navigator.mediaDevices.getUserMedia({ 
        video: { 
            facingMode: 'environment' 
        } 
    });
}
