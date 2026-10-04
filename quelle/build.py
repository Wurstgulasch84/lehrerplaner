"""Baut aus app.html die installierbare Web-App im Ordner web/ (index.html, Manifest, Service Worker)."""
import json, pathlib, hashlib
here = pathlib.Path(__file__).parent
body = (here / "app.html").read_text()
out = here / "web"
out.mkdir(exist_ok=True)
head = """<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" href="icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="icon-192.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Lehrerplaner">
<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:0}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>
</head>
<body>
"""
(out / "index.html").write_text(head + body + "\n</body>\n</html>\n")
(out / "icon.svg").write_text((here / "icon.svg").read_text())
(out / "manifest.webmanifest").write_text(json.dumps({
    "name": "Lehrerplaner Sachsen 2026/27", "short_name": "Lehrerplaner", "lang": "de",
    "start_url": "./", "scope": "./", "display": "standalone",
    "background_color": "#F2F4F7", "theme_color": "#3D6B8E",
    "icons": [{"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
              {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"},
              {"src": "icon.svg", "sizes": "any", "type": "image/svg+xml"}],
}, ensure_ascii=False, indent=2))
ver = hashlib.sha1((out / "index.html").read_bytes()).hexdigest()[:8]
(out / "sw.js").write_text("""// Offline-Speicher: App-Dateien und Schriften werden zwischengespeichert, damit der Planer ohne Netz startet.
const CACHE = "lehrerplaner-%s";
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
""" % ver)
print("web/ gebaut, Version", ver)
