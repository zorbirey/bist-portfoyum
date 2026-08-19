(function(){
  const colors=['#8bb8a1','#d99a9a','#9fb7d8','#d8bd83','#b8a0cc','#80b9bd','#d8a6c1','#aabf7f','#d59e72','#8fa5a8'];
  window.distribution = distribution = function(){
    const rows=(Array.isArray(stocks)?stocks:[]).map((s,i)=>{
      const value=(Number(s.qty)||0)*(Number(s.price)||0);
      return {code:String(s.code||''),name:s.name||'',value,color:colors[i%colors.length]};
    }).filter(x=>x.value>0);
    const total=rows.reduce((a,x)=>a+x.value,0);
    if(!rows.length||total<=0){
      return '<div class="page"><div class="section">Portföy Dağılımı</div><div class="panel empty">Pie chart göstermek için güncel fiyat verisi gerekli.</div></div>';
    }
    let deg=0;
    const stops=rows.map(r=>{
      const pct=r.value/total*100;
      const start=deg;
      deg+=pct*3.6;
      r.pct=pct;
      return `${r.color} ${start.toFixed(2)}deg ${deg.toFixed(2)}deg`;
    }).join(',');
    const legend=rows.map(r=>`<div style="display:grid;grid-template-columns:14px 1fr auto;gap:9px;align-items:center;padding:9px 0;border-bottom:1px solid var(--line)"><span style="width:12px;height:12px;border-radius:4px;background:${r.color}"></span><div><b>${r.code}</b><div class="small">${r.name}</div></div><div class="right"><b>%${fmt(r.pct)}</b><div class="small">${fmt(r.value)} ₺</div></div></div>`).join('');
    return `<div class="page"><div class="section">Portföy Dağılımı</div><div class="panel" style="display:flex;justify-content:center;padding:24px"><div style="width:min(72vw,330px);aspect-ratio:1;border-radius:50%;background:conic-gradient(${stops});position:relative;box-shadow:inset 0 0 0 1px rgba(0,0,0,.03)"><div style="position:absolute;inset:27%;background:var(--card);border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:8px"><span class="small">PORTFÖY DEĞERİ</span><b style="font-size:18px;margin-top:4px">${fmt(total)} ₺</b></div></div></div><div class="panel"><div class="label" style="margin-bottom:5px">GÜNCEL DEĞERE GÖRE DAĞILIM</div>${legend}</div></div>`;
  };
})();
