(function(){
  function backupPayload(){
    return {
      app:'BIST Portföy',version:1,exportedAt:new Date().toISOString(),
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
    const a=document.createElement('a');a.href=URL.createObjectURL(blob);
    const d=new Date();const ds=[d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-');
    a.download='bist-portfoy-yedek-'+ds+'.json';document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(a.href),1000);
  };
  window.pickPortfolioBackup=function(){document.getElementById('backupFileInput')?.click();};
  window.importPortfolioBackup=function(input){
    const file=input?.files?.[0];if(!file)return;
    const r=new FileReader();r.onload=()=>{try{
      const x=JSON.parse(r.result);if(!x||!Array.isArray(x.stocks))throw new Error('Geçersiz yedek');
      if(!confirm('Bu yedek mevcut portföy bilgilerini değiştirecek. Devam edilsin mi?'))return;
      localStorage.setItem('stocks',JSON.stringify(x.stocks));
      if(x.annualTarget!=null)localStorage.setItem('annualTarget',String(x.annualTarget));
      if(x.monthlyTarget!=null)localStorage.setItem('monthlyTarget',String(x.monthlyTarget));
      if(x.targetAmount!=null)localStorage.setItem('targetAmount',String(x.targetAmount));
      if(x.targetPeriod)localStorage.setItem('targetPeriod',x.targetPeriod);
      if(x.targetMode)localStorage.setItem('targetMode',x.targetMode);
      if(Array.isArray(x.dividends))localStorage.setItem('dividends',JSON.stringify(x.dividends));
      alert('Yedek geri yüklendi. Uygulama yeniden açılacak.');location.reload();
    }catch(e){alert('Yedek dosyası okunamadı. Doğru BIST Portföy yedek dosyasını seç.');}};r.readAsText(file);
  };

  const oldSettings=window.settings;
  window.settings=settings=function(){
    const html=oldSettings();
    const block=`<div class="section">Yedekleme ve Aktarma</div><div class="panel"><b>Portföy yedeği</b><div class="small" style="margin-top:6px">APK'ya veya başka bir telefona geçmeden önce portföy, maliyet ve hedef bilgilerini JSON dosyasına kaydet.</div><div class="btnrow"><button onclick="exportPortfolioBackup()">YEDEK DOSYASI OLUŞTUR</button><button onclick="pickPortfolioBackup()">YEDEĞİ GERİ YÜKLE</button></div><input id="backupFileInput" type="file" accept="application/json,.json" style="display:none" onchange="importPortfolioBackup(this)"></div>`;
    return html.replace('</div>',block+'</div>');
  };
})();
