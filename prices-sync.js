let bistPriceMap = {};

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

async function syncMynetPrices(showStatus = false) {
  if (!Array.isArray(stocks) || stocks.length === 0) return;
  try {
    const data = await loadBistMap();
    if (!data) throw new Error('prices.json alınamadı');
    const map = data.prices || {};
    let updated = 0;
    stocks.forEach(stock => {
      const row = map[String(stock.code || '').toUpperCase()];
      if (row && Number(row.price) > 0) {
        stock.price = Number(row.price);
        stock.changePct = row.changePct == null ? null : Number(row.changePct);
        stock.marketTime = row.marketTime || '';
        stock.priceSource = row.source || data.source || 'Mynet Finans';
        if (row.name) stock.name = row.name;
        updated++;
      }
    });
    save();
    localStorage.setItem('priceFeedUpdatedAt', data.updatedAt || '');
    localStorage.setItem('priceFeedSource', data.source || 'Mynet Finans');
    localStorage.setItem('priceFeedCount', String(data.count || 0));
    render();
    if (showStatus) alert(updated + ' portföy hissesi Mynet Finans verisiyle güncellendi.');
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
    .toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6);
}

async function validateCodeElement(el) {
  if (!el) return false;
  const normalized = normalizeBistCode(el.value);
  if (el.value !== normalized) el.value = normalized;
  const feedback = document.getElementById('codeFeedback');
  const nameInput = document.getElementById('name');
  const addBtn = document.getElementById('addStockBtn');
  if (!normalized) {
    if (feedback) { feedback.textContent = 'BIST kodunu gir.'; feedback.style.color = 'var(--muted)'; }
    if (nameInput) nameInput.value = '';
    if (addBtn) addBtn.disabled = true;
    return false;
  }
  if (!Object.keys(bistPriceMap).length) await loadBistMap();
  const row = bistPriceMap[normalized];
  if (row) {
    if (nameInput) nameInput.value = row.name || '';
    if (feedback) { feedback.textContent = '✓ ' + (row.name || 'Geçerli BIST kodu'); feedback.style.color = 'var(--green)'; }
    if (addBtn) addBtn.disabled = false;
    return true;
  }
  if (nameInput) nameInput.value = '';
  if (feedback) { feedback.textContent = "BIST'te bu hisse kodu bulunamadı."; feedback.style.color = 'var(--red)'; }
  if (addBtn) addBtn.disabled = true;
  return false;
}

document.addEventListener('input', function (event) {
  const el = event.target;
  if (el && el.id === 'code') {
    const normalized = normalizeBistCode(el.value);
    if (el.value !== normalized) el.value = normalized;
    validateCodeElement(el);
  }
});

document.addEventListener('paste', function (event) {
  const el = event.target;
  if (el && el.id === 'code') setTimeout(() => validateCodeElement(el), 0);
});

window.editStock = function(i) {
  const s = stocks[i];
  if (!s) return;
  const qty = prompt(s.code + ' için yeni hisse adedini gir:', String(s.qty).replace('.', ','));
  if (qty === null) return;
  const cost = prompt(s.code + ' için yeni ortalama maliyeti gir:', String(s.cost).replace('.', ','));
  if (cost === null) return;
  const newQty = cleanMoney(qty);
  const newCost = cleanMoney(cost);
  if (newQty <= 0 || newCost <= 0) return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');
  s.qty = newQty;
  s.cost = newCost;
  save(); render();
};

window.addStock = addStock = async function() {
  if (stocks.length >= 10) return alert('En fazla 10 hisse eklenebilir.');
  const codeEl = document.getElementById('code');
  const code = normalizeBistCode(codeEl ? codeEl.value : '');
  if (!code) return alert('BIST kodunu gir.');
  if (!Object.keys(bistPriceMap).length) await loadBistMap();
  const row = bistPriceMap[code];
  if (!row) return alert("BIST'te bu hisse kodu bulunamadı. Lütfen kodu kontrol et.");
  if (stocks.some(s => String(s.code).toUpperCase() === code)) return alert('Bu hisse zaten portföyde.');
  const qty = cleanMoney(document.getElementById('qty').value);
  const cost = cleanMoney(document.getElementById('cost').value);
  if (qty <= 0 || cost <= 0) return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');
  stocks.push({code,name:row.name||'',qty,cost,price:Number(row.price)||0,changePct:row.changePct==null?null:Number(row.changePct),marketTime:row.marketTime||''});
  save(); render();
};

// Kâr/zarar için tek doğru kaynak: güncel toplam değer - toplam maliyet.
window.totals = totals = function() {
  let totalCost = 0, totalValue = 0, daily = 0;
  stocks.forEach(s => {
    const qty = Number(s.qty) || 0;
    const avgCost = Number(s.cost) || 0;
    const price = Number(s.price) || 0;
    totalCost += qty * avgCost;
    if (price > 0) totalValue += qty * price;
    if (price > 0 && Number.isFinite(Number(s.changePct))) {
      const pct = Number(s.changePct);
      const prev = price / (1 + pct / 100);
      if (Number.isFinite(prev) && prev > 0) daily += (price - prev) * qty;
    }
  });
  return {cost: totalCost, val: totalValue, pnl: totalValue - totalCost, daily};
};

window.portfolio = portfolio = function() {
  const t = totals();
  const pricedStocks = stocks.filter(s => Number(s.price) > 0);
  const pricedCost = pricedStocks.reduce((sum,s)=>sum+(Number(s.qty)||0)*(Number(s.cost)||0),0);
  const portfolioPnl = pricedStocks.length ? t.val - pricedCost : 0;
  return `<div class="page"><div class="cards">
    <div class="card"><div class="label">TOPLAM PORTFÖY DEĞERİ</div><div class="value">${pricedStocks.length?fmt(t.val)+' ₺':'—'}</div></div>
    <div class="card"><div class="label">KÂR / ZARAR</div><div class="value ${portfolioPnl>=0?'green':'red'}">${pricedStocks.length?(portfolioPnl>=0?'+':'')+fmt(portfolioPnl)+' ₺':'—'}</div></div>
    <div class="card"><div class="label">MALİYET TUTARI</div><div class="value">${fmt(t.cost)} ₺</div></div>
    <div class="card"><div class="label">GÜNLÜK KÂR / ZARAR</div><div class="value ${t.daily>=0?'green':'red'}">${pricedStocks.length?(t.daily>=0?'+':'')+fmt(t.daily)+' ₺':'—'}</div></div>
  </div><div class="section">Portföyüm</div>${stocks.length?stocks.map(s=>{
    const qty=Number(s.qty)||0, avg=Number(s.cost)||0, price=Number(s.price)||0;
    const totalCost=qty*avg, currentValue=price>0?qty*price:0, pnl=price>0?currentValue-totalCost:null;
    const isProfit=pnl!==null&&pnl>=0;
    return `<div class="panel stock"><div><div class="ticker">${s.code}</div><div class="small">${s.name||''}</div><div class="small">${fmt(qty)} adet · Ort. maliyet ${fmt(avg)} ₺</div><div class="small">Toplam maliyet: <b>${fmt(totalCost)} ₺</b></div></div><div class="mobilehide"><div class="small">GÜNCEL FİYAT</div><b>${price>0?fmt(price)+' ₺':'Veri bekleniyor'}</b><div class="small">Güncel değer: <b>${price>0?fmt(currentValue)+' ₺':'—'}</b></div></div><div class="right"><div class="small">${pnl===null?'KÂR / ZARAR':isProfit?'KÂR':'ZARAR'}</div><b class="${pnl===null?'':isProfit?'green':'red'}">${pnl===null?'—':(isProfit?'+':'')+fmt(pnl)+' ₺'}</b></div></div>`;
  }).join(''):`<div class="panel empty"><b>Portföyünde henüz hisse yok.</b></div>`}</div>`;
};

window.settings = settings = function() {
  return `<div class="page"><div class="section">Portföy Düzenle</div><div class="panel"><div class="formgrid"><div><input id="code" autocomplete="off" autocapitalize="characters" maxlength="6" placeholder="BIST kodu (örn. TUPRS)"><div id="codeFeedback" class="small" style="margin:6px 2px 0">Küçük harfler otomatik büyük harfe çevrilir.</div></div><input id="name" placeholder="Şirket adı otomatik gelecek" readonly><input id="qty" inputmode="decimal" placeholder="Hisse adedi"><input id="cost" inputmode="decimal" placeholder="Ortalama maliyet"></div><div class="btnrow"><button id="addStockBtn" onclick="addStock()" disabled>HİSSE EKLE</button><button onclick="refreshPrices()">FİYATLARI YENİLE</button></div></div>${stocks.map((s,i)=>`<div class="panel stock"><div><b>${s.code}</b><div class="small">${s.name||''} · ${fmt(s.qty)} adet · ${s.price?fmt(s.price)+' ₺':'fiyat bekleniyor'}</div></div><div class="right"><div style="display:flex;flex-direction:column;gap:7px;align-items:stretch"><button onclick="removeStock(${i})">SİL</button><button onclick="editStock(${i})" title="Düzenle">✏️ DÜZENLE</button></div></div></div>`).join('')}<div class="section">Hedef Ayarı</div><div class="panel"><div class="label">AYLIK NET TEMETTÜ HEDEFİ</div><input id="monthly" inputmode="numeric" value="${moneyInput(monthlyTarget)}" oninput="formatTarget(this)" onblur="monthlyTarget=cleanMoney(this.value);save()"></div><div class="panel"><b>Fiyat kaynağı</b><div class="small" style="margin-top:6px">Mynet Finans tüm BIST hisseleri tablosu. GitHub Actions yaklaşık 15 dakikada bir günceller.</div></div></div>`;
};

window.addEventListener('load', async () => {
  await loadBistMap();
  syncMynetPrices(false);
  setInterval(() => syncMynetPrices(false), 15 * 60 * 1000);
});
