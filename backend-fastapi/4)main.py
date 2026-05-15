"""
COMM AI - Sign Language Recognition API
Wraps your existing model.p directly — no retraining needed.

HOW TO RUN IN PYCHARM:
  1. Put this file in the same folder as your model.p
  2. pip install fastapi uvicorn scikit-learn numpy
  3. Click the green ▶ Play button on this file

GESTURE RULES (same as your original main.py):
  X = SPACE between words
  Z = QUIT (handled on iOS side by closing camera)
"""

import pickle
import numpy as np
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict
import os

# ── Load YOUR existing model.p ────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_dict = pickle.load(open(os.path.join(BASE_DIR, 'model.p'), 'rb'))
model = model_dict['model']

# Exact same labels_dict from your original main.py
labels_dict = {
    0: 'A', 1: 'B',  2: 'C',  3: 'D',  4: 'E',  5: 'F',
    6: 'G', 7: 'H',  8: 'I',  9: 'J', 10: 'K', 11: 'L',
   12: 'M',13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R',
   18: 'T',19: 'S', 20: 'U', 21: 'V', 22: 'W', 23: 'X',
   24: 'Y',25: 'Z'
}

print(f"✅ model.p loaded — {type(model).__name__}, {model.n_features_in_} features")

# ── FastAPI setup ─────────────────────────────────────────────
app = FastAPI(
    title="COMM AI Sign Language API",
    description="Wraps your existing MediaPipe-trained model.p",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Request / Response schemas ────────────────────────────────
class Landmark(BaseModel):
    x: float
    y: float

class PredictRequest(BaseModel):
    landmarks: List[Landmark]  # 21 landmarks from Vision Framework

class PredictResponse(BaseModel):
    letter: str
    confidence: float
    all_probabilities: Dict[str, float]

# ── Feature extraction ────────────────────────────────────────
def extract_features(landmarks: List[Landmark]) -> np.ndarray:
    x_ = [lm.x for lm in landmarks]
    y_ = [lm.y for lm in landmarks]
    min_x = min(x_)
    min_y = min(y_)

    data_aux = []
    for lm in landmarks:
        data_aux.append(lm.x - min_x)
        data_aux.append(lm.y - min_y)

    return np.asarray(data_aux)

# ── Endpoints ─────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "service": "COMM AI Sign Language API",
        "status": "running",
        "model": type(model).__name__,
        "features": model.n_features_in_
    }

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest):
    if len(request.landmarks) != 21:
        raise HTTPException(
            status_code=400,
            detail=f"Expected 21 landmarks, got {len(request.landmarks)}"
        )

    try:
        features = extract_features(request.landmarks)
        prediction = model.predict([features])
        probs      = model.predict_proba([features])[0]

        predicted_idx    = int(prediction[0])
        predicted_letter = labels_dict[predicted_idx]
        confidence       = float(probs[predicted_idx])

        all_probs = {
            labels_dict[i]: float(probs[i])
            for i in range(len(probs))
        }

        return PredictResponse(
            letter=predicted_letter,
            confidence=confidence,
            all_probabilities=all_probs
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── PyCharm play button entry point ──────────────────────────
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)