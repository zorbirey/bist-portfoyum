(function(){
  function backupPayload(){
    const storage={};
    for(let i=0;i<localStorage.length;i++){
      const key=localStorage.key(i);
      if(key!=null) storage[key]=localStorage.getItem(key);
    }
    return {
      app:'BIST Portföy',version:2,exportedAt:new Date().toISOString(),storage,
      stocks:JSON.parse(localStorage.getItem('stocks')||'[]'),
      annualTarget:Number(localStorage.getItem('annualTarget')||0),
      monthlyTarget:Number(localStorage.getItem('monthlyTarget')||0),
      targetAmount:localStorage.getItem('targetAmount'),
      targetPeriod:localStorage.getItem('targetPeriod'),
      targetMode:localStorage.getItem('targetMode'),
      dividends:JSON.parse(localStorage.getItem('dividends')||'[]')
    };
  }

  window.exportPortfolioBackup=function(){
    const blob=new Blob([JSON.stringify(backupPayload(),null,2)],{type:'application/json'});
    const a=document.createElement('a');
    a.href=URL.createObjectURL(blob);
    const d=new Date();
    const ds=[d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-');
    a.download='bist-portfoy-yedek-'+ds+'.json';
    document.body.appendChild(a);a.click();a.remove();
    setTimeout(()=>URL.revokeObjectURL(a.href),1000);
  };

  window.pickPortfolioBackup=function(){
    const input=document.getElementById('backupFileInput');
    if(!input)return;
    input.value='';
    input.click();
  };

  function restoreLegacyBackup(x){
    if(!Array.isArray(x.stocks))throw new Error('Geçersiz yedek');
    localStorage.setItem('stocks',JSON.stringify(x.stocks));
    if(x.annualTarget!=null)localStorage.setItem('annualTarget',String(x.annualTarget));
    if(x.monthlyTarget!=null)localStorage.setItem('monthlyTarget',String(x.monthlyTarget));
    if(x.targetAmount!=null)localStorage.setItem('targetAmount',String(x.targetAmount));
    if(x.targetPeriod)localStorage.setItem('targetPeriod',x.targetPeriod);
    if(x.targetMode)localStorage.setItem('targetMode',x.targetMode);
    if(Array.isArray(x.dividends))localStorage.setItem('dividends',JSON.stringify(x.dividends));
  }

  window.importPortfolioBackup=function(input){
    const file=input?.files?.[0];
    if(!file)return;
    const r=new FileReader();
    r.onload=()=>{try{
      const x=JSON.parse(r.result);
      if(!x||(!x.storage&&!Array.isArray(x.stocks)))throw new Error('Geçersiz yedek');
      if(!confirm('Seçilen yedek dosyası mevcut uygulama verilerinin üzerine yazılacak. Devam edilsin mi?'))return;

      if(x.storage&&typeof x.storage==='object'){
        Object.keys(x.storage).forEach(key=>{
          const value=x.storage[key];
          if(value!=null)localStorage.setItem(key,String(value));
        });
      }else{
        restoreLegacyBackup(x);
      }

      alert('Tek seferlik yedek geri yüklendi. Uygulama yeniden açılacak.');
      location.reload();
    }catch(e){
      alert('Yedek dosyası okunamadı. BİST TAKİP tarafından oluşturulmuş .json yedek dosyasını seç.');
    }};
    r.readAsText(file);
  };

  const oldSettings=window.settings;
  if(typeof oldSettings==='function'){
    window.settings=settings=function(){
      const html=oldSettings();
      const block=`<div class="section">Yedekleme ve Geri Yükleme</div><div class="panel"><b>Tek seferlik yedek işlemi</b><div class="small" style="margin-top:6px">Portföy, maliyet, hedef, temettü ve uygulamada saklanan diğer bilgileri JSON dosyasına kaydedebilir veya daha önce oluşturduğun yedeği bir kez seçerek geri yükleyebilirsin.</div><div class="btnrow"><button onclick="exportPortfolioBackup()">YEDEK DOSYASI OLUŞTUR</button><button onclick="pickPortfolioBackup()">TEK SEFERLİK YEDEK YÜKLE</button></div><input id="backupFileInput" type="file" accept="application/json,.json" style="display:none" onchange="importPortfolioBackup(this)"></div>`;
      const pos=html.lastIndexOf('</div>');
      return pos>=0?html.slice(0,pos)+block+html.slice(pos):html+block;
    };
  }

  // Hedef sayfasındaki eski yazım hatasını, hangi hedef şablonu kullanılırsa kullanılsın düzelt.
  const oldTarget=window.target;
  if(typeof oldTarget==='function'){
    window.target=function(){
      return String(oldTarget()).replace(/HİSSESİNİN/g,'HİSSENİN').replace(/hissesinin/g,'hissenin');
    };
  }
})();
