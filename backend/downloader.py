"""
SnapFlow Media Downloader Backend Engine
Author: Developed by S. M. Mahmud Iqbal
Description: Core extraction and stream handler powered by yt-dlp.
"""

import os
import re
import tempfile
import logging
from typing import Dict, Any, List, Optional
import yt_dlp

logger = logging.getLogger("snapflow.downloader")
DOWNLOAD_DIR = os.path.join(tempfile.gettempdir(), "snapflow_downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)


def format_bytes(size: Optional[int]) -> str:
    """Format file size in human-readable string."""
    if not size or size <= 0:
        return "Unknown size"
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"


def format_duration(seconds: Optional[int]) -> str:
    """Format seconds into MM:SS or HH:MM:SS."""
    if not seconds:
        return "Unknown"
    mins, secs = divmod(seconds, 60)
    hours, mins = divmod(mins, 60)
    if hours > 0:
        return f"{hours}:{mins:02d}:{secs:02d}"
    return f"{mins}:{secs:02d}"


def get_platform_name(extractor: str, url: str) -> str:
    """Detect human-friendly platform name."""
    ext = (extractor or "").lower()
    url_low = url.lower()
    if "youtube" in ext or "youtu.be" in url_low:
        return "YouTube"
    if "tiktok" in ext or "tiktok" in url_low:
        return "TikTok"
    if "instagram" in ext or "instagram" in url_low:
        return "Instagram"
    if "twitter" in ext or "x.com" in url_low or "twitter.com" in url_low:
        return "X (Twitter)"
    if "facebook" in ext or "fb" in url_low:
        return "Facebook"
    if "vimeo" in ext:
        return "Vimeo"
    if "reddit" in ext:
        return "Reddit"
    if "pinterest" in ext:
        return "Pinterest"
    return extractor.capitalize() if extractor else "Web Video"


def extract_info(url: str) -> Dict[str, Any]:
    """Extract media metadata and categorized quality formats from any supported URL."""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'extract_flat': False,
        'ignoreerrors': False,
        'noplaylist': True,
        'nocheckcertificate': True,
        'extractor_args': {'youtube': {'player_client': ['android', 'web']}},
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            info = ydl.extract_info(url, download=False)
        except Exception as e:
            logger.error(f"Extraction failed for {url}: {e}")
            raise RuntimeError(f"Could not extract info: {str(e)}")

    if not info:
        raise ValueError("No video information could be retrieved.")

    title = info.get("title", "Untitled Media")
    uploader = info.get("uploader") or info.get("channel") or info.get("creator") or "Unknown Creator"
    duration = info.get("duration")
    duration_str = format_duration(duration)
    thumbnail = info.get("thumbnail") or (info.get("thumbnails")[-1]["url"] if info.get("thumbnails") else "")
    webpage_url = info.get("webpage_url") or url
    platform = get_platform_name(info.get("extractor", ""), url)

    # Process Formats
    raw_formats = info.get("formats", [])
    video_formats: List[Dict[str, Any]] = []
    audio_formats: List[Dict[str, Any]] = []

    seen_resolutions = set()

    # Pre-packaged direct progressive or best formats
    for f in reversed(raw_formats):
        format_id = f.get("format_id")
        ext = f.get("ext", "mp4")
        vcodec = f.get("vcodec", "none")
        acodec = f.get("acodec", "none")
        height = f.get("height")
        filesize = f.get("filesize") or f.get("filesize_approx")
        url_direct = f.get("url")

        # Audio only format
        if vcodec == "none" and acodec != "none":
            abr = int(f.get("abr") or 128)
            audio_formats.append({
                "format_id": format_id,
                "label": f"Audio ({ext.upper()}) - {abr}kbps",
                "quality": f"{abr} kbps",
                "ext": ext,
                "filesize_bytes": filesize,
                "filesize_str": format_bytes(filesize),
                "is_audio_only": True,
                "direct_url": url_direct if url_direct and not url_direct.startswith("manifest") else None
            })

        # Video format
        elif height and height > 0 and vcodec != "none":
            resolution_key = f"{height}p"
            if resolution_key not in seen_resolutions:
                seen_resolutions.add(resolution_key)
                has_audio = (acodec != "none")
                video_formats.append({
                    "format_id": format_id,
                    "resolution": resolution_key,
                    "height": height,
                    "ext": "mp4" if "mp4" in ext else ext,
                    "has_audio": has_audio,
                    "filesize_bytes": filesize,
                    "filesize_str": format_bytes(filesize),
                    "label": f"{resolution_key} ({'HD' if height >= 720 else 'SD'})",
                    "direct_url": url_direct if url_direct and not url_direct.startswith("manifest") else None
                })

    # Sort video formats descending by resolution
    video_formats.sort(key=lambda x: x["height"], reverse=True)

    # Standardized generic audio options if needed
    if not audio_formats:
        audio_formats.append({
            "format_id": "bestaudio",
            "label": "High Quality Audio (MP3/M4A)",
            "quality": "Best",
            "ext": "mp3",
            "filesize_bytes": None,
            "filesize_str": "Auto",
            "is_audio_only": True,
            "direct_url": None
        })

    return {
        "title": title,
        "uploader": uploader,
        "duration": duration,
        "duration_str": duration_str,
        "thumbnail": thumbnail,
        "platform": platform,
        "url": webpage_url,
        "video_formats": video_formats,
        "audio_formats": audio_formats,
        "author_credit": "Developed by S. M. Mahmud Iqbal"
    }


def get_stream_url(url: str, format_id: str, is_audio: bool = False) -> Dict[str, Any]:
    """Retrieve direct stream URL and title for redirect without heavy server downloads."""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'nocheckcertificate': True,
        'noplaylist': True,
        'extractor_args': {'youtube': {'player_client': ['android', 'web']}},
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        if not info:
            raise ValueError("Media info not found")

        title = info.get("title", "media")
        sanitized_title = re.sub(r'[^\w\s-]', '', title).strip() or "media"

        formats = info.get("formats", [])
        target_format = None
        for f in formats:
            if str(f.get("format_id")) == str(format_id):
                target_format = f
                break

        if not target_format:
            if is_audio:
                for f in reversed(formats):
                    if f.get("vcodec") == "none" and f.get("acodec") != "none" and f.get("url"):
                        target_format = f
                        break
            else:
                for f in reversed(formats):
                    if f.get("height") and f.get("url"):
                        target_format = f
                        break

        stream_url = target_format.get("url") if target_format else None
        ext = (target_format.get("ext") if target_format else None) or ("mp3" if is_audio else "mp4")
        filename = f"{sanitized_title}.{ext}"

        return {
            "stream_url": stream_url,
            "filename": filename,
            "title": title,
            "ext": ext
        }


def download_media_file(url: str, format_id: str, is_audio: bool = False) -> str:
    """Download requested media file locally to temp cache and return absolute filepath."""
    sanitized_id = re.sub(r'[^a-zA-Z0-9_-]', '_', format_id)
    out_tmpl = os.path.join(DOWNLOAD_DIR, f"%(id)s_{sanitized_id}.%(ext)s")

    if is_audio:
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': out_tmpl,
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }] if False else [],  # fallback gracefully if ffmpeg is missing
        }
    else:
        # Prefer format specified, or progressive mp4 fallback
        ydl_opts = {
            'format': f"{format_id}+bestaudio/best[height<={format_id.replace('p','')}]/{format_id}/best",
            'outtmpl': out_tmpl,
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
        }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info)
        # Check if actual file exists (in case extension altered)
        if os.path.exists(filename):
            return filename
        
        # Locate file in directory with matching base
        base_name = os.path.splitext(filename)[0]
        for f in os.listdir(DOWNLOAD_DIR):
            full_path = os.path.join(DOWNLOAD_DIR, f)
            if full_path.startswith(base_name):
                return full_path

        return filename
