#!/usr/bin/env python3
"""
Collect ShowBook live & scenario network logs and generate AppStubData mock fixtures
for Empty, Negative, and Positive scenarios across all Open Library, First.org, and IP-API endpoints.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
SHOWBOOK_LOGS_DIR = ROOT_DIR / "ShowBook" / "Logs"
DEV_STUBS_DIR = ROOT_DIR / "DevOps" / "AppStubData" / "Sources" / "AppStubData" / "Resources"
LOCAL_MOCK_DIR = ROOT_DIR / "ShowBook" / "TestSupport" / "MockData"

SHOWBOOK_LOGS_DIR.mkdir(parents=True, exist_ok=True)
DEV_STUBS_DIR.mkdir(parents=True, exist_ok=True)
LOCAL_MOCK_DIR.mkdir(parents=True, exist_ok=True)

USER_AGENT = "ShowBook (anuragchourasia1999@gmail.com)"

log_entries = []

def record_http_log(method, url, status, duration_ms, request_headers, response_headers, body_str, is_error=False, error_msg=None):
    req_id = str(uuid.uuid4()).upper()
    req_header_str = "\n".join(f"  {k}: {v}" for k, v in request_headers.items())
    resp_header_str = "\n".join(f"  {k}: {v}" for k, v in response_headers.items()) if response_headers else "  <none>"

    log_part = f"""========== HTTP REQUEST ==========
Request ID: {req_id}
Method: {method}
URL: {url}
Headers:
{req_header_str}
Request Body:
<no request body>
=================================

"""
    if is_error:
        log_part += f"""========== HTTP ERROR ============
Request ID: {req_id}
Method: {method}
URL: {url}
Duration: {duration_ms:.2f} ms
Error: {error_msg or f'HTTP {status}'}
Response Body:
{body_str}
==================================

"""
    else:
        log_part += f"""========== HTTP RESPONSE =========
Request ID: {req_id}
Method: {method}
URL: {url}
Final URL: {url}
Status: {status}
Duration: {duration_ms:.2f} ms
Headers:
{resp_header_str}
Response Body:
{body_str}
==================================

"""
    log_entries.append(log_part)
    return req_id

def fetch_live_or_fallback(name, url, fallback_data, status_expected=200):
    print(f"Fetching live: {name} ({url})...")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            duration_ms = (time.time() - t0) * 1000
            raw = resp.read()
            text = raw.decode("utf-8", errors="replace")
            resp_headers = dict(resp.headers)
            record_http_log("GET", url, resp.status, duration_ms, {"User-Agent": USER_AGENT}, resp_headers, text)
            try:
                parsed = json.loads(text)
                return parsed
            except Exception:
                return fallback_data
    except urllib.error.HTTPError as e:
        duration_ms = (time.time() - t0) * 1000
        raw = e.read()
        text = raw.decode("utf-8", errors="replace")
        resp_headers = dict(e.headers)
        record_http_log("GET", url, e.code, duration_ms, {"User-Agent": USER_AGENT}, resp_headers, text, is_error=True, error_msg=f"HTTPError {e.code} ({e.reason})")
        try:
            return json.loads(text)
        except Exception:
            return fallback_data
    except Exception as e:
        duration_ms = (time.time() - t0) * 1000
        record_http_log("GET", url, 0, duration_ms, {"User-Agent": USER_AGENT}, {}, str(fallback_data), is_error=True, error_msg=f"Transport error: {str(e)}")
        return fallback_data

# ==========================================
# 1. POSITIVE SCENARIOS (Success payloads)
# ==========================================

# 1a. Search Positive
search_pos_live = fetch_live_or_fallback(
    "Search Positive",
    "https://openlibrary.org/search.json?title=The+Hobbit&limit=5&offset=0&fields=key,title,author_name,cover_i,ratings_average,ratings_count",
    fallback_data={
        "numFound": 1, "start": 0, "numFoundExact": True, "num_found": 1,
        "docs": [{
            "key": "/works/OL45804W",
            "title": "The Hobbit",
            "author_name": ["J.R.R. Tolkien"],
            "cover_i": 14627509,
            "ratings_average": 4.65,
            "ratings_count": 850
        }]
    }
)

# 1b. Discover Positive
discover_pos_live = fetch_live_or_fallback(
    "Discover Positive",
    "https://openlibrary.org/search.json?q=subject:fiction&limit=5&fields=key,title,author_name,cover_i,ratings_average,ratings_count",
    fallback_data={
        "numFound": 2, "start": 0, "numFoundExact": True, "num_found": 2,
        "docs": [
            {"key": "/works/OL45804W", "title": "Fantastic Mr Fox", "author_name": ["Roald Dahl"], "cover_i": 8739191, "ratings_average": 4.25, "ratings_count": 120},
            {"key": "/works/OL45805W", "title": "The Twits", "author_name": ["Roald Dahl"], "cover_i": 8739192, "ratings_average": 4.10, "ratings_count": 95}
        ]
    }
)

# 1c. Work Details Positive
work_pos_live = fetch_live_or_fallback(
    "Work Details Positive",
    "https://openlibrary.org/works/OL45804W.json",
    fallback_data={
        "key": "/works/OL45804W",
        "title": "Fantastic Mr Fox",
        "description": {"type": "/type/text", "value": "Boggis, Bunce and Bean are three greedy, smelly farmers who hate Fantastic Mr Fox."},
        "subjects": ["Animals", "Foxes", "Children's stories", "Humorous stories"],
        "covers": [8739191, 14627509],
        "first_publish_date": "1970"
    }
)

# 1d. Editions Positive
editions_pos_live = fetch_live_or_fallback(
    "Editions Positive",
    "https://openlibrary.org/works/OL45804W/editions.json?limit=5&offset=0",
    fallback_data={
        "links": {"self": "/works/OL45804W/editions.json?limit=5&offset=0", "work": "/works/OL45804W"},
        "size": 5,
        "entries": [
            {
                "key": "/books/OL7353617M",
                "title": "Fantastic Mr Fox (Puffin Books)",
                "publishers": ["Puffin Books", "Penguin"],
                "publish_date": "2000",
                "number_of_pages": 96,
                "isbn_10": ["0141301139"],
                "isbn_13": ["9780141301136"],
                "covers": [8739191]
            },
            {
                "key": "/books/OL1M",
                "title": "Fantastic Mr Fox (Collector Edition)",
                "publishers": ["Alfred A. Knopf"],
                "publish_date": "2002",
                "number_of_pages": 112,
                "covers": [14627509]
            }
        ]
    }
)

# 1e. Single Edition Positive
edition_pos_live = fetch_live_or_fallback(
    "Single Edition Positive",
    "https://openlibrary.org/books/OL7353617M.json",
    fallback_data={
        "key": "/books/OL7353617M",
        "title": "Fantastic Mr Fox",
        "publishers": ["Puffin Books"],
        "publish_date": "2000",
        "number_of_pages": 96,
        "isbn_10": ["0141301139"],
        "isbn_13": ["9780141301136"],
        "covers": [8739191]
    }
)

# 1f. Countries Positive
countries_pos_live = fetch_live_or_fallback(
    "Countries Positive",
    "https://api.first.org/data/v1/countries?limit=5",
    fallback_data={
        "status": "OK", "status-code": 200, "version": "1.0", "access": "public",
        "total": 249, "offset": 0, "limit": 5,
        "data": {
            "IN": {"country": "India", "region": "Asia"},
            "US": {"country": "United States", "region": "Americas"},
            "GB": {"country": "United Kingdom", "region": "Europe"},
            "AU": {"country": "Australia", "region": "Oceania"},
            "CA": {"country": "Canada", "region": "Americas"}
        }
    }
)

# 1g. IP Positive
ip_pos_live = fetch_live_or_fallback(
    "IP Positive",
    "http://ip-api.com/json",
    fallback_data={
        "status": "success", "country": "India", "countryCode": "IN",
        "region": "MH", "regionName": "Maharashtra", "city": "Mumbai",
        "zip": "400001", "lat": 18.9220, "lon": 72.8347, "timezone": "Asia/Kolkata",
        "isp": "Jio", "org": "Reliance Jio", "as": "AS55836", "query": "127.0.0.1"
    }
)


# ==========================================
# 2. EMPTY SCENARIOS (Zero results)
# ==========================================

search_empty = {
    "numFound": 0,
    "start": 0,
    "numFoundExact": True,
    "num_found": 0,
    "q": "nonexistent_query_xyz_99999",
    "offset": 0,
    "docs": []
}

discover_empty = {
    "numFound": 0,
    "start": 0,
    "numFoundExact": True,
    "num_found": 0,
    "q": "subject:nonexistent_subject_xyz",
    "offset": 0,
    "docs": []
}

work_empty = {
    "key": "/works/OL45804W",
    "title": "Minimal Title Only",
    "description": None,
    "subjects": [],
    "covers": []
}

editions_empty = {
    "size": 0,
    "entries": []
}

edition_empty = {
    "key": "/books/OL1M",
    "title": "Untitled Edition"
}

countries_empty = {
    "status": "OK",
    "status-code": 200,
    "version": "1.0",
    "access": "public",
    "total": 0,
    "offset": 0,
    "limit": 0,
    "data": {}
}

ip_empty = {
    "status": "success",
    "country": "",
    "countryCode": "",
    "region": "",
    "regionName": "",
    "city": "",
    "zip": "",
    "lat": 0,
    "lon": 0,
    "timezone": "",
    "isp": "",
    "org": "",
    "as": "",
    "query": "127.0.0.1"
}

# Record Empty scenario logs
for name, url, payload in [
    ("Search (Empty)", "https://openlibrary.org/search.json?title=nonexistent_xyz&limit=10&offset=0", search_empty),
    ("Discover (Empty)", "https://openlibrary.org/search.json?q=subject:nonexistent&limit=12", discover_empty),
    ("Work (Empty)", "https://openlibrary.org/works/OL45804W.json", work_empty),
    ("Editions (Empty)", "https://openlibrary.org/works/OL45804W/editions.json?limit=20&offset=0", editions_empty),
    ("Edition (Empty)", "https://openlibrary.org/books/OL1M.json", edition_empty),
    ("Countries (Empty)", "https://api.first.org/data/v1/countries", countries_empty),
    ("IP (Empty)", "http://ip-api.com/json", ip_empty),
]:
    record_http_log("GET", url, 200, 15.0, {"User-Agent": USER_AGENT}, {"Content-Type": "application/json"}, json.dumps(payload, indent=2))


# ==========================================
# 3. NEGATIVE SCENARIOS (Errors / Failures)
# ==========================================

search_negative = {
    "error": "bad_request",
    "message": "Invalid query parameters syntax error",
    "code": 400
}

discover_negative = {
    "error": "service_unavailable",
    "message": "Open Library subject discover search service currently unavailable",
    "code": 503
}

work_negative = {
    "error": "notfound",
    "key": "/works/OL0000000W",
    "message": "Work not found",
    "code": 404
}

editions_negative = {
    "error": "notfound",
    "message": "No editions available for specified key",
    "code": 404
}

edition_negative = {
    "error": "notfound",
    "key": "/books/OL0M",
    "message": "Book edition not found",
    "code": 404
}

countries_negative = {
    "status": "ERROR",
    "status-code": 500,
    "error": "Internal Server Error"
}

ip_negative = {
    "status": "fail",
    "message": "invalid query",
    "query": "invalid_ip"
}

# Record Negative scenario logs
for name, url, code, payload in [
    ("Search (Negative 400)", "https://openlibrary.org/search.json?invalid=true", 400, search_negative),
    ("Discover (Negative 503)", "https://openlibrary.org/search.json?q=subject:error", 503, discover_negative),
    ("Work (Negative 404)", "https://openlibrary.org/works/OL0000000W.json", 404, work_negative),
    ("Editions (Negative 404)", "https://openlibrary.org/works/OL0000000W/editions.json", 404, editions_negative),
    ("Edition (Negative 404)", "https://openlibrary.org/books/OL0M.json", 404, edition_negative),
    ("Countries (Negative 500)", "https://api.first.org/data/v1/countries", 500, countries_negative),
    ("IP (Negative Fail)", "http://ip-api.com/json/invalid_ip", 200, ip_negative),
]:
    record_http_log("GET", url, code, 45.0, {"User-Agent": USER_AGENT}, {"Content-Type": "application/json"}, json.dumps(payload, indent=2), is_error=True, error_msg=f"HTTP {code}")


# ==========================================
# 4. SAVE APPSTUBDATA & MOCK FIXTURES
# ==========================================

fixtures_map = {
    # Positive
    "showbook-search-positive": search_pos_live,
    "showbook-discover-positive": discover_pos_live,
    "showbook-work-positive": work_pos_live,
    "showbook-editions-positive": editions_pos_live,
    "showbook-edition-positive": edition_pos_live,
    "showbook-countries-positive": countries_pos_live,
    "showbook-ip-positive": ip_pos_live,

    # Empty
    "showbook-search-empty": search_empty,
    "showbook-discover-empty": discover_empty,
    "showbook-work-empty": work_empty,
    "showbook-editions-empty": editions_empty,
    "showbook-edition-empty": edition_empty,
    "showbook-countries-empty": countries_empty,
    "showbook-ip-empty": ip_empty,

    # Negative
    "showbook-search-negative": search_negative,
    "showbook-discover-negative": discover_negative,
    "showbook-work-negative": work_negative,
    "showbook-editions-negative": editions_negative,
    "showbook-edition-negative": edition_negative,
    "showbook-countries-negative": countries_negative,
    "showbook-ip-negative": ip_negative,
}

for name, data in fixtures_map.items():
    json_bytes = json.dumps(data, indent=2).encode("utf-8")
    for target_dir in [DEV_STUBS_DIR, LOCAL_MOCK_DIR]:
        target_path = target_dir / f"{name}.json"
        target_path.write_bytes(json_bytes)
        print(f"Saved fixture: {target_path}")

# Write log file
log_file = SHOWBOOK_LOGS_DIR / "network_scenarios.log"
log_file.write_text("".join(log_entries), encoding="utf-8")
print(f"\nSuccessfully wrote {len(log_entries)} HTTP log sessions to {log_file}")
