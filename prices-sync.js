let bistPriceMap = {};
let dividendFeed = [];
let dividendFeedMeta = {};

window.cleanMoney = cleanMoney = function(value) {
  let s = String(value ?? '').trim().replace(/\s/g, '').replace(/[^0-9,.-]/g, '');
  if (!s) return 0;
  const neg = s.startsWith('-');
  s = s.replace(/-/g, '');
  const c = s.lastIndexOf(',');
  const d = s.lastIndexOf('.');
  let normalized;
  if (c >= 0 && d >= 0) {
    normalized = c > d ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  } else if (c >= 0) {
    const decimals = s.length - c - 1;
    normalized = decimals >= 1 && decimals <= 2 ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  } else if (d >= 0) {
    const decimals = s.length - d - 1;
    normalized = decimals >= 1 && decimals <= 2 ? s.replace(/,/g, '') : s.replace(/\./g, '');
  } else normalized = s;
  const n = Number(normalized);
  return Number.isFinite(n) ? (neg ? -n : n) : 0;
};

function rawPortfolioCost() {
  return stocks.reduce((sum, s) => sum + (Number(s.qty)||0) * (Number(s.cost)||0), 0);
}
function currentPortfolioValue() {
  return stocks.reduce((sum, s) => sum + (Number(s.qty)||0) * (Number(s.price)||0), 0);
}
function portfolioNeedsScaleRepair() {
  const raw = rawPortfolioCost();
  const value = currentPortfolioValue();
  return raw > 5_000_000 && value > 0 && raw > value * 10;
}
function effectiveCost(s) {
  const c = Number(s.cost) || 0;
  return portfolioNeedsScaleRepair() ? c / 100 : c;
}
function persistScaleRepairIfNeeded() {
  if (!portfolioNeedsScaleRepair()) return false;
  stocks.forEach(s => { s.cost = (Number(s.cost)||0) / 100; });
  save();
  localStorage.setItem('costRepairV4', new Date().toISOString());
  return true;
}

async function loadBistMap() {
  try {
    const res = await fetch('./prices.json?ts=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) throw new Error('prices.json alınamadı');
    const data = await res.json();
    bistPriceMap = data.prices || {};
    return data;
  } catch (err) {
    console.error('BIST kod listesi alınamadı:', err);
    return null;
  }
}

async function loadDividendFeed() {
  try {
    const res = await fetch('./dividends.json?ts=' + Date.now(), {cache:'no-store'});
    if (!res.ok) throw new Error('dividends.json alınamadı');
    const data = await res.json();
    dividendFeed = Array.isArray(data.dividends) ? data.dividends : [];
    dividendFeedMeta = data;
    return data;
  } catch (e) {
    console.warn('Temettü verisi henüz hazır değil:', e);
    dividendFeed = [];
    return null;
  }
}

async function syncMynetPrices(showStatus = false) {
  if (!Array.isArray(stocks) || stocks.length === 0) return;
  try {
    const data = await loadBistMap();
    if (!data) throw new Error('prices.json alınamadı');
    let updated = 0;
    stocks.forEach(stock => {
      const row = bistPriceMap[String(stock.code || '').toUpperCase()];
      if (row && Number(row.price) > 0) {
        stock.price = Number(row.price);
        stock.changePct = row.changePct == null ? null : Number(row.changePct);
        stock.marketTime = row.marketTime || '';
        stock.priceSource = row.source || data.source || 'Mynet Finans';
        if (row.name) stock.name = row.name;
        updated++;
      }
    });
    persistScaleRepairIfNeeded();
    save();
    localStorage.setItem('priceFeedUpdatedAt', data.updatedAt || '');
    render();
    if (showStatus) alert(updated + ' portföy hissesi güncellendi.');
  } catch (err) {
    console.error('Mynet fiyat senkronizasyonu başarısız:', err);
    if (showStatus) alert('Fiyat verisi şu anda alınamadı. Son kayıtlı fiyatlar gösteriliyor.');
  }
}
window.refreshPrices = () => syncMynetPrices(true);

function normalizeBistCode(value) {
  return String(value || '')
    .replace(/ç/gi, 'C').replace(/ğ/gi, 'G').replace(/ı/gi, 'I')
    .replace(/ö/gi, 'O').replace(/ş/gi, 'S').replace(/ü/gi, 'U')
    .toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8);
}
async function validateCodeElement(el) {
  if (!el) return false;
  const normalized = normalizeBistCode(el.value);
  if (el.value !== normalized) el.value = normalized;
  const feedback = document.getElementById('codeFeedback');
  const nameInput = document.getElementById('name');
  const addBtn = document.getElementById('addStockBtn');
  if (!normalized) {
    if (feedback) { feedback.textContent='BIST kodunu gir.'; feedback.style.color='var(--muted)'; }
    if (nameInput) nameInput.value=''; if(addBtn)addBtn.disabled=true; return false;
  }
  if (!Object.keys(bistPriceMap).length) await loadBistMap();
  const row = bistPriceMap[normalized];
  if (row) {
    if(nameInput)nameInput.value=row.name||'';
    if(feedback){feedback.textContent='✓ '+(row.name||'Geçerli BIST kodu');feedback.style.color='var(--green)';}
    if(addBtn)addBtn.disabled=false; return true;
  }
  if(nameInput)nameInput.value='';
  if(feedback){feedback.textContent="BIST'te bu hisse kodu bulunamadı.";feedback.style.color='var(--red)';}
  if(addBtn)addBtn.disabled=true; return false;
}
document.addEventListener('input', e=>{if(e.target?.id==='code'){e.target.value=normalizeBistCode(e.target.value);validateCodeElement(e.target);}});
document.addEventListener('paste', e=>{if(e.target?.id==='code')setTimeout(()=>validateCodeElement(e.target),0);});

window.editStock = function(i) {
  const s=stocks[i]; if(!s)return;
  const qty=prompt(s.code+' için yeni hisse adedini gir:',String(s.qty).replace('.',',')); if(qty===null)return;
  const cost=prompt(s.code+' için yeni ortalama maliyeti gir:',String(effectiveCost(s)).replace('.',',')); if(cost===null)return;
  const q=cleanMoney(qty), c=cleanMoney(cost);
  if(q<=0||c<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');
  s.qty=q;s.cost=c;save();render();
};
window.addStock = addStock = async function() {
  if(stocks.length>=10)return alert('En fazla 10 hisse eklenebilir.');
  const code=normalizeBistCode(document.getElementById('code')?.value||''); if(!code)return alert('BIST kodunu gir.');
  if(!Object.keys(bistPriceMap).length)await loadBistMap(); const row=bistPriceMap[code];
  if(!row)return alert("BIST'te bu hisse kodu bulunamadı. Lütfen kodu kontrol et.");
  if(stocks.some(s=>String(s.code).toUpperCase()===code))return alert('Bu hisse zaten portföyde.');
  const qty=cleanMoney(document.getElementById('qty').value),cost=cleanMoney(document.getElementById('cost').value);
  if(qty<=0||cost<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');
  stocks.push({code,name:row.name||'',qty,cost,price:Number(row.price)||0,changePct:row.changePct==null?null:Number(row.changePct),marketTime:row.marketTime||''});
  save();render();
};

window.totals = totals = function() {
  let cost=0,val=0,daily=0;
  stocks.forEach(s=>{
    const q=Number(s.qty)||0,c=effectiveCost(s),p=Number(s.price)||0;
    cost+=q*c;if(p>0)val+=q*p;
    if(p>0&&Number.isFinite(Number(s.changePct))){const pct=Number(s.changePct);const prev=p/(1+pct/100);if(prev>0&&Number.isFinite(prev))daily+=(p-prev)*q;}
  });
  return {cost,val,pnl:val-cost,daily};
};
window.portfolio = portfolio = function() {
  const t=totals(); const priced=stocks.filter(s=>Number(s.price)>0);
  const pricedCost=priced.reduce((a,s)=>a+(Number(s.qty)||0)*effectiveCost(s),0); const pnl=priced.length?t.val-pricedCost:0;
  return `<div class="page"><div class="cards">
  <div class="card"><div class="label">TOPLAM PORTFÖY DEĞERİ</div><div class="value">${priced.length?fmt(t.val)+' ₺':'—'}</div></div>
  <div class="card"><div class="label">KÂR / ZARAR</div><div class="value ${pnl>=0?'green':'red'}">${priced.length?(pnl>=0?'+':'')+fmt(pnl)+' ₺':'—'}</div></div>
  <div class="card"><div class="label">MALİYET TUTARI</div><div class="value">${fmt(t.cost)} ₺</div></div>
  <div class="card"><div class="label">GÜNLÜK KÂR / ZARAR</div><div class="value ${t.daily>=0?'green':'red'}">${priced.length?(t.daily>=0?'+':'')+fmt(t.daily)+' ₺':'—'}</div></div></div>
  <div class="section">Portföyüm</div>${stocks.length?stocks.map(s=>{const q=Number(s.qty)||0,c=effectiveCost(s),p=Number(s.price)||0,tc=q*c,cv=p>0?q*p:0,k=p>0?cv-tc:null,profit=k!==null&&k>=0;return `<div class="panel stock"><div><div class="ticker">${s.code}</div><div class="small">${s.name||''}</div><div class="small">${fmt(q)} adet · Ort. maliyet ${fmt(c)} ₺</div><div class="small">Toplam maliyet: <b>${fmt(tc)} ₺</b></div></div><div class="mobilehide"><div class="small">GÜNCEL FİYAT</div><b>${p>0?fmt(p)+' ₺':'Veri bekleniyor'}</b><div class="small">Güncel değer: <b>${p>0?fmt(cv)+' ₺':'—'}</b></div></div><div class="right"><div class="small">${k===null?'KÂR / ZARAR':profit?'KÂR':'ZARAR'}</div><b class="${k===null?'':profit?'green':'red'}">${k===null?'—':(profit?'+':'')+fmt(k)+' ₺'}</b></div></div>`}).join(''):'<div class="panel empty">Portföyünde henüz hisse yok.</div>'}</div>`;
};

function parseTRDate(s){const [d,m,y]=String(s||'').split('.').map(Number);return new Date(y,m-1,d);}
function portfolioDividendRows(){
  const year=new Date().getFullYear(); const codes=new Set(stocks.map(s=>String(s.code).toUpperCase()));
  return dividendFeed.filter(d=>codes.has(String(d.code).toUpperCase())&&parseTRDate(d.date).getFullYear()===year).map(d=>{
    const stock=stocks.find(s=>String(s.code).toUpperCase()===String(d.code).toUpperCase()); const qty=Number(stock?.qty)||0;
    const grossPS=Number(d.grossPerShare)||0, netPS=grossPS*.85; const gross=grossPS*qty,net=netPS*qty;
    const paid=parseTRDate(d.date)<new Date(new Date().getFullYear(),new Date().getMonth(),new Date().getDate());
    return {...d,qty,grossPS,netPS,gross,net,paid,stock};
  }).sort((a,b)=>(a.paid===b.paid?parseTRDate(a.date)-parseTRDate(b.date):a.paid?-1:1));
}
function dividendStats(){const rows=portfolioDividendRows();return {rows,forecast:rows.reduce((a,r)=>a+r.net,0),paid:rows.filter(r=>r.paid).reduce((a,r)=>a+r.net,0)};}
window.divTotal = divTotal = function(){return dividendStats().forecast;};
window.dividend = dividend = function(){
  const y=new Date().getFullYear(),st=dividendStats(),monthly=Number(monthlyTarget)||0,ratio=monthly?((st.forecast/12)/monthly)*100:0;
  const undo=localStorage.getItem('dividendUndo');
  return `<div class="page"><div class="cards">
    <div class="card"><div class="label">${y} NET ÖNGÖRÜLEN TEMETTÜ</div><div class="value">${fmt(st.forecast)} ₺</div></div>
    <div class="card"><div class="label">${y} ÖDENEN NET TEMETTÜ</div><div class="value">${fmt(st.paid)} ₺</div></div>
    <div class="card"><div class="label">HEDEFLENEN AYLIK TEMETTÜ GELİRİ</div><div class="value">${fmt(monthly)} ₺</div></div>
    <div class="card"><div class="label">AYLIK HEDEFE ULAŞMA</div><div class="value ${ratio>=100?'green':'red'}">%${fmt(ratio)}</div></div>
  </div>${undo?'<div class="btnrow"><button onclick="undoDividendReinvest()">↶ SON TEMETTÜ EKLEMESİNİ GERİ AL</button></div>':''}
  <div class="section">Net Temettü Geliri · ${y}</div>
  ${!dividendFeed.length?'<div class="panel empty">Temettü veri dosyası hazırlanıyor. Bir sonraki veri güncellemesinde otomatik dolacak.</div>':!st.rows.length?'<div class="panel empty">Portföyündeki hisseler için bu takvim yılında açıklanmış temettü kaydı bulunamadı.</div>':st.rows.map((r,i)=>`<div class="panel"><div style="display:flex;justify-content:space-between;gap:12px;align-items:start"><div><div class="ticker">${r.code}</div><div class="small">${r.name||r.stock?.name||''}</div><div class="small">Ödeme tarihi: ${r.date}</div></div><div class="right"><span class="badge ${r.paid?'paid':'pending'}">${r.paid?'ÖDENDİ':'BEKLEYEN'}</span><div style="font-size:20px;font-weight:900;margin-top:8px">${fmt(r.netPS)} ₺ <span class="small">/ hisse net</span></div></div></div><div style="margin-top:12px"><div class="small">Brüt: ${fmt(r.gross)} ₺ · %15 stopaj: ${fmt(r.gross-r.net)} ₺</div><div style="font-size:19px;font-weight:900;margin-top:3px">Net ${r.paid?'ödenen':'ödenecek'}: ${fmt(r.net)} ₺</div></div>${r.paid&&Number(r.stock?.price)>0?`<div class="btnrow"><button onclick="reinvestDividend('${r.code}','${r.date}',${r.net})">TEMETTÜYÜ HİSSEYE EKLE</button></div>`:''}</div>`).join('')}</div>`;
};
window.reinvestDividend=function(code,date,net){const idx=stocks.findIndex(s=>String(s.code).toUpperCase()===code);if(idx<0)return;const s=stocks[idx],p=Number(s.price)||0;if(p<=0)return alert('Güncel fiyat bulunamadı.');const shares=Math.ceil(Number(net)/p);if(shares<=0)return;const msg=`${fmt(net)} ₺ net temettü, ${fmt(p)} ₺ güncel fiyatla ${shares} adet ${code} hissesine yuvarlanacak. Portföye eklensin mi?`;if(!confirm(msg))return;localStorage.setItem('dividendUndo',JSON.stringify({idx,qty:s.qty,cost:s.cost,code,date}));const oldQty=Number(s.qty)||0,oldCost=effectiveCost(s);const newQty=oldQty+shares;s.cost=((oldQty*oldCost)+(shares*p))/newQty;s.qty=newQty;save();render();};
window.undoDividendReinvest=function(){try{const u=JSON.parse(localStorage.getItem('dividendUndo')||'null');if(!u||!stocks[u.idx])return;stocks[u.idx].qty=u.qty;stocks[u.idx].cost=u.cost;save();localStorage.removeItem('dividendUndo');render();}catch(e){localStorage.removeItem('dividendUndo');}};

window.settings = settings = function() {
  return `<div class="page"><div class="section">Portföy Düzenle</div><div class="panel"><div class="formgrid"><div><input id="code" autocomplete="off" autocapitalize="characters" maxlength="8" placeholder="BIST kodu (örn. TUPRS)"><div id="codeFeedback" class="small" style="margin:6px 2px 0">Küçük harfler otomatik büyük harfe çevrilir.</div></div><input id="name" placeholder="Şirket adı otomatik gelecek" readonly><input id="qty" inputmode="decimal" placeholder="Hisse adedi"><input id="cost" inputmode="decimal" placeholder="Ortalama maliyet"></div><div class="btnrow"><button id="addStockBtn" onclick="addStock()" disabled>HİSSE EKLE</button><button onclick="refreshPrices()">FİYATLARI YENİLE</button></div></div>${stocks.map((s,i)=>`<div class="panel stock"><div><b>${s.code}</b><div class="small">${s.name||''} · ${fmt(s.qty)} adet · ${s.price?fmt(s.price)+' ₺':'fiyat bekleniyor'}</div></div><div class="right"><div style="display:flex;flex-direction:column;gap:7px"><button onclick="removeStock(${i})">SİL</button><button onclick="editStock(${i})">✏️ DÜZENLE</button></div></div></div>`).join('')}<div class="section">Hedef Ayarı</div><div class="panel"><div class="label">AYLIK NET TEMETTÜ HEDEFİ</div><input id="monthly" inputmode="numeric" value="${moneyInput(monthlyTarget)}" oninput="formatTarget(this)" onblur="monthlyTarget=cleanMoney(this.value);save();render()"></div></div>`;
};

window.addEventListener('load', async()=>{
  await Promise.all([loadBistMap(),loadDividendFeed()]);
  syncMynetPrices(false);
  persistScaleRepairIfNeeded();
  render();
  setInterval(()=>syncMynetPrices(false),15*60*1000);
  setInterval(()=>loadDividendFeed().then(()=>render()),60*60*1000);
});
