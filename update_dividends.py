import json
import re
from datetime import datetime, timezone

import requests
from bs4 import BeautifulSoup

FUTURE_URL = "https://borsa.doviz.com/temettu-ve-sermaye-artirimi-takvimi"
HISTORY_URL = "https://www.temettuhisseleri.net/temettu-takvimi/"
HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151 Safari/537.36"}

MONTHS = {"ocak":1,"şubat":2,"subat":2,"mart":3,"nisan":4,"mayıs":5,"mayis":5,"haziran":6,"temmuz":7,"ağustos":8,"agustos":8,"eylül":9,"eylul":9,"ekim":10,"kasım":11,"kasim":11,"aralık":12,"aralik":12}

def tr_number(text):
    s=(text or "").strip().replace("\xa0"," ")
    s=re.sub(r"[^0-9,.-]","",s)
    if not s: return 0.0
    if "," in s and "." in s:
        s=s.replace(".","").replace(",",".") if s.rfind(",")>s.rfind(".") else s.replace(",","")
    elif "," in s: s=s.replace(".","").replace(",",".")
    try: return float(s)
    except: return 0.0

def normalize_date(text):
    t=(text or "").strip().lower()
    if re.fullmatch(r"\d{2}\.\d{2}\.\d{4}",t): return t
    m=re.search(r"(\d{1,2})\s+([a-zçğıöşü]+)\s+(\d{4})",t)
    if m and m.group(2) in MONTHS:
        return f"{int(m.group(1)):02d}.{MONTHS[m.group(2)]:02d}.{m.group(3)}"
    return None

def add_row(rows, seen, code, name, date_text, gross, source_net, source):
    if not code or not date_text: return
    if not gross and source_net: gross=source_net/0.85
    if not source_net and gross: source_net=gross*0.85
    if gross<=0: return
    net=round(gross*0.85,6)
    key=(code,date_text,round(gross,5))
    if key in seen: return
    seen.add(key)
    rows.append({"code":code,"name":name,"date":date_text,"grossPerShare":round(gross,6),"netPerShare":net,"sourceNetPerShare":round(source_net or net,6),"withholdingRate":15,"source":source})

def parse_future(rows, seen):
    r=requests.get(FUTURE_URL,headers=HEADERS,timeout=30); r.raise_for_status(); soup=BeautifulSoup(r.text,"html.parser")
    for tr in soup.find_all("tr"):
        cells=[c.get_text(" ",strip=True) for c in tr.find_all(["td","th"])]
        if len(cells)<6: continue
        m=re.match(r"^([A-Z0-9]{3,8})\b(?:\s+(.*))?$",cells[0].strip())
        if not m: continue
        date_text=next((normalize_date(c) for c in reversed(cells) if normalize_date(c)),None)
        money=[c for c in cells[1:] if "₺" in c or "TL" in c.upper()]
        if not date_text or len(money)<3: continue
        add_row(rows,seen,m.group(1),(m.group(2) or "").strip(),date_text,tr_number(money[-2]),tr_number(money[-1]),"Doviz.com temettü takvimi")

def parse_history(rows, seen):
    r=requests.get(HISTORY_URL,headers=HEADERS,timeout=30); r.raise_for_status(); soup=BeautifulSoup(r.text,"html.parser")
    for tr in soup.find_all("tr"):
        cells=[c.get_text(" ",strip=True) for c in tr.find_all(["td","th"])]
        if len(cells)<4: continue
        first=cells[0].strip(); m=re.match(r"^([A-Z0-9]{3,8})\b",first)
        if not m: continue
        date_text=next((normalize_date(c) for c in cells if normalize_date(c)),None)
        if not date_text or not date_text.endswith("2026"): continue
        # Kaynak tabloda son sütun hisse başı net temettü.
        net=tr_number(cells[-1])
        if net<=0: continue
        name=cells[1].strip() if len(cells)>1 else first[m.end():].strip()
        add_row(rows,seen,m.group(1),name,date_text,net/0.85,net,"Temettuhisseleri.net 2026 geçmiş takvimi")

def main():
    rows=[]; seen=set()
    errors=[]
    for fn in (parse_history,parse_future):
        try: fn(rows,seen)
        except Exception as e: errors.append(str(e))
    if not rows: raise RuntimeError("Temettü kaynaklarından veri okunamadı: "+" | ".join(errors))
    rows=[x for x in rows if x["date"].endswith("2026")]
    rows.sort(key=lambda x: datetime.strptime(x["date"],"%d.%m.%Y"))
    payload={"updatedAt":datetime.now(timezone.utc).isoformat(),"year":2026,"source":"Geçmiş + gelecek temettü takvimi","count":len(rows),"dividends":rows}
    with open("dividends.json","w",encoding="utf-8") as f: json.dump(payload,f,ensure_ascii=False,indent=2)
    print(f"{len(rows)} temettü kaydı güncellendi")
    if errors: print("Uyarılar:",errors)

if __name__=="__main__": main()
