"""
SnapFlow Media Extraction API
Author: Developed by S. M. Mahmud Iqbal
"""
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

try:
    from .downloader import extract_info
except ImportError:
    from downloader import extract_info

logger = logging.getLogger("snapflow.extract")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ExtractRequest(BaseModel):
    url: str

@app.post("/api/extract")
@app.post("/")
def extract_endpoint(request: ExtractRequest):
    url = request.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty.")
    try:
        data = extract_info(url)
        return JSONResponse(content=data)
    except Exception as e:
        logger.error(f"Extract error: {e}")
        raise HTTPException(status_code=422, detail=f"Failed to extract media: {str(e)}")
