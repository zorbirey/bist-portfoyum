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
  if (c >= 0 && d >= 0) normalized = c > d ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  else if (c >= 0) { const decimals=s.length-c-1; normalized=decimals>=1&&decimals<=2?s.replace(/\./g,'').replace(',','.') : s.replace(/,/g,''); }
  else if (d >= 0) { const decimals=s.length-d-1; normalized=decimals>=1&&decimals<=2?s.replace(/,/g,'') : s.replace(/\./g,''); }
  else normalized=s;
  const n=Number(normalized); return Number.isFinite(n)?(neg?-n:n):0;
};

function rawPortfolioCost(){return stocks.reduce((sum,s)=>sum+(Number(s.qty)||0)*(Number(s.cost)||0),0)}
function currentPortfolioValue(){return stocks.reduce((sum,s)=>sum+(Number(s.qty)||0)*(Number(s.price)||0),0)}
function portfolioNeedsScaleRepair(){const raw=rawPortfolioCost(),value=currentPortfolioValue();return raw>5_000_000&&value>0&&raw>value*10}
function effectiveCost(s){const c=Number(s.cost)||0;return portfolioNeedsScaleRepair()?c/100:c}
function persistScaleRepairIfNeeded(){if(!portfolioNeedsScaleRepair())return false;stocks.forEach(s=>{s.cost=(Number(s.cost)||0)/100});save();localStorage.setItem('costRepairV4',new Date().toISOString());return true}

async function loadBistMap(){try{const res=await fetch('./prices.json?ts='+Date.now(),{cache:'no-store'});if(!res.ok)throw new Error('prices.json alınamadı');const data=await res.json();bistPriceMap=data.prices||{};return data}catch(err){console.error('BIST kod listesi alınamadı:',err);return null}}
async function loadDividendFeed(){try{const res=await fetch('./dividends.json?ts='+Date.now(),{cache:'no-store'});if(!res.ok)throw new Error('dividends.json alınamadı');const data=await res.json();dividendFeed=Array.isArray(data.dividends)?data.dividends:[];dividendFeedMeta=data;return data}catch(e){console.warn('Temettü verisi henüz hazır değil:',e);dividendFeed=[];return null}}

async function syncMynetPrices(showStatus=false){if(!Array.isArray(stocks)||stocks.length===0)return;try{const data=await loadBistMap();if(!data)throw new Error('prices.json alınamadı');let updated=0;stocks.forEach(stock=>{const row=bistPriceMap[String(stock.code||'').toUpperCase()];if(row&&Number(row.price)>0){stock.price=Number(row.price);stock.changePct=row.changePct==null?null:Number(row.changePct);stock.marketTime=row.marketTime||'';stock.priceSource=row.source||data.source||'Mynet Finans';if(row.name)stock.name=row.name;updated++}});persistScaleRepairIfNeeded();save();localStorage.setItem('priceFeedUpdatedAt',data.updatedAt||'');render();if(showStatus)alert(updated+' portföy hissesi güncellendi.')}catch(err){console.error('Mynet fiyat senkronizasyonu başarısız:',err);if(showStatus)alert('Fiyat verisi şu anda alınamadı. Son kayıtlı fiyatlar gösteriliyor.')}}
window.refreshPrices=()=>syncMynetPrices(true);

function normalizeBistCode(value){return String(value||'').replace(/ç/gi,'C').replace(/ğ/gi,'G').replace(/ı/gi,'I').replace(/ö/gi,'O').replace(/ş/gi,'S').replace(/ü/gi,'U').toUpperCase().replace(/[^A-Z0-9]/g,'').slice(0,8)}
async function validateCodeElement(el){if(!el)return false;const normalized=normalizeBistCode(el.value);if(el.value!==normalized)el.value=normalized;const feedback=document.getElementById('codeFeedback'),nameInput=document.getElementById('name'),addBtn=document.getElementById('addStockBtn');if(!normalized){if(feedback){feedback.textContent='BIST kodunu gir.';feedback.style.color='var(--muted)'}if(nameInput)nameInput.value='';if(addBtn)addBtn.disabled=true;return false}if(!Object.keys(bistPriceMap).length)await loadBistMap();const row=bistPriceMap[normalized];if(row){if(nameInput)nameInput.value=row.name||'';if(feedback){feedback.textContent='✓ '+(row.name||'Geçerli BIST kodu');feedback.style.color='var(--green)'}if(addBtn)addBtn.disabled=false;return true}if(nameInput)nameInput.value='';if(feedback){feedback.textContent="BIST'te bu hisse kodu bulunamadı.";feedback.style.color='var(--red)'}if(addBtn)addBtn.disabled=true;return false}
document.addEventListener('input',e=>{if(e.target?.id==='code'){e.target.value=normalizeBistCode(e.target.value);validateCodeElement(e.target)}});document.addEventListener('paste',e=>{if(e.target?.id==='code')setTimeout(()=>validateCodeElement(e.target),0)});

window.editStock=function(i){const s=stocks[i];if(!s)return;const qty=prompt(s.code+' için yeni hisse adedini gir:',String(s.qty).replace('.',','));if(qty===null)return;const cost=prompt(s.code+' için yeni ortalama maliyeti gir:',String(effectiveCost(s)).replace('.',','));if(cost===null)return;const q=cleanMoney(qty),c=cleanMoney(cost);if(q<=0||c<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');s.qty=q;s.cost=c;save();render()};
window.addStock=addStock=async function(){if(stocks.length>=10)return alert('En fazla 10 hisse eklenebilir.');const code=normalizeBistCode(document.getElementById('code')?.value||'');if(!code)return alert('BIST kodunu gir.');if(!Object.keys(bistPriceMap).length)await loadBistMap();const row=bistPriceMap[code];if(!row)return alert("BIST'te bu hisse kodu bulunamadı. Lütfen kodu kontrol et.");if(stocks.some(s=>String(s.code).toUpperCase()===code))return alert('Bu hisse zaten portföyde.');const qty=cleanMoney(document.getElementById('qty').value),cost=cleanMoney(document.getElementById('cost').value);if(qty<=0||cost<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');stocks.push({code,name:row.name||'',qty,cost,price:Number(row.price)||0,changePct:row.changePct==null?null:Number(row.changePct),marketTime:row.marketTime||''});save();render()};

window.totals=totals=function(){let cost=0,val=0,daily=0;stocks.forEach(s=>{const q=Number(s.qty)||0,c=effectiveCost(s),p=Number(s.price)||0;cost+=q*c;if(p>0)val+=q*p;if(p>0&&Number.isFinite(Number(s.changePct))){const pct=Number(s.changePct),prev=p/(1+pct/100);if(prev>0&&Number.isFinite(prev))daily+=(p-prev)*q}});return{cost,val,pnl:val-cost,daily}};
window.portfolio=portfolio=function(){const t=totals();const priced=stocks.filter(s=>Number(s.price)>0);const pricedCost=priced.reduce((a,s)=>a+(Number(s.qty)||0)*effectiveCost(s),0);const pnl=priced.length?t.val-pricedCost:0;return `<div class="page"><div class="cards"><div class="card"><div class="label">TOPLAM PORTFÖY DEĞERİ</div><div class="value">${priced.length?fmt(t.val)+' ₺':'—'}</div></div><div class="card"><div class="label">KÂR / ZARAR</div><div class="value ${pnl>=0?'green':'red'}">${priced.length?(pnl>=0?'+':'')+fmt(pnl)+' ₺':'—'}</div></div><div class="card"><div class="label">MALİYET TUTARI</div><div class="value">${fmt(t.cost)} ₺</div></div><div class="card"><div class="label">GÜNLÜK KÂR / ZARAR</div><div class="value ${t.daily>=0?'green':'red'}">${priced.length?(t.daily>=0?'+':'')+fmt(t.daily)+' ₺':'—'}</div></div></div><div class="section">Portföyüm</div>${stocks.length?stocks.map(s=>{const q=Number(s.qty)||0,c=effectiveCost(s),p=Number(s.price)||0,tc=q*c,cv=p>0?q*p:0,k=p>0?cv-tc:null,profit=k!==null&&k>=0,colorClass=k===null?'':profit?'green':'red';return `<div class="panel stock"><div><div class="ticker">${s.code}</div><div class="small">${s.name||''}</div><div class="small">${fmt(q)} adet · Ort. maliyet ${fmt(c)} ₺</div><div class="small">Toplam maliyet: <b>${fmt(tc)} ₺</b></div></div><div class="mobilehide"><div class="small">GÜNCEL FİYAT</div><b>${p>0?fmt(p)+' ₺':'Veri bekleniyor'}</b></div><div class="right"><div class="small">${k===null?'KÂR / ZARAR':profit?'KÂR':'ZARAR'}</div><b class="${colorClass}">${k===null?'—':(profit?'+':'')+fmt(k)+' ₺'}</b><div class="small" style="margin-top:8px">GÜNCEL DEĞER</div><b class="${colorClass}">${p>0?fmt(cv)+' ₺':'—'}</b></div></div>`}).join(''):'<div class="panel empty">Portföyünde henüz hisse yok.</div>'}</div>`};

function parseTRDate(s){const[d,m,y]=String(s||'').split('.').map(Number);return new Date(y,m-1,d)}
function portfolioDividendRows(){const year=new Date().getFullYear(),codes=new Set(stocks.map(s=>String(s.code).toUpperCase()));return dividendFeed.filter(d=>codes.has(String(d.code).toUpperCase())&&parseTRDate(d.date).getFullYear()===year).map(d=>{const stock=stocks.find(s=>String(s.code).toUpperCase()===String(d.code).toUpperCase()),qty=Number(stock?.qty)||0,grossPS=Number(d.grossPerShare)||0,netPS=grossPS*.85,gross=grossPS*qty,net=netPS*qty,paid=parseTRDate(d.date)<new Date(new Date().getFullYear(),new Date().getMonth(),new Date().getDate());return{...d,qty,grossPS,netPS,gross,net,paid,stock}}).sort((a,b)=>{if(a.paid!==b.paid)return a.paid?1:-1;return a.paid?parseTRDate(b.date)-parseTRDate(a.date):parseTRDate(a.date)-parseTRDate(b.date)})}
function dividendStats(){const rows=portfolioDividendRows();return{rows,forecast:rows.reduce((a,r)=>a+r.net,0),paid:rows.filter(r=>r.paid).reduce((a,r)=>a+r.net,0)}}
window.divTotal=divTotal=function(){return dividendStats().forecast};
window.dividend=dividend;
window.addEventListener('load',async()=>{await Promise.all([loadBistMap(),loadDividendFeed()]);persistScaleRepairIfNeeded();syncMynetPrices(false);setInterval(()=>syncMynetPrices(false),15*60*1000)});
