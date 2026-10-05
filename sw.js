// Offline-Speicher: App-Dateien und Schriften werden zwischengespeichert, damit der Planer ohne Netz startet.
const CACHE = "lehrerplaner-556ac6d9";
const FILES = ["./", "index.html", "manifest.webmanifest", "icon.svg", "icon-192.png", "icon-512.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES))); self.skipWaiting(); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))); self.clients.claim(); });
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  /* Seite selbst: zuerst aus dem Netz (damit Updates sofort da sind), ohne Netz nach 3 s aus dem Speicher */
  if (e.request.mode === "navigate") {
    e.respondWith(new Promise(done => {
      let settled = false;
      const fallback = () => caches.match("index.html").then(hit => { if (!settled && hit) { settled = true; done(hit); } });
      const t = setTimeout(fallback, 3000);
      fetch(e.request).then(res => {
        clearTimeout(t);
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put("index.html", copy)); }
        if (!settled) { settled = true; done(res); }
      }).catch(() => { clearTimeout(t); caches.match("index.html").then(hit => { if (!settled) { settled = true; done(hit || Response.error()); } }); });
    }));
    return;
  }
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then(hit => {
    const net = fetch(e.request).then(res => {
      if (res.ok || res.type === "opaque") { const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
      return res;
    }).catch(() => hit);
    return hit || net;
  }));
});
