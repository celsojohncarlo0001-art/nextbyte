/* NEXBYTE PWA service worker.
 * Caches only the app shell and same-origin static assets.
 * Supabase Auth, database, storage, realtime and function requests are never cached.
 */
'use strict';

const CACHE_VERSION = 'nexbyte-pwa-v20-pdf-landscape-reading-r1';
const PDFJS_ASSET_CACHE = 'nexbyte-pdfjs-assets-6-5-438';
const PDFJS_ASSET_PREFIX = '/npm/pdfjs-dist@6.5.438/';
const APP_SHELL = [
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './nexbyte-background.png',
  './supabase-config.js'
];

self.addEventListener('install', (event) => {
  const shellUrls = APP_SHELL.map((path) => new URL(path, self.registration.scope).toString());
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then((cache) => cache.addAll(shellUrls))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => key.startsWith('nexbyte-pwa-') && key !== CACHE_VERSION)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

function isSupabaseApiPath(pathname) {
  return /\/(rest\/v1|auth\/v1|storage\/v1|realtime\/v1|functions\/v1)(\/|$)/i.test(pathname);
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const requestUrl = new URL(request.url);

  // Cache only the exact pinned PDF.js distribution assets. PDF.js requests
  // its worker, CMaps, standard fonts, and WASM helpers from this CDN prefix.
  // These are static library resources, never private user documents or API data.
  if (requestUrl.origin === 'https://cdn.jsdelivr.net' && requestUrl.pathname.startsWith(PDFJS_ASSET_PREFIX)) {
    event.respondWith((async () => {
      const cache = await caches.open(PDFJS_ASSET_CACHE);
      const cached = await cache.match(request);
      if (cached) return cached;
      try {
        const response = await fetch(request);
        if (response && response.ok && (response.type === 'cors' || response.type === 'basic')) {
          try { await cache.put(request, response.clone()); }
          catch (cacheError) { /* A cache quota failure must not block online PDF preview. */ }
        }
        return response;
      } catch (networkError) {
        return new Response('PDF viewer asset is not cached on this device yet. Connect to the internet and open the PDF once.', {
          status: 503,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' }
        });
      }
    })());
    return;
  }

  // Never intercept Supabase API traffic or unrelated cross-origin requests.
  if (requestUrl.origin !== self.location.origin || isSupabaseApiPath(requestUrl.pathname)) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request, { cache: 'no-store' })
        .then((response) => {
          if (response && response.ok) {
            const copy = response.clone();
            caches.open(CACHE_VERSION).then((cache) => cache.put('./index.html', copy));
          }
          return response;
        })
        .catch(async () => {
          const cached = await caches.match(new URL('./index.html', self.registration.scope).toString());
          return cached || new Response('NEXBYTE is offline. Open the app once while online, then try again.', {
            status: 503,
            headers: { 'Content-Type': 'text/plain; charset=utf-8' }
          });
        })
    );
    return;
  }

  // Cache-first for same-origin app assets, with a background network refresh.
  const refresh = fetch(request).then((response) => {
    if (response && response.ok && response.type === 'basic') {
      const copy = response.clone();
      return caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy)).then(() => response);
    }
    return response;
  }).catch(() => undefined);

  // Register the refresh synchronously so the browser keeps the worker alive.
  event.waitUntil(refresh);
  event.respondWith(
    caches.match(request).then((cached) => cached || refresh).then((response) => {
      if (response) return response;
      return new Response('This NEXBYTE file is not available offline yet.', {
        status: 503,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' }
      });
    })
  );
});
