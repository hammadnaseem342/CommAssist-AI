# CommAssist-AI

An AI-powered communication assistant that combines computer vision, speech recognition, and voice synthesis technologies to improve accessibility and real-time communication.

---

# Features

* Real-time sign language / hand gesture recognition
* Speech-to-Text conversion
* Text-to-Speech conversion
* AI-powered communication assistance
* FastAPI backend integration
* Native iOS application using Swift UIKit
* Computer vision-based gesture detection
* Real-time camera processing
* Machine learning model integration

---

# Technologies Used

## Frontend (iOS)

* Swift
* UIKit
* AVFoundation
* Vision Framework
* Xcode

## Backend

* FastAPI
* Python
* Uvicorn

## AI / Machine Learning

* MediaPipe
* OpenCV
* Scikit-learn
* RandomForestClassifier

---

# Project Structure

```bash
CommAssist-AI/
│
├── ios-app/
│   └── iOS UIKit application
│
├── backend-fastapi/
│   ├── main.py
│   ├── requirements.txt
│   ├── model.p
│   └── backend files
│
├── README.md
├── LICENSE
└── .gitignore
```

---

# How It Works

1. The iOS application captures camera input.
2. Hand gestures/signs are detected using computer vision.
3. The FastAPI backend processes the gesture data using the trained AI model.
4. The detected signs are converted into meaningful text/sentences.
5. Speech-to-text and text-to-speech modules provide additional communication support.
6. The processed response is displayed and spoken back to the user.

---

# Backend Setup (FastAPI)

## Clone Repository

```bash
git clone https://github.com/yourusername/CommAssist-AI.git
cd CommAssist-AI
```

## Create Virtual Environment

```bash
python -m venv .venv
```

### Activate Environment

#### Windows

```bash
.venv\Scripts\activate
```

#### macOS/Linux

```bash
source .venv/bin/activate
```

---

# Install Dependencies

```bash
pip install -r requirements.txt
```

---

# Run FastAPI Server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Server URL:

```bash
http://127.0.0.1:8000
```

---

# iOS Application Setup

1. Open the iOS project in Xcode.
2. Configure the API endpoint.
3. Connect a physical iPhone device.
4. Build and run the application.

---

# API Integration Example

```swift
let url = URL(string: "https://your-api-url/predict")
```

---

# Future Improvements

* Multi-language support
* More advanced sentence framing
* Cloud deployment
* Real-time translation
* Enhanced gesture recognition accuracy
* User authentication system
* Conversation history

---

# Deployment

The FastAPI backend can be deployed using:

* Render
* Railway
* Koyeb
* Fly.io

---

# Author

Muhammad Hammad

---

# License

This project is licensed under the MIT License.

---

# GitHub Topics

```txt
ai
fastapi
swift
ios
uikit
speech-to-text
text-to-speech
sign-language
gesture-recognition
computer-vision
machine-learning
opencv
mediapipe
accessibility
communication-assistant
```
