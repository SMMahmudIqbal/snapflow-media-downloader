"""
SnapFlow Health Check API
Author: Developed by S. M. Mahmud Iqbal
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/api/health")
@app.get("/")
def health_endpoint():
    return {
        "status": "healthy",
        "service": "SnapFlow Engine",
        "developer": "Developed by S. M. Mahmud Iqbal",
        "engine": "yt-dlp"
    }
