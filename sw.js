const CACHE_NAME = 'bist-portfoy-v14';
const ASSETS = ['./','./index.html','./manifest.webmanifest','./icon.svg','./prices-sync.js','./restore-features.js','./distribution-pie.js','./target-page.js','./splash.js','./backup-tools.js'];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS)));
  self.skipWaiting();
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  if (event.request.url.includes('prices-sync.js')) {
    event.respondWith((async()=>{
      try {
        const files=['prices-sync.js','restore-features.js','distribution-pie.js','target-page.js','splash.js','backup-tools.js'];
        const responses=await Promise.all(files.map(f=>fetch('./'+f+'?live='+Date.now(),{cache:'no-store'})));
        const texts=await Promise.all(responses.map(r=>r.text()));
        return new Response(texts.join('\n'),{headers:{'Content-Type':'application/javascript; charset=utf-8','Cache-Control':'no-store'}});
      } catch(e) { return fetch(event.request,{cache:'no-store'}); }
    })()); return;
  }
  if (['prices.json','dividends.json','restore-features.js','distribution-pie.js','target-page.js','splash.js','backup-tools.js'].some(x=>event.request.url.includes(x))) {
    event.respondWith(fetch(event.request,{cache:'no-store'}).catch(()=>caches.match(event.request))); return;
  }
  event.respondWith(fetch(event.request,{cache:'no-store'}).then(response=>{const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put(event.request,copy));return response;}).catch(()=>caches.match(event.request).then(r=>r||caches.match('./index.html'))));
});