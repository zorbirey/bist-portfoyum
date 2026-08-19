async function syncMynetPrices(showStatus = false) {
  if (!Array.isArray(stocks) || stocks.length === 0) return;
  try {
    const res = await fetch('./prices.json?ts=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) throw new Error('prices.json alınamadı');
    const data = await res.json();
    const map = data.prices || {};
    let updated = 0;
    stocks.forEach(stock => {
      const row = map[String(stock.code || '').toUpperCase()];
      if (row && Number(row.price) > 0) {
        stock.price = Number(row.price);
        stock.changePct = row.changePct == null ? null : Number(row.changePct);
        stock.marketTime = row.marketTime || '';
        stock.priceSource = row.source || data.source || 'Mynet Finans';
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

// Ayarlar ekranında mevcut hisseyi silmeden adet ve ortalama maliyeti değiştirme.
const baseSettings = window.settings || settings;
window.editStock = function(i) {
  const s = stocks[i];
  if (!s) return;
  const qty = prompt(s.code + ' için yeni hisse adedini gir:', String(s.qty).replace('.', ','));
  if (qty === null) return;
  const cost = prompt(s.code + ' için yeni ortalama maliyeti gir:', String(s.cost).replace('.', ','));
  if (cost === null) return;
  const newQty = cleanMoney(qty);
  const newCost = cleanMoney(cost);
  if (newQty <= 0 || newCost <= 0) {
    alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');
    return;
  }
  s.qty = newQty;
  s.cost = newCost;
  save();
  render();
};

window.settings = settings = function() {
  return `<div class="page"><div class="section">Portföy Düzenle</div><div class="panel"><div class="formgrid"><input id="code" placeholder="BIST kodu (örn. TUPRS)"><input id="name" placeholder="Şirket adı (isteğe bağlı)"><input id="qty" inputmode="decimal" placeholder="Hisse adedi"><input id="cost" inputmode="decimal" placeholder="Ortalama maliyet"></div><div class="btnrow"><button onclick="addStock()">HİSSE EKLE</button><button onclick="refreshPrices()">FİYATLARI YENİLE</button></div></div>${stocks.map((s,i)=>`<div class="panel stock"><div><b>${s.code}</b><div class="small">${s.name||''} · ${fmt(s.qty)} adet · ${s.price?fmt(s.price)+' ₺':'fiyat bekleniyor'}</div></div><div class="right"><div class="btnrow" style="justify-content:flex-end;margin-top:0"><button onclick="editStock(${i})" title="Düzenle">✏️ DÜZENLE</button><button onclick="removeStock(${i})">SİL</button></div></div></div>`).join('')}<div class="section">Hedef Ayarı</div><div class="panel"><div class="label">AYLIK NET TEMETTÜ HEDEFİ</div><input id="monthly" inputmode="numeric" value="${moneyInput(monthlyTarget)}" oninput="formatTarget(this)" onblur="monthlyTarget=cleanMoney(this.value);save()"></div><div class="panel"><b>Fiyat kaynağı</b><div class="small" style="margin-top:6px">Mynet Finans tüm BIST hisseleri tablosu. GitHub Actions yaklaşık 15 dakikada bir günceller. Portföy adet ve maliyetlerin yalnızca bu cihazda saklanır.</div></div></div>`;
};

window.addEventListener('load', () => {
  syncMynetPrices(false);
  setInterval(() => syncMynetPrices(false), 15 * 60 * 1000);
});
