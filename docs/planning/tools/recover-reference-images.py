#!/usr/bin/env python3
"""Manual reference-only recovery; no Git upload, no automatic scheduling."""
import argparse, hashlib, json, pathlib, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

MANIFEST = pathlib.Path(__file__).resolve().parent.parent / "reference-images" / "manifest.json"
MAX_BYTES = 25 * 1024 * 1024

def image_type(data):
    if data.startswith(b"\xff\xd8\xff"): return ".jpg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"): return ".png"
    if data.startswith((b"GIF87a", b"GIF89a")): return ".gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP": return ".webp"
    if data[4:12] in (b"ftypavif", b"ftypavis"): return ".avif"
    raise ValueError("Response is not a recognized raster image")

def recover(entry, dest):
    result = {"id": entry["id"], "url": entry["url"], "source": entry.get("source"), "license": entry.get("license")}
    try:
        if not entry["url"].startswith("https://"): raise ValueError("HTTPS required")
        req = urllib.request.Request(entry["url"], headers={"User-Agent": "VOID-CARAVAN-reference-recovery/1.0", "Accept": "image/*"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read(MAX_BYTES + 1)
            mime = resp.headers.get_content_type()
            if len(data) > MAX_BYTES: raise ValueError("Image exceeds size limit")
            if not resp.geturl().startswith("https://"): raise ValueError("Non-HTTPS redirect")
            suffix = image_type(data)
        path = dest / (entry["id"] + suffix)
        path.write_bytes(data)
        result.update(status="downloaded", file=path.name, bytes=len(data), sha256=hashlib.sha256(data).hexdigest(), mime=mime)
    except Exception as exc:
        result.update(status="failed", error=str(exc))
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, default=pathlib.Path.home() / "VOID-CARAVAN-reference-images")
    args = parser.parse_args()
    dest = args.output.expanduser().resolve()
    repo = MANIFEST.parents[3]
    if dest == repo or repo in dest.parents: parser.error("Keep research downloads outside the public repository")
    dest.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    with ThreadPoolExecutor(max_workers=4) as pool:
        rows = list(pool.map(lambda e: recover(e, dest), manifest["entries"]))
    report = {"created_at": datetime.now(timezone.utc).isoformat(), "known_urls": len(rows), "downloaded": sum(r["status"] == "downloaded" for r in rows), "results": rows, "unresolved_chat_records": [e["id"] for e in manifest.get("chatExamples", []) if not e.get("url") and not e.get("localFile")]}
    (dest / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f'{report["downloaded"]}/{len(rows)} downloaded; report: {dest / "report.json"}')
    return 0 if report["downloaded"] == len(rows) else 1

if __name__ == "__main__":
    raise SystemExit(main())
