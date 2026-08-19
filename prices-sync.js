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

    if (showStatus) {
      alert(updated + ' portföy hissesi Mynet Finans verisiyle güncellendi.');
    }
  } catch (err) {
    console.error('Mynet fiyat senkronizasyonu başarısız:', err);
    if (showStatus) alert('Fiyat verisi şu anda alınamadı. Son kayıtlı fiyatlar gösteriliyor.');
  }
}

window.refreshPrices = () => syncMynetPrices(true);
window.addEventListener('load', () => {
  syncMynetPrices(false);
  setInterval(() => syncMynetPrices(false), 15 * 60 * 1000);
});
