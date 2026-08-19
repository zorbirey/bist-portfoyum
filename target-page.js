(function(){
  const style=document.createElement('style');
  style.textContent=`
    .target-head{text-align:center;margin:6px 0 14px}.target-red{color:#b94e4e;font-weight:950;font-size:23px}.target-motto{font-weight:950;color:#202824;margin-top:6px;line-height:1.4}.target-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:9px}.target-step{border:1px solid var(--line);background:#fff;border-radius:14px;padding:12px;text-align:center;cursor:pointer}.target-step.active{outline:2px solid #7cae90}.target-step .tbar{height:12px;border-radius:20px;margin-top:8px;background:#efcccc;overflow:hidden}.target-step .tbar span{display:block;height:100%;background:#74ad8b}.target-mode{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:10px}.target-plan-card{display:grid;grid-template-columns:1fr auto;gap:12px;align-items:center;padding:13px 0;border-bottom:1px solid var(--line)}.target-plan-card:last-child{border-bottom:0}.target-badge{font-size:11px;padding:5px 8px;border-radius:999px;background:#edf6f0;color:#397553;font-weight:900}.warning-target{padding:14px;border:2px solid #d76565;background:#fff1f1;color:#9d3030;border-radius:15px;text-align:center;font-weight:900;line-height:1.45;animation:targetPulse 1.15s infinite;margin-top:12px}@keyframes targetPulse{50%{opacity:.55}}@media(max-width:700px){.target-grid{grid-template-columns:repeat(2,1fr)}}`;
  document.head.appendChild(style);

  let selectedMilestone=1;
  let selectedMode=localStorage.getItem('targetMode')||'single';

  function annualForecast(){
    try{return Number(dividendStats().forecast)||0}catch(e){return 0}
  }
  function targetAnnual(){
    const mode=localStorage.getItem('targetPeriod')||'annual';
    const raw=Number(localStorage.getItem('targetAmount')||annualTarget||0);
    return mode==='monthly'?raw*12:raw;
  }
  function selectedGoal(){return targetAnnual()*selectedMilestone}
  function remaining(){return Math.max(0,selectedGoal()-annualForecast())}
  function dividendPerShareByCode(){
    const year=new Date().getFullYear(); const map={};
    try{
      portfolioDividendRows().forEach(r=>{if(parseTRDate(r.date).getFullYear()===year){map[r.code]=(map[r.code]||0)+(Number(r.netPS)||0)}});
    }catch(e){}
    return map;
  }
  function eligibleStocks(){
    const dps=dividendPerShareByCode();
    return stocks.map(s=>({...s,netYearPerShare:Number(dps[String(s.code).toUpperCase()]||0)})).filter(s=>Number(s.price)>0&&s.netYearPerShare>0);
  }
  function singlePlan(){
    const rem=remaining();
    return eligibleStocks().map(s=>{
      const qty=Math.ceil(rem/s.netYearPerShare);
      const cost=qty*Number(s.price);
      const added=qty*s.netYearPerShare;
      return {...s,planQty:qty,planCost:cost,addedDividend:added};
    }).sort((a,b)=>a.planCost-b.planCost);
  }
  function equalPlan(){
    const list=eligibleStocks(); const rem=remaining(); if(!list.length)return [];
    const share=rem/list.length;
    return list.map(s=>{
      const qty=Math.ceil(share/s.netYearPerShare);
      return {...s,planQty:qty,planCost:qty*Number(s.price),addedDividend:qty*s.netYearPerShare};
    });
  }
  function money(v){return new Intl.NumberFormat('tr-TR',{maximumFractionDigits:0}).format(Number(v)||0)}

  window.setTargetMilestone=function(v){selectedMilestone=Number(v)||1;render();};
  window.setTargetMode=function(mode){selectedMode=mode;localStorage.setItem('targetMode',mode);render();};
  window.setTargetPeriod=function(mode){localStorage.setItem('targetPeriod',mode);render();};
  window.saveTargetAmount=function(el){const n=cleanMoney(el.value);localStorage.setItem('targetAmount',String(n));if((localStorage.getItem('targetPeriod')||'annual')==='annual'){annualTarget=n;localStorage.setItem('annualTarget',String(n));}render();};
  window.formatTargetAmount=function(el){let n=cleanMoney(el.value);el.value=new Intl.NumberFormat('tr-TR',{maximumFractionDigits:0}).format(n||0);};

  window.target=function(){
    const period=localStorage.getItem('targetPeriod')||'annual';
    const raw=Number(localStorage.getItem('targetAmount')||annualTarget||0);
    const annual=targetAnnual(), forecast=annualForecast(), rem=remaining(), selected=selectedGoal();
    const milestones=[.25,.5,.75,1];
    const plan=selectedMode==='single'?singlePlan():equalPlan();
    const planTotal=plan.reduce((a,x)=>a+x.planCost,0), planDiv=plan.reduce((a,x)=>a+x.addedDividend,0);
    const planSummary = selectedMode==='equal' ? `<div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap"><div><div class="label">PLAN TOPLAM MALİYETİ</div><div class="value">${fmt(planTotal)} ₺</div></div><div class="right"><div class="label">EK NET TEMETTÜ GELİRİ</div><div class="value green">+${fmt(planDiv)} ₺</div></div></div>` : '';
    return `<div class="page">
      <div class="target-head"><div class="target-red">NET TEMETTÜ HEDEFİ</div><div class="target-motto">HEDEFE GİDEN YOLDA ÇEKİLEN BÜTÜN ÇİLELER KUTSALDIR</div></div>
      <div class="warning-target">UYARI<br>BU HESAPLAMALAR SADECE BU SENEYE GÖRE YAPILMIŞTIR. SENEYE HİSSENİN TEMETTÜ VERMESİ GARANTİ DEĞİLDİR. SADECE FİKİR AMAÇLIDIR</div>
      <div class="panel"><div class="label">HEDEF TÜRÜ</div><div class="target-mode"><button onclick="setTargetPeriod('annual')" style="${period==='annual'?'outline:2px solid #7cae90':''}">YILLIK</button><button onclick="setTargetPeriod('monthly')" style="${period==='monthly'?'outline:2px solid #7cae90':''}">AYLIK</button></div><div class="label" style="margin-top:12px">${period==='annual'?'YILLIK':'AYLIK'} NET TEMETTÜ HEDEFİ</div><input inputmode="numeric" value="${money(raw)}" oninput="formatTargetAmount(this)" onblur="saveTargetAmount(this)"><div class="small" style="margin-top:8px">Yıllık karşılığı: <b>${fmt(annual)} ₺</b></div><div class="small">Bu yıl öngörülen net temettü: <b>${fmt(forecast)} ₺</b></div></div>
      <div class="section">Hedef Kademeleri</div><div class="target-grid">${milestones.map(m=>{const goal=annual*m,pct=goal?Math.min(100,forecast/goal*100):0;return `<div class="target-step ${selectedMilestone===m?'active':''}" onclick="setTargetMilestone(${m})"><div class="label">${m===1?'HEDEF':m*100+'%'}</div><b>${fmt(goal)} ₺</b><div class="tbar"><span style="width:${pct}%"></span></div><div class="small" style="margin-top:6px">${pct>=100?'Ulaşıldı':'%'+fmt(pct)}</div></div>`}).join('')}</div>
      <div class="panel"><div class="label">HEDEF KADEMESİNE KALAN TUTAR</div><div class="value ${rem>0?'red':'green'}">${fmt(rem)} ₺</div><div class="small">Seçili kademe: ${selectedMilestone===1?'%100':('%'+selectedMilestone*100)} · ${fmt(selected)} ₺</div><div class="section" style="margin-top:16px">Tek hisseden mi portföye eşit dağılımla mı ilerlemek istersiniz?</div><div class="target-mode"><button onclick="setTargetMode('single')" style="${selectedMode==='single'?'outline:2px solid #7cae90':''}">TEK HİSSE</button><button onclick="setTargetMode('equal')" style="${selectedMode==='equal'?'outline:2px solid #7cae90':''}">EŞİT DAĞILIM</button></div></div>
      <div class="panel">${planSummary}${!plan.length?'<div class="empty">Plan oluşturmak için portföyde fiyatı ve 2026 net temettü verisi bulunan hisse gerekli.</div>':plan.map((p,i)=>`<div class="target-plan-card"><div><div><b>${i===0&&selectedMode==='single'?'★ EN DÜŞÜK MALİYET · ':''}${p.code}</b> <span class="small">${p.name||''}</span></div><div class="small">Yıllık net temettü / hisse: ${fmt(p.netYearPerShare)} ₺ · Güncel fiyat: ${fmt(p.price)} ₺</div><div class="small">Alınması gereken: <b>${fmt(p.planQty)} adet</b> · Ek net temettü: <b>${fmt(p.addedDividend)} ₺</b></div></div><div class="right"><span class="target-badge">MALİYET</span><div style="font-weight:900;margin-top:5px">${fmt(p.planCost)} ₺</div></div></div>`).join('')}</div>
    </div>`;
  };
})();
