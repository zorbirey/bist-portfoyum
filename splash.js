(function(){
  const style=document.createElement('style');
  style.textContent=`
    #zeusSplash{position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;background:#f5f7f5;transition:opacity .55s ease,visibility .55s ease}
    #zeusSplash.hide{opacity:0;visibility:hidden;pointer-events:none}
    .zeusSplashInner{text-align:center;padding:24px}
    .zeusMark{font-size:46px;line-height:1;margin-bottom:16px;animation:zeusGlow 1.2s ease-in-out infinite alternate}
    .zeusText{font-size:21px;font-weight:950;letter-spacing:4px;color:#26352f}
    .zeusSub{font-size:11px;letter-spacing:2px;color:#74817b;margin-top:8px}
    @keyframes zeusGlow{from{transform:scale(.96);opacity:.65}to{transform:scale(1.04);opacity:1}}
  `;
  document.head.appendChild(style);
  const splash=document.createElement('div');
  splash.id='zeusSplash';
  splash.innerHTML='<div class="zeusSplashInner"><div class="zeusMark">⚡</div><div class="zeusText">INSPIRED FROM ZEUS</div><div class="zeusSub">BIST PORTFÖY</div></div>';
  document.body.prepend(splash);
  const close=()=>{splash.classList.add('hide');setTimeout(()=>splash.remove(),650)};
  if(document.readyState==='complete')setTimeout(close,1100);else window.addEventListener('load',()=>setTimeout(close,1100),{once:true});
  setTimeout(close,2600);
})();
