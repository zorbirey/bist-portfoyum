import json
import re
from datetime import datetime, timezone

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
        m = re.match(r"^([A-Z0-9]{3,6})\b", first)
        if not m:
            continue

        code = m.group(1)
        company_name = first[m.end():].strip(" -–—|/")
        price = None
        change_pct = None
        time_text = None

        for cell in cells[1:]:
            if price is None and re.fullmatch(r"[0-9.]+,[0-9]+", cell.strip()):
                price = tr_number(cell)
                continue
            if price is not None and change_pct is None and re.fullmatch(r"-?[0-9.]+,[0-9]+", cell.strip()):
                change_pct = tr_number(cell)
                continue
            if re.fullmatch(r"\d{1,2}:\d{2}", cell.strip()):
                time_text = cell.strip()

        if price is None:
            continue

        prices[code] = {
            "name": company_name,
            "price": price,
            "changePct": change_pct,
            "marketTime": time_text,
            "source": "Mynet Finans"
        }

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


if __name__ == "__main__":
    main()
