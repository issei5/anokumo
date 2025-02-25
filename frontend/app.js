// DOM elements
const elements = {
    captureButton: document.getElementById("captureButton"),
    reCaptureButton: document.getElementById("reCaptureButton"),
    sendButton: document.getElementById("sendButton"),
    resultDiv: document.getElementById("result"),
    video: document.getElementById("video"),
    canvas: document.getElementById("canvas"),
    capturedImageContainer: document.getElementById("capturedImageContainer"),
    capturedImage: document.getElementById("capturedImage"),
    loadingSpinner: document.getElementById("loadingSpinner"),
    okButton: document.getElementById('okButton'),
    permissionMessage: document.getElementById('permissionMessage'),
    captureSection: document.getElementById('captureSection'),
    map: document.getElementById('map')
  };
  
  // Canvas context
  const ctx = elements.canvas.getContext("2d");
  
  // Application state
  const state = {
    stream: null,
    capturedImageData: null,
    capturedLocation: null,
    capturedOrientation: null,
    position: null
  };
  
  const DEFAULT_LOCATION = {
    latitude: 35.682839,  // 東京の緯度
    longitude: 139.759455 // 東京の経度
};

  // Event listeners
  elements.okButton.addEventListener('click', handleOkButtonClick);
  elements.captureButton.addEventListener('click', handleCaptureButtonClick);
  elements.reCaptureButton.addEventListener('click', handleReCaptureButtonClick);
  elements.sendButton.addEventListener('click', handleSendButtonClick);
  
  // Main functions
  async function handleOkButtonClick() {
    try {
      showLoading(true);
      state.position = await getLocation();
  
      elements.permissionMessage.style.display = 'none';
      elements.captureSection.style.display = 'block';
      await startCamera();
    } catch (err) {
      showError('権限の取得に失敗しました', err);
    } finally {
      showLoading(false);
    }
  }
  
  async function handleCaptureButtonClick() {
    if (!state.stream) {
      alert('カメラが起動していません。');
      return;
    }
  
    try {
      showLoading(true);
      
      // Get orientation data
      const orientation = await getOrientation();
      
      // Save location data
      state.capturedLocation = {
        latitude: state.position.coords.latitude,
        longitude: state.position.coords.longitude,
      };
      
      // Save orientation data
      state.capturedOrientation = orientation;
      
      // Capture image
      captureImage();
      
      // Stop camera
      stopCamera();
      
      // Update UI
      updateUIAfterCapture();
      
      console.log('Captured Data:', {
        location: state.capturedLocation,
        orientation: state.capturedOrientation
      });
    } catch (err) {
      showError('データの取得に失敗しました', err);
      await startCamera();
    } finally {
      showLoading(false);
    }
  }
  
  async function handleReCaptureButtonClick() {
    await startCamera();
    resetMap();
    elements.resultDiv.innerHTML = '';
  }
  
  async function handleSendButtonClick() {
    if (!state.capturedImageData || !state.capturedLocation || !state.capturedOrientation) {
      alert('必要なデータが揃っていません。再度撮影してください。');
      return;
    }
  
    try {
      showLoading(true);
      elements.resultDiv.innerHTML = '解析中...';
  
      const response = await sendDataToAPI();
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
  
      const data = await response.json();
      console.log('API Response:', data);
      
      // Display results
      displayResults(data);
      
      // Reset state data
      resetCapturedData();
      
      // Update UI
      elements.sendButton.style.display = 'none';
      elements.reCaptureButton.style.display = 'block';
    } catch (err) {
      elements.resultDiv.innerHTML = '';
      showError('送信に失敗しました', err);
    } finally {
      showLoading(false);
    }
  }
  
  // Helper functions
  async function startCamera() {
    try {
      updateUIBeforeCapture();
      
      stopCamera();
      
      state.stream = await navigator.mediaDevices.getUserMedia({ 
        video: { 
          facingMode: 'environment',
          width: { ideal: 300 },
          height: { ideal: 300 }
        } 
      });
      
      elements.video.srcObject = state.stream;
      elements.video.style.display = 'block';
  
      await elements.video.play();
      await waitForVideoReady();
  
      // Add error listener
      state.stream.oninactive = () => {
        console.log('Camera stream ended');
      };
    } catch (err) {
      showError("カメラの起動に失敗しました", err);
    }
  }
  
  function stopCamera() {
    if (state.stream) {
      state.stream.getTracks().forEach(track => track.stop());
      state.stream = null;
    }
  }
  
  function waitForVideoReady() {
    return new Promise((resolve) => {
      if (elements.video.readyState >= 3) { // HAVE_FUTURE_DATA or higher
        resolve();
      } else {
        elements.video.addEventListener('loadeddata', () => {
          // Wait a bit for the first frame to fully load
          setTimeout(resolve, 500);
        });
      }
    });
  }
  
  function captureImage() {
    elements.canvas.width = elements.video.videoWidth;
    elements.canvas.height = elements.video.videoHeight;
    ctx.drawImage(elements.video, 0, 0, elements.canvas.width, elements.canvas.height);
    
    // Save image data with adjusted quality
    state.capturedImageData = elements.canvas.toDataURL("image/jpeg", 0.8);
  }
  
  function updateUIBeforeCapture() {
    elements.capturedImageContainer.style.display = 'none';
    elements.sendButton.style.display = 'none';
    elements.captureButton.style.display = 'block';
    elements.reCaptureButton.style.display = 'none';
  }
  
  function updateUIAfterCapture() {
    elements.capturedImage.src = state.capturedImageData;
    elements.video.style.display = 'none';
    elements.capturedImageContainer.style.display = 'block';
    elements.sendButton.style.display = 'block';
    elements.captureButton.style.display = 'none';
    elements.reCaptureButton.style.display = 'block';
  }
  
  function resetMap() {
    if (window.map) {
      window.map.remove();
      window.map = null;
    }
  
    const mapElement = document.getElementById('map');
    if (mapElement) {
      mapElement.remove();
    }
  
    const newMapDiv = document.createElement('div');
    newMapDiv.id = 'map';
    newMapDiv.style.height = '400px';
    elements.captureSection.appendChild(newMapDiv);
  }
  
  function resetCapturedData() {
    state.capturedImageData = null;
    state.capturedLocation = null;
    state.capturedOrientation = null;
  }
  
  function showLoading(isLoading) {
    elements.loadingSpinner.style.display = isLoading ? 'flex' : 'none';
  }
  
  function showError(message, error) {
    alert(`${message}: ${error.message}`);
    console.error(`${message}:`, error);
  }
  
  async function sendDataToAPI() {
    const base64Data = state.capturedImageData.replace(/^data:image\/jpeg;base64,/, '');
  
    const postData = {
      image: base64Data,
      image_type: 'jpeg',
      location: state.capturedLocation,
      orientation: {
        alpha: state.capturedOrientation.alpha,
        beta: state.capturedOrientation.beta,
        gamma: state.capturedOrientation.gamma
      },
    };
  
    console.log('Send Data:', postData);
  
    return fetch('https://n54istqshdgcez3erucqt4ddge0bokqi.lambda-url.ap-northeast-1.on.aws/', {
      method: 'POST',
      body: JSON.stringify(postData),
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  function displayResults(data) {
    elements.resultDiv.innerHTML = `解析結果: ${data.description}`;
    
    const latitude = data.position.latitude;
    const longitude = data.position.longitude;
    
    // Create map
    const map = L.map('map').setView([latitude, longitude], 13);
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    
    L.marker([latitude, longitude]).addTo(map)
      .bindPopup('雲がここにあります')
      .openPopup();
      
    // Save map reference
    window.map = map;
  }
  
  // Utility functions
  function getLocation() {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        console.warn('お使いのブラウザはGeolocationをサポートしていません。デフォルトの位置を返します。');
        resolve({ coords: DEFAULT_LOCATION });
        return;
      }
  
      navigator.geolocation.getCurrentPosition(
        resolve,
        (err) => {
          console.warn('位置情報の取得に失敗しました。デフォルトの位置を返します。', err);
          resolve({ coords: DEFAULT_LOCATION });
        },
        { 
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
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
          // Default values if orientation data is not available
          resolve({
            alpha: 0,   // 北
            beta: 45,   // Vertical rotation
            gamma: 0    // Roll
          });
          return;
        }
  
        // Correction for back camera
        const correctedAlpha = (event.alpha + 180) % 360;
        const correctedBeta = event.beta - 90;
        const correctedGamma = event.gamma;
  
        resolve({
          alpha: correctedAlpha,
          beta: correctedBeta,
          gamma: correctedGamma
        });
      });
    });
  }
