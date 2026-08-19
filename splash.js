(function(){
  const style=document.createElement('style');
  style.textContent=`
    #zeusSplash{position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;background:radial-gradient(circle at 50% 42%,#20271f 0,#090b0a 58%,#020303 100%);transition:opacity .55s ease,visibility .55s ease}
    #zeusSplash.hide{opacity:0;visibility:hidden;pointer-events:none}
    .zeusSplashInner{text-align:center;padding:24px;color:#fff}
    .zeusMark{font-size:58px;line-height:1;margin-bottom:18px;filter:drop-shadow(0 0 16px #d5a928);animation:zeusGlow 1.15s ease-in-out infinite alternate}
    .zeusText{font-size:21px;font-weight:950;letter-spacing:4px;color:#e4bd4f}
    .zeusSub{font-size:13px;font-weight:800;letter-spacing:3px;color:#f2f2ed;margin-top:10px}
    @keyframes zeusGlow{from{transform:scale(.96);opacity:.72}to{transform:scale(1.05);opacity:1}}
  `;
  document.head.appendChild(style);
  const splash=document.createElement('div');
  splash.id='zeusSplash';
  splash.innerHTML='<div class="zeusSplashInner"><div class="zeusMark">⚡</div><div class="zeusText">INSPIRED BY ZEUS</div><div class="zeusSub">BİST TAKİP</div></div>';
  document.body.prepend(splash);
  let closed=false;
  const close=()=>{if(closed)return;closed=true;splash.classList.add('hide');setTimeout(()=>splash.remove(),650)};
  // Açılış yazısı her açılışta yaklaşık 3 saniye görünür.
  setTimeout(close,3000);
})();
