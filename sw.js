/* Prumo: guarda o app no aparelho para abrir rápido e funcionar sem internet.
   Ao publicar uma versão nova, aumente o número abaixo. */
const VERSION = "prumo-v89";
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
  // Vídeo direto da internet (o iPhone precisa carregar em partes)
  if (url.pathname.endsWith(".mp4")) return;
  // Dados e contas sempre pela internet
  if (url.hostname.endsWith("supabase.co") || url.hostname.includes("googleapis.com") && url.pathname.startsWith("/books") || url.hostname === "openlibrary.org") return;
  // Páginas: tenta a internet primeiro para pegar a versão nova
  if (req.mode === "navigate" || url.pathname.endsWith("index.html") || url.pathname.endsWith("config.js")) {
    // "no-cache": confere com o servidor sempre (o GitHub guarda a página por até 10 min)
    e.respondWith(fetch(req.url, { cache: "no-cache", credentials: "same-origin" }).then(r => { const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); return r; })
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
// Avisos das equipes chegando com o app fechado
self.addEventListener("push", e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (x) { d = { title: "Prumo", body: e.data ? e.data.text() : "" }; }
  self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(l => l.forEach(c => c.postMessage({ type: "prumo-push" })));
  e.waitUntil(self.registration.showNotification(d.title || "Prumo", {
    body: d.body || "", icon: "icons/icon-192.png", badge: "icons/icon-192.png",
    tag: d.tag || undefined, renotify: !!d.tag, data: { url: d.url || "./" }
  }));
});
self.addEventListener("notificationclick", e => {
  e.notification.close();
  const target = new URL((e.notification.data && e.notification.data.url) || "./", self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(list => {
    const w = list.find(c => c.url.startsWith(self.registration.scope));
    if (w) { w.postMessage({ type: "prumo-open", url: target }); return w.focus(); }
    return self.clients.openWindow(target);
  }));
});
