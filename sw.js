/* Prumo: guarda o app no aparelho para abrir rápido e funcionar sem internet.
   Ao publicar uma versão nova, aumente o número abaixo. */
const VERSION = "prumo-v15";
const SHELL = ["./", "index.html", "config.js", "manifest.webmanifest",
  "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Dados e contas sempre pela internet
  if (url.hostname.endsWith("supabase.co") || url.hostname.includes("googleapis.com") && url.pathname.startsWith("/books") || url.hostname === "openlibrary.org") return;
  // Páginas: tenta a internet primeiro para pegar a versão nova
  if (req.mode === "navigate" || url.pathname.endsWith("index.html") || url.pathname.endsWith("config.js")) {
    e.respondWith(fetch(req).then(r => { const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); return r; })
      .catch(() => caches.match(req).then(r => r || caches.match("index.html"))));
    return;
  }
  // Demais arquivos (ícones, fontes, bibliotecas): usa o que já está guardado
  e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(r => {
    if (r.ok && (url.origin === location.origin || url.hostname.includes("fonts.") || url.hostname === "cdn.jsdelivr.net")) {
      const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy));
    }
    return r;
  })));
});
self.addEventListener("notificationclick", e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: "window" }).then(list => list.length ? list[0].focus() : self.clients.openWindow("./")));
});
