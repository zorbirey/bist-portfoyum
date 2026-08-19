import json
import re
from datetime import datetime, timezone

import requests
from bs4 import BeautifulSoup

URL = "https://borsa.doviz.com/temettu-ve-sermaye-artirimi-takvimi"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151 Safari/537.36"
}


def tr_number(text: str) -> float:
    s = (text or "").strip().replace("\xa0", " ")
    s = re.sub(r"[^0-9,.-]", "", s)
    if not s:
        return 0.0
    if "," in s and "." in s:
        if s.rfind(",") > s.rfind("."):
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(",", "")
    elif "," in s:
        s = s.replace(".", "").replace(",", ".")
    return float(s) if s not in {"", "-", "."} else 0.0


def main():
    r = requests.get(URL, headers=HEADERS, timeout=30)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")

    rows = []
    seen = set()
    for tr in soup.find_all("tr"):
        cells = [c.get_text(" ", strip=True) for c in tr.find_all(["td", "th"])]
        if len(cells) < 6:
            continue
        first = cells[0].strip()
        m = re.match(r"^([A-Z0-9]{3,8})\b(?:\s+(.*))?$", first)
        if not m:
            continue
        code = m.group(1)
        name = (m.group(2) or "").strip()

        # Sayfadaki tabloda son sütun dağıtım tarihi, brüt/net sütunları ortadadır.
        date_text = next((c.strip() for c in reversed(cells) if re.fullmatch(r"\d{2}\.\d{2}\.\d{4}", c.strip())), None)
        if not date_text:
            continue

        money_cells = [c for c in cells[1:] if "₺" in c or "TL" in c.upper()]
        # Web tablosu: toplam tutar, pay başına brüt, pay başına net.
        if len(money_cells) < 3:
            continue
        gross = tr_number(money_cells[-2])
        source_net = tr_number(money_cells[-1])
        if gross <= 0:
            continue

        # Kullanıcının istediği sabit %15 stopaj kuralı.
        net = round(gross * 0.85, 6)
        key = (code, date_text, gross)
        if key in seen:
            continue
        seen.add(key)
        rows.append({
            "code": code,
            "name": name,
            "date": date_text,
            "grossPerShare": gross,
            "netPerShare": net,
            "sourceNetPerShare": source_net,
            "withholdingRate": 15,
            "source": "Doviz.com / halka açık temettü takvimi"
        })

    if not rows:
        raise RuntimeError("Temettü takviminden veri okunamadı")

    rows.sort(key=lambda x: datetime.strptime(x["date"], "%d.%m.%Y"))
    payload = {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "year": datetime.now().year,
        "source": "Doviz.com temettü takvimi",
        "count": len(rows),
        "dividends": rows,
    }
    with open("dividends.json", "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"{len(rows)} temettü kaydı güncellendi")


if __name__ == "__main__":
    main()
