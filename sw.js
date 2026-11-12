
/* NEXBYTE PWA service worker.
 * Caches app files but never caches private Supabase API traffic.
 */
'use strict';

const CACHE_VERSION = 'nexbyte-pwa-v1';

const APP_SHELL = [
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './supabase-config.js'
];

self.addEventListener('install', (event) => {
  const urls = APP_SHELL.map(
    path => new URL(path, self.registration.scope).toString()
  );

  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then(cache => cache.addAll(urls))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys
          .filter(key =>
            key.startsWith('nexbyte-pwa-') &&
            key !== CACHE_VERSION
          )
          .map(key => caches.delete(key))
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

  const url = new URL(request.url);

  if (
    url.origin !== self.location.origin ||
    isSupabaseApiPath(url.pathname)
  ) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then(response => {
          if (response && response.ok) {
            const copy = response.clone();
            caches.open(CACHE_VERSION)
              .then(cache => cache.put('./index.html', copy));
          }
          return response;
        })
        .catch(async () => {
          const cached = await caches.match(
            new URL('./index.html', self.registration.scope).toString()
          );

          return cached || new Response(
            'NEXBYTE is offline. Open the app once while online.',
            { status: 503 }
          );
        })
    );
    return;
  }

  const refresh = fetch(request)
    .then(response => {
      if (response && response.ok && response.type === 'basic') {
        const copy = response.clone();
        return caches.open(CACHE_VERSION)
          .then(cache => cache.put(request, copy))
          .then(() => response);
      }
      return response;
    })
    .catch(() => undefined);

  event.waitUntil(refresh);

  event.respondWith(
    caches.match(request)
      .then(cached => cached || refresh)
      .then(response => response || new Response(
        'This NEXBYTE file is not available offline yet.',
        { status: 503 }
      ))
  );
});
