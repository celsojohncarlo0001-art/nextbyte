/* NEXBYTE PWA service worker.
 * Caches only the app shell and same-origin static assets.
 * Supabase Auth, database, storage, realtime and function requests are never cached.
 */
'use strict';

const CACHE_VERSION = 'nexbyte-pwa-v2';
const APP_SHELL = [
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
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
  // Never intercept cross-origin requests or Supabase API traffic.
  if (requestUrl.origin !== self.location.origin || isSupabaseApiPath(requestUrl.pathname)) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
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
