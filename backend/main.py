"""
SnapFlow Media Downloader Backend API
Author: Developed by S. M. Mahmud Iqbal
Description: FastAPI server providing media extraction, format resolution, and download streaming.
"""

import os
import urllib.parse
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, HttpUrl

from downloader import extract_info, download_media_file

app = FastAPI(
    title="SnapFlow Media Engine API",
    description="Cross-platform video and audio extraction API - Developed by S. M. Mahmud Iqbal",
    version="1.0.0"
)

# Enable CORS for Flutter mobile apps and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ExtractRequest(BaseModel):
    url: str


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "SnapFlow Engine",
        "developer": "Developed by S. M. Mahmud Iqbal",
        "engine": "yt-dlp"
    }


@app.post("/api/extract")
def api_extract(request: ExtractRequest):
    """Extract metadata, thumbnails, and available video/audio formats for a given media URL."""
    url = request.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty.")
    
    try:
        data = extract_info(url)
        return JSONResponse(content=data)
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Failed to extract media: {str(e)}")


@app.get("/api/download")
def api_download(
    url: str = Query(..., description="Target media URL"),
    format_id: str = Query(..., description="Format ID to download"),
    is_audio: bool = Query(False, description="Whether to extract audio only")
):
    """Download the media file and return it as a downloadable attachment stream."""
    try:
        file_path = download_media_file(url, format_id, is_audio=is_audio)
        if not os.path.exists(file_path):
            raise HTTPException(status_code=500, detail="Downloaded media file not found on disk.")
        
        filename = os.path.basename(file_path)
        media_type = "audio/mpeg" if is_audio else "video/mp4"

        return FileResponse(
            path=file_path,
            filename=filename,
            media_type=media_type,
            headers={
                "Content-Disposition": f'attachment; filename="{urllib.parse.quote(filename)}"',
                "X-Developed-By": "Developed by S. M. Mahmud Iqbal"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")


# Serve Web App / Mobile Preview frontend
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
