import json
import re
from datetime import datetime, timezone
from urllib.parse import urlparse

import requests
from bs4 import BeautifulSoup

URL = "https://finans.mynet.com/borsa/hisseler/"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151 Safari/537.36"
}


def tr_number(text: str) -> float:
    text = (text or "").strip().replace("\xa0", " ")
    text = text.replace(".", "").replace(",", ".")
    text = re.sub(r"[^0-9.\-]", "", text)
    return float(text) if text not in {"", "-", "."} else 0.0


def code_from_row(tr, first_text: str):
    # Önce görünür ilk hücreden oku: "TUPRS TUPRAS" -> TUPRS
    m = re.match(r"^([A-Z0-9]{3,8})\b", first_text or "")
    if m:
        return m.group(1), (first_text[m.end():].strip(" -–—|/") or "")

    # Bazı öne çıkarılmış satırlarda ilk hücre yapısı farklı olabiliyor.
    # Linkten /hisseler/tuprs-tupras/ -> TUPRS, TUPRAS çıkar.
    for a in tr.find_all("a", href=True):
        href = a.get("href", "")
        mm = re.search(r"/borsa/hisseler/([a-z0-9]{3,8})-([^/?#]+)/?", href, re.I)
        if mm:
            code = mm.group(1).upper()
            name = (a.get_text(" ", strip=True) or mm.group(2).replace("-", " ")).strip()
            # Link metni bazen kodu da içerir.
            name = re.sub(rf"^{re.escape(code)}\s+", "", name, flags=re.I).strip()
            return code, name.upper()
    return None, ""


def main():
    r = requests.get(URL, headers=HEADERS, timeout=30)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")

    prices = {}
    for tr in soup.find_all("tr"):
        cells = [c.get_text(" ", strip=True) for c in tr.find_all(["td", "th"])]
        if len(cells) < 4:
            continue

        first = cells[0].strip()
        code, company_name = code_from_row(tr, first)
        if not code:
            continue

        price = None
        change_pct = None
        time_text = None

        for cell in cells[1:]:
            raw = cell.strip()
            if not raw:
                continue
            if re.fullmatch(r"\d{1,2}:\d{2}", raw):
                time_text = raw
                continue
            if not re.search(r"\d", raw):
                continue
            value = tr_number(raw)
            if price is None:
                price = value
                continue
            if change_pct is None and ('%' in raw or abs(value) <= 100):
                change_pct = value

        if price is None or price <= 0:
            continue

        old = prices.get(code)
        row = {
            "name": company_name,
            "price": price,
            "changePct": change_pct,
            "marketTime": time_text,
            "source": "Mynet Finans"
        }
        # Aynı kod birden fazla görünürse adı dolu ve saati olan kaydı tercih et.
        if not old or (row["name"] and not old.get("name")) or (row["marketTime"] and not old.get("marketTime")):
            prices[code] = row

    if not prices:
        raise RuntimeError("Mynet fiyat tablosundan veri okunamadı")

    payload = {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "source": "Mynet Finans",
        "count": len(prices),
        "prices": prices,
    }

    with open("prices.json", "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"{len(prices)} hisse ve şirket adı güncellendi")
    print("TUPRS bulundu:", "TUPRS" in prices, prices.get("TUPRS"))


if __name__ == "__main__":
    main()
