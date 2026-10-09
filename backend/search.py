"""
SnapFlow Media Search API Engine
Author: Developed by S. M. Mahmud Iqbal
Description: Multi-engine search resolver using YouTube HTML parser with yt-dlp fallback.
"""
import re
import json
import logging
import urllib.request
import urllib.parse
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import yt_dlp

logger = logging.getLogger("snapflow.search")

app = FastAPI(title="SnapFlow Search Engine")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def search_youtube_html(query: str, limit: int = 12) -> List[Dict[str, Any]]:
    """Fast, zero-auth YouTube search scraping via public results page."""
    encoded_query = urllib.parse.quote_plus(query)
    search_url = f"https://www.youtube.com/results?search_query={encoded_query}"
    
    req = urllib.request.Request(
        search_url,
        headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9"
        }
    )

    try:
        with urllib.request.urlopen(req, timeout=6) as response:
            html = response.read().decode("utf-8", errors="ignore")
    except Exception as e:
        logger.error(f"YouTube HTML search request failed: {e}")
        return []

    match = re.search(r'ytInitialData\s*=\s*(\{.+?\});</script>', html)
    if not match:
        match = re.search(r'var ytInitialData\s*=\s*(\{.+?\});', html)
    if not match:
        return []

    try:
        data = json.loads(match.group(1))
    except Exception as e:
        logger.error(f"Failed to parse ytInitialData JSON: {e}")
        return []

    results: List[Dict[str, Any]] = []
    try:
        sections = (
            data.get("contents", {})
            .get("twoColumnSearchResultsRenderer", {})
            .get("primaryContents", {})
            .get("sectionListRenderer", {})
            .get("contents", [])
        )
        for section in sections:
            item_contents = section.get("itemSectionRenderer", {}).get("contents", [])
            for item in item_contents:
                vr = item.get("videoRenderer")
                if not vr:
                    continue
                vid = vr.get("videoId")
                if not vid:
                    continue

                title = ""
                runs = vr.get("title", {}).get("runs", [])
                if runs:
                    title = "".join(r.get("text", "") for r in runs)
                else:
                    title = vr.get("title", {}).get("simpleText", "Untitled Media")

                uploader = ""
                owner_runs = vr.get("ownerText", {}).get("runs", [])
                if owner_runs:
                    uploader = owner_runs[0].get("text", "Unknown Channel")
                elif vr.get("shortBylineText", {}).get("runs"):
                    uploader = vr["shortBylineText"]["runs"][0].get("text", "Unknown Channel")

                duration = vr.get("lengthText", {}).get("simpleText", "LIVE / HD")
                views = vr.get("viewCountText", {}).get("simpleText", "")

                thumbnail = f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
                if vr.get("thumbnail", {}).get("thumbnails"):
                    thumbnail = vr["thumbnail"]["thumbnails"][-1].get("url", thumbnail)

                results.append({
                    "id": vid,
                    "title": title,
                    "uploader": uploader,
                    "duration": duration,
                    "views": views,
                    "thumbnail": thumbnail,
                    "url": f"https://www.youtube.com/watch?v={vid}",
                    "platform": "YouTube"
                })

                if len(results) >= limit:
                    break
            if len(results) >= limit:
                break
    except Exception as e:
        logger.error(f"Error parsing videoRenderer items: {e}")

    return results


def search_ytdlp_fallback(query: str, limit: int = 8) -> List[Dict[str, Any]]:
    """yt-dlp search fallback for secondary query resolution."""
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'skip_download': True,
        'nocheckcertificate': True,
        'noplaylist': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            res = ydl.extract_info(f"ytsearch{limit}:{query}", download=False)
            entries = res.get("entries", [])
            results = []
            for e in entries:
                vid = e.get("id")
                if not vid:
                    continue
                results.append({
                    "id": vid,
                    "title": e.get("title", "Untitled Media"),
                    "uploader": e.get("uploader", "Unknown Artist"),
                    "duration": f"{int(e['duration'] // 60)}:{int(e['duration'] % 60):02d}" if e.get("duration") else "LIVE",
                    "views": "",
                    "thumbnail": f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg",
                    "url": e.get("url") or f"https://www.youtube.com/watch?v={vid}",
                    "platform": "YouTube"
                })
            return results
        except Exception as e:
            logger.error(f"yt-dlp search fallback error: {e}")
            return []


def perform_search(query: str, limit: int = 12) -> List[Dict[str, Any]]:
    """Execute integrated search with HTML scrape and yt-dlp fallback."""
    q = query.strip()
    if not q:
        return []
    
    # Try fast HTML scrape first
    items = search_youtube_html(q, limit=limit)
    if items:
        return items
    
    # Fallback to yt-dlp search
    return search_ytdlp_fallback(q, limit=limit)


class SearchRequest(BaseModel):
    query: str
    limit: Optional[int] = 12


@app.get("/api/search")
@app.get("/")
def search_get(q: str = Query(..., description="Search keyword query")):
    if not q or not q.strip():
        raise HTTPException(status_code=400, detail="Query keyword cannot be empty.")
    items = perform_search(q)
    return JSONResponse(content={
        "query": q,
        "results": items,
        "total": len(items),
        "author": "Developed by S. M. Mahmud Iqbal"
    })


@app.post("/api/search")
def search_post(request: SearchRequest):
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
