const NUCLEO='leo-nucleo-v22',AUDIO='leo-audio-v5';
const ARQ=['./','index.html','manifest.webmanifest','modelo.js','lib/three.min.js','lib/GLTFLoader.js','icons/icone-192.png','icons/icone-512.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(NUCLEO).then(c=>c.addAll(ARQ)).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==NUCLEO&&k!==AUDIO).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;
  e.respondWith(caches.match(r,{ignoreSearch:true}).then(hit=>{if(hit)return hit;
    return fetch(r).then(res=>{if(res&&res.ok&&(res.type==='basic'||res.type==='cors')&&!r.headers.has('range')){const cp=res.clone();caches.open(/\.mp3$/.test(new URL(r.url).pathname)?AUDIO:NUCLEO).then(c=>c.put(r,cp)).catch(()=>{})}return res})
  }).catch(()=>caches.match('index.html')))});
