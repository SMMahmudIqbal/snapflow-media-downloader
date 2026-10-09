"""
SnapFlow Stream Download Redirect API
Author: Developed by S. M. Mahmud Iqbal
"""
import os
import urllib.parse
import logging
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, FileResponse

try:
    from .downloader import get_stream_url, download_media_file
except ImportError:
    from downloader import get_stream_url, download_media_file

logger = logging.getLogger("snapflow.download")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/download")
@app.get("/")
def download_endpoint(
    url: str = Query(..., description="Target media URL"),
    format_id: str = Query(..., description="Format ID to download"),
    is_audio: bool = Query(False, description="Whether to extract audio only")
):
    try:
        # First attempt: Direct stream URL redirect (instant, avoids Vercel 4.5MB limit and timeouts)
        stream_info = get_stream_url(url, format_id, is_audio=is_audio)
        if stream_info.get("stream_url"):
            filename = stream_info.get("filename", "download.mp4")
            return RedirectResponse(
                url=stream_info["stream_url"],
                status_code=307,
                headers={
                    "Content-Disposition": f'attachment; filename="{urllib.parse.quote(filename)}"',
                    "X-Developed-By": "Developed by S. M. Mahmud Iqbal"
                }
            )

        # Fallback for complex stream merges
        file_path = download_media_file(url, format_id, is_audio=is_audio)
        if os.path.exists(file_path):
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

        raise HTTPException(status_code=404, detail="Media stream could not be resolved.")
    except Exception as e:
        logger.error(f"Download error: {e}")
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")
