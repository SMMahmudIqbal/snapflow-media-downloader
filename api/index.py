"""
SnapFlow Media Downloader Backend API
Author: Developed by S. M. Mahmud Iqbal
Description: FastAPI server providing media extraction, format resolution, direct stream redirect, and downloads.
"""

import os
import re
import urllib.parse
import logging
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from starlette.middleware.base import BaseHTTPMiddleware

try:
    from .downloader import extract_info, download_media_file, get_stream_url
    from .search import perform_search
except ImportError:
    from downloader import extract_info, download_media_file, get_stream_url
    from search import perform_search

logger = logging.getLogger("snapflow.api")

app = FastAPI(
    title="SnapFlow Media Engine API",
    description="Cross-platform video and audio extraction API - Developed by S. M. Mahmud Iqbal",
    version="1.0.0"
)

# Normalize Vercel paths if needed
class VercelPathMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Support Vercel matched path header
        matched_path = request.headers.get("x-matched-path")
        if matched_path and matched_path != request.scope.get("path"):
            request.scope["path"] = matched_path
        elif request.scope.get("path", "").startswith("/api/index.py"):
            sub = request.scope["path"][len("/api/index.py"):]
            request.scope["path"] = sub if sub else "/"
        return await call_next(request)

app.add_middleware(VercelPathMiddleware)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ExtractRequest(BaseModel):
    url: str


class SearchRequest(BaseModel):
    query: str
    limit: int = 12


@app.get("/")
@app.get("/api")
def root_status():
    return {
        "status": "online",
        "service": "SnapFlow Media Engine",
        "developer": "Developed by S. M. Mahmud Iqbal",
        "version": "1.0.0"
    }


@app.get("/health")
@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "service": "SnapFlow Engine",
        "developer": "Developed by S. M. Mahmud Iqbal",
        "engine": "yt-dlp"
    }


@app.post("/extract")
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
        logger.error(f"Extract error: {e}")
        raise HTTPException(status_code=422, detail=f"Failed to extract media: {str(e)}")


@app.get("/search")
@app.get("/api/search")
def api_search(q: str = Query(..., description="Search keyword query")):
    """Live search for videos/audio across YouTube and platforms without pasting URL."""
    if not q or not q.strip():
        raise HTTPException(status_code=400, detail="Query keyword cannot be empty.")
    items = perform_search(q)
    return JSONResponse(content={
        "query": q,
        "results": items,
        "total": len(items),
        "author": "Developed by S. M. Mahmud Iqbal"
    })


@app.post("/search")
@app.post("/api/search")
def api_search_post(request: SearchRequest):
    """POST endpoint for live search."""
    q = request.query.strip()
    if not q:
        raise HTTPException(status_code=400, detail="Query keyword cannot be empty.")
    items = perform_search(q, limit=request.limit or 12)
    return JSONResponse(content={
        "query": q,
        "results": items,
        "total": len(items),
        "author": "Developed by S. M. Mahmud Iqbal"
    })


@app.get("/download")
@app.get("/api/download")
def api_download(
    url: str = Query(..., description="Target media URL"),
    format_id: str = Query(..., description="Format ID to download"),
    is_audio: bool = Query(False, description="Whether to extract audio only")
):
    """Download the media file by redirecting directly to the CDN stream or downloading locally."""
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
        
        raise HTTPException(status_code=404, detail="Media stream could not be found.")
    except Exception as e:
        logger.error(f"Download error: {e}")
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")


# Serve static web frontend if directory exists
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
