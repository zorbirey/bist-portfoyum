// prices-sync.js sonrasi temel ozellikleri garanti altina alir.
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
  ${!dividendFeed.length?'<div class="panel empty">Temettü veri dosyası hazırlanıyor. Bir sonraki veri güncellemesinde otomatik dolacak.</div>':!st.rows.length?'<div class="panel empty">Portföyündeki hisseler için bu takvim yılında açıklanmış temettü kaydı bulunamadı.</div>':st.rows.map(r=>`<div class="panel"><div style="display:flex;justify-content:space-between;gap:12px;align-items:start"><div><div class="ticker">${r.code}</div><div class="small">${r.name||r.stock?.name||''}</div><div class="small">Ödeme tarihi: ${r.date}</div></div><div class="right"><span class="badge ${r.paid?'paid':'pending'}">${r.paid?'ÖDENDİ':'BEKLEYEN'}</span><div style="font-size:20px;font-weight:900;margin-top:8px">${fmt(r.netPS)} ₺ <span class="small">/ hisse net</span></div></div></div><div style="margin-top:12px"><div class="small">Brüt: ${fmt(r.gross)} ₺ · %15 stopaj: ${fmt(r.gross-r.net)} ₺</div><div style="font-size:19px;font-weight:900;margin-top:3px">Net ${r.paid?'ödenen':'ödenecek'}: ${fmt(r.net)} ₺</div></div>${r.paid&&Number(r.stock?.price)>0?`<div class="btnrow"><button onclick="reinvestDividend('${r.code}','${r.date}',${r.net})">TEMETTÜYÜ HİSSEYE EKLE</button></div>`:''}</div>`).join('')}</div>`;
};

window.reinvestDividend=function(code,date,net){
  const idx=stocks.findIndex(s=>String(s.code).toUpperCase()===code);if(idx<0)return;
  const s=stocks[idx],p=Number(s.price)||0;if(p<=0)return alert('Güncel fiyat bulunamadı.');
  const shares=Math.ceil(Number(net)/p);if(shares<=0)return;
  const msg=`${fmt(net)} ₺ net temettü, ${fmt(p)} ₺ güncel fiyatla ${shares} adet ${code} hissesine yuvarlanacak. Portföye eklensin mi?`;
  if(!confirm(msg))return;
  localStorage.setItem('dividendUndo',JSON.stringify({idx,qty:s.qty,cost:s.cost,code,date}));
  const oldQty=Number(s.qty)||0,oldCost=effectiveCost(s),newQty=oldQty+shares;
  s.cost=((oldQty*oldCost)+(shares*p))/newQty;s.qty=newQty;save();render();
};
window.undoDividendReinvest=function(){try{const u=JSON.parse(localStorage.getItem('dividendUndo')||'null');if(!u||!stocks[u.idx])return;stocks[u.idx].qty=u.qty;stocks[u.idx].cost=u.cost;save();localStorage.removeItem('dividendUndo');render();}catch(e){localStorage.removeItem('dividendUndo')}};

window.settings = settings = function(){
  return `<div class="page"><div class="section">Portföy Düzenle</div><div class="panel"><div class="formgrid"><div><input id="code" autocomplete="off" autocapitalize="characters" maxlength="8" placeholder="BIST kodu (örn. TUPRS)"><div id="codeFeedback" class="small" style="margin:6px 2px 0">Küçük harfler otomatik büyük harfe çevrilir.</div></div><input id="name" placeholder="Şirket adı otomatik gelecek" readonly><input id="qty" inputmode="decimal" placeholder="Hisse adedi"><input id="cost" inputmode="decimal" placeholder="Ortalama maliyet"></div><div class="btnrow"><button id="addStockBtn" onclick="addStock()" disabled>HİSSE EKLE</button><button onclick="refreshPrices()">FİYATLARI YENİLE</button></div></div>${stocks.map((s,i)=>`<div class="panel stock"><div><b>${s.code}</b><div class="small">${s.name||''} · ${fmt(s.qty)} adet · ${s.price?fmt(s.price)+' ₺':'fiyat bekleniyor'}</div></div><div class="right"><div style="display:flex;flex-direction:column;gap:7px"><button onclick="removeStock(${i})">SİL</button><button onclick="editStock(${i})">✏️ DÜZENLE</button></div></div></div>`).join('')}<div class="section">Hedef Ayarı</div><div class="panel"><div class="label">AYLIK NET TEMETTÜ HEDEFİ</div><input id="monthly" inputmode="numeric" value="${moneyInput(monthlyTarget)}" oninput="formatTarget(this)" onblur="monthlyTarget=cleanMoney(this.value);save();render()"></div></div>`;
};
