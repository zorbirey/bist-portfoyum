let bistPriceMap = {};

// Türkçe ve İngilizce sayı biçimlerini doğru okur.
window.cleanMoney = cleanMoney = function(value) {
  let s = String(value ?? '').trim().replace(/\s/g, '').replace(/[^0-9,.-]/g, '');
  if (!s) return 0;
  const neg = s.startsWith('-'); s = s.replace(/-/g, '');
  const c = s.lastIndexOf(','), d = s.lastIndexOf('.');
  let normalized;
  if (c >= 0 && d >= 0) normalized = c > d ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  else if (c >= 0) { const decimals=s.length-c-1; normalized=decimals>=1&&decimals<=2?s.replace(/\./g,'').replace(',','.'):s.replace(/,/g,''); }
  else if (d >= 0) { const decimals=s.length-d-1; normalized=decimals>=1&&decimals<=2?s.replace(/,/g,''):s.replace(/\./g,''); }
  else normalized=s;
  const n=Number(normalized); return Number.isFinite(n)?(neg?-n:n):0;
};

async function loadBistMap(){try{const res=await fetch('./prices.json?ts='+Date.now(),{cache:'no-store'});if(!res.ok)throw new Error('prices.json alınamadı');const data=await res.json();bistPriceMap=data.prices||{};return data}catch(err){console.error('BIST kod listesi alınamadı:',err);return null}}

// Eski sürümde 145.20 -> 14520 kaydedilen maliyetleri düzeltir.
// V3 ayrı anahtar kullanır; önceki onarım fiyat gelmeden çalıştıysa tekrar denenir.
function repairOldCostsV3(){
  if(localStorage.getItem('costRepairV3')==='done') return false;
  let changed=false;
  stocks.forEach(s=>{
    const price=Number(s.price)||0, cost=Number(s.cost)||0;
    if(price>0 && cost>price*20){
      const corrected=cost/100;
      // Düzeltme sonrası maliyet piyasa fiyatının makul çevresine geliyorsa uygula.
      if(corrected>0 && corrected<price*5){s.cost=Math.round(corrected*100)/100;changed=true;}
    }
  });
  if(changed) save();
  localStorage.setItem('costRepairV3','done');
  return changed;
}

async function syncMynetPrices(showStatus=false){
  if(!Array.isArray(stocks)||stocks.length===0)return;
  try{
    const data=await loadBistMap();if(!data)throw new Error('prices.json alınamadı');const map=data.prices||{};let updated=0;
    stocks.forEach(stock=>{const row=map[String(stock.code||'').toUpperCase()];if(row&&Number(row.price)>0){stock.price=Number(row.price);stock.changePct=row.changePct==null?null:Number(row.changePct);stock.marketTime=row.marketTime||'';stock.priceSource=row.source||data.source||'Mynet Finans';if(row.name)stock.name=row.name;updated++;}});
    repairOldCostsV3();save();render();
    if(showStatus)alert(updated+' portföy hissesi güncellendi.');
  }catch(err){console.error('Fiyat senkronizasyonu başarısız:',err);if(showStatus)alert('Fiyat verisi şu anda alınamadı. Son kayıtlı fiyatlar gösteriliyor.');}
}
window.refreshPrices=()=>syncMynetPrices(true);

function normalizeBistCode(value){return String(value||'').replace(/ç/gi,'C').replace(/ğ/gi,'G').replace(/ı/gi,'I').replace(/ö/gi,'O').replace(/ş/gi,'S').replace(/ü/gi,'U').toUpperCase().replace(/[^A-Z0-9]/g,'').slice(0,6)}
async function validateCodeElement(el){if(!el)return false;const normalized=normalizeBistCode(el.value);if(el.value!==normalized)el.value=normalized;const feedback=document.getElementById('codeFeedback'),nameInput=document.getElementById('name'),addBtn=document.getElementById('addStockBtn');if(!normalized){if(feedback){feedback.textContent='BIST kodunu gir.';feedback.style.color='var(--muted)'}if(nameInput)nameInput.value='';if(addBtn)addBtn.disabled=true;return false}if(!Object.keys(bistPriceMap).length)await loadBistMap();const row=bistPriceMap[normalized];if(row){if(nameInput)nameInput.value=row.name||'';if(feedback){feedback.textContent='✓ '+(row.name||'Geçerli BIST kodu');feedback.style.color='var(--green)'}if(addBtn)addBtn.disabled=false;return true}if(nameInput)nameInput.value='';if(feedback){feedback.textContent="BIST'te bu hisse kodu bulunamadı.";feedback.style.color='var(--red)'}if(addBtn)addBtn.disabled=true;return false}
document.addEventListener('input',e=>{const el=e.target;if(el&&el.id==='code'){const n=normalizeBistCode(el.value);if(el.value!==n)el.value=n;validateCodeElement(el)}});
document.addEventListener('paste',e=>{const el=e.target;if(el&&el.id==='code')setTimeout(()=>validateCodeElement(el),0)});

window.editStock=function(i){const s=stocks[i];if(!s)return;const qty=prompt(s.code+' için yeni hisse adedini gir:',String(s.qty).replace('.',','));if(qty===null)return;const cost=prompt(s.code+' için yeni ortalama maliyeti gir:',String(s.cost).replace('.',','));if(cost===null)return;const newQty=cleanMoney(qty),newCost=cleanMoney(cost);if(newQty<=0||newCost<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');s.qty=newQty;s.cost=newCost;save();render()};
window.addStock=addStock=async function(){if(stocks.length>=10)return alert('En fazla 10 hisse eklenebilir.');const codeEl=document.getElementById('code'),code=normalizeBistCode(codeEl?codeEl.value:'');if(!code)return alert('BIST kodunu gir.');if(!Object.keys(bistPriceMap).length)await loadBistMap();const row=bistPriceMap[code];if(!row)return alert("BIST'te bu hisse kodu bulunamadı. Lütfen kodu kontrol et.");if(stocks.some(s=>String(s.code).toUpperCase()===code))return alert('Bu hisse zaten portföyde.');const qty=cleanMoney(document.getElementById('qty').value),cost=cleanMoney(document.getElementById('cost').value);if(qty<=0||cost<=0)return alert('Hisse adedi ve ortalama maliyet sıfırdan büyük olmalıdır.');stocks.push({code,name:row.name||'',qty,cost,price:Number(row.price)||0,changePct:row.changePct==null?null:Number(row.changePct),marketTime:row.marketTime||''});save();render()};

window.totals=totals=function(){let totalCost=0,totalValue=0,daily=0;stocks.forEach(s=>{const qty=Number(s.qty)||0,avgCost=Number(s.cost)||0,price=Number(s.price)||0;totalCost+=qty*avgCost;if(price>0)totalValue+=qty*price;if(price>0&&Number.isFinite(Number(s.changePct))){const pct=Number(s.changePct),prev=price/(1+pct/100);if(Number.isFinite(prev)&&prev>0)daily+=(price-prev)*qty}});return{cost:totalCost,val:totalValue,pnl:totalValue-totalCost,daily}};
window.portfolio=portfolio=function(){const t=totals(),pricedStocks=stocks.filter(s=>Number(s.price)>0),pricedCost=pricedStocks.reduce((sum,s)=>sum+(Number(s.qty)||0)*(Number(s.cost)||0),0),portfolioPnl=pricedStocks.length?t.val-pricedCost:0;return `<div class="page"><div class="cards"><div class="card"><div class="label">TOPLAM PORTFÖY DEĞERİ</div><div class="value">${pricedStocks.length?fmt(t.val)+' ₺':'—'}</div></div><div class="card"><div class="label">KÂR / ZARAR</div><div class="value ${portfolioPnl>=0?'green':'red'}">${pricedStocks.length?(portfolioPnl>=0?'+':'')+fmt(portfolioPnl)+' ₺':'—'}</div></div><div class="card"><div class="label">MALİYET TUTARI</div><div class="value">${fmt(t.cost)} ₺</div></div><div class="card"><div class="label">GÜNLÜK KÂR / ZARAR</div><div class="value ${t.daily>=0?'green':'red'}">${pricedStocks.length?(t.daily>=0?'+':'')+fmt(t.daily)+' ₺':'—'}</div></div></div><div class="section">Portföyüm</div>${stocks.length?stocks.map(s=>{const qty=Number(s.qty)||0,avg=Number(s.cost)||0,price=Number(s.price)||0,totalCost=qty*avg,currentValue=price>0?qty*price:0,pnl=price>0?currentValue-totalCost:null,isProfit=pnl!==null&&pnl>=0;return `<div class="panel stock"><div><div class="ticker">${s.code}</div><div class="small">${s.name||''}</div><div class="small">${fmt(qty)} adet · Ort. maliyet ${fmt(avg)} ₺</div><div class="small">Toplam maliyet: <b>${fmt(totalCost)} ₺</b></div></div><div class="mobilehide"><div class="small">GÜNCEL FİYAT</div><b>${price>0?fmt(price)+' ₺':'Veri bekleniyor'}</b><div class="small">Güncel değer: <b>${price>0?fmt(currentValue)+' ₺':'—'}</b></div></div><div class="right"><div class="small">${pnl===null?'KÂR / ZARAR':isProfit?'KÂR':'ZARAR'}</div><b class="${pnl===null?'':isProfit?'green':'red'}">${pnl===null?'—':(isProfit?'+':'')+fmt(pnl)+' ₺'}</b></div></div>`}).join(''):`<div class="panel empty"><b>Portföyünde henüz hisse yok.</b></div>`}</div>`};
window.settings=settings=function(){return `<div class="page"><div class="section">Portföy Düzenle</div><div class="panel"><div class="formgrid"><div><input id="code" autocomplete="off" autocapitalize="characters" maxlength="6" placeholder="BIST kodu (örn. TUPRS)"><div id="codeFeedback" class="small" style="margin:6px 2px 0">Küçük harfler otomatik büyük harfe çevrilir.</div></div><input id="name" placeholder="Şirket adı otomatik gelecek" readonly><input id="qty" inputmode="decimal" placeholder="Hisse adedi"><input id="cost" inputmode="decimal" placeholder="Ortalama maliyet"></div><div class="btnrow"><button id="addStockBtn" onclick="addStock()" disabled>HİSSE EKLE</button><button onclick="refreshPrices()">FİYATLARI YENİLE</button></div></div>${stocks.map((s,i)=>`<div class="panel stock"><div><b>${s.code}</b><div class="small">${s.name||''} · ${fmt(s.qty)} adet · ${s.price?fmt(s.price)+' ₺':'fiyat bekleniyor'}</div></div><div class="right"><div style="display:flex;flex-direction:column;gap:7px;align-items:stretch"><button onclick="removeStock(${i})">SİL</button><button onclick="editStock(${i})">✏️ DÜZENLE</button></div></div></div>`).join('')}<div class="section">Hedef Ayarı</div><div class="panel"><div class="label">AYLIK NET TEMETTÜ HEDEFİ</div><input id="monthly" inputmode="numeric" value="${moneyInput(monthlyTarget)}" oninput="formatTarget(this)" onblur="monthlyTarget=cleanMoney(this.value);save()"></div></div>`};
window.addEventListener('load',async()=>{await loadBistMap();await syncMynetPrices(false);setInterval(()=>syncMynetPrices(false),15*60*1000)});
