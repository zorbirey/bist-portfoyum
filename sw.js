const CACHE_NAME = 'bist-portfoy-v12';
const ASSETS = ['./','./index.html','./manifest.webmanifest','./icon.svg','./prices-sync.js','./restore-features.js','./distribution-pie.js','./target-page.js','./splash.js'];
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
        const [baseRes,restoreRes,pieRes,targetRes,splashRes]=await Promise.all([
          fetch('./prices-sync.js?live='+Date.now(),{cache:'no-store'}),
          fetch('./restore-features.js?live='+Date.now(),{cache:'no-store'}),
          fetch('./distribution-pie.js?live='+Date.now(),{cache:'no-store'}),
          fetch('./target-page.js?live='+Date.now(),{cache:'no-store'}),
          fetch('./splash.js?live='+Date.now(),{cache:'no-store'})
        ]);
        const base=await baseRes.text();
        const restore=await restoreRes.text();
        const pie=await pieRes.text();
        const target=await targetRes.text();
        const splash=await splashRes.text();
        return new Response(base+'\n'+restore+'\n'+pie+'\n'+target+'\n'+splash,{headers:{'Content-Type':'application/javascript; charset=utf-8','Cache-Control':'no-store'}});
      } catch(e) {
        return fetch(event.request,{cache:'no-store'});
      }
    })());
    return;
  }

  if (event.request.url.includes('prices.json') || event.request.url.includes('dividends.json') || event.request.url.includes('restore-features.js') || event.request.url.includes('distribution-pie.js') || event.request.url.includes('target-page.js') || event.request.url.includes('splash.js')) {
    event.respondWith(fetch(event.request, {cache:'no-store'}).catch(() => caches.match(event.request)));
    return;
  }

  event.respondWith(fetch(event.request, {cache:'no-store'}).then(response => {
    const copy = response.clone();
    caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
    return response;
  }).catch(() => caches.match(event.request).then(r => r || caches.match('./index.html'))));
});