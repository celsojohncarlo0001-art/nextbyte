'use strict';

// Secure, bounded metadata fetch for NEXTBYTE chat link cards.
// This endpoint never forwards cookies/credentials and never executes remote code.
const dns = require('node:dns').promises;
const net = require('node:net');
const http = require('node:http');
const https = require('node:https');

const MAX_BYTES = 512 * 1024;
const TIMEOUT_MS = 5000;
const REDIRECTS = 3;

function ipv4ToNumber(ip) {
  return ip.split('.').reduce((n, part) => ((n << 8) | Number(part)) >>> 0, 0);
}
function inV4(ip, base, bits) {
  const mask = bits === 0 ? 0 : (0xffffffff << (32 - bits)) >>> 0;
  return (ipv4ToNumber(ip) & mask) === (ipv4ToNumber(base) & mask);
}
function isPublicIp(ip) {
  const family = net.isIP(ip);
  if (family === 4) {
    const denied = [
      ['0.0.0.0', 8], ['10.0.0.0', 8], ['100.64.0.0', 10], ['127.0.0.0', 8],
      ['169.254.0.0', 16], ['172.16.0.0', 12], ['192.0.0.0', 24], ['192.0.2.0', 24],
      ['192.168.0.0', 16], ['198.18.0.0', 15], ['198.51.100.0', 24], ['203.0.113.0', 24],
      ['224.0.0.0', 4], ['240.0.0.0', 4]
    ];
    return !denied.some(([base, bits]) => inV4(ip, base, bits));
  }
  if (family === 6) {
    const value = ip.toLowerCase().split('%')[0];
    const mapped = value.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/);
    if (mapped) return isPublicIp(mapped[1]);
    if (value === '::' || value === '::1' || value.startsWith('fc') || value.startsWith('fd') ||
        value.startsWith('fe8') || value.startsWith('fe9') || value.startsWith('fea') || value.startsWith('feb') ||
        value.startsWith('fec') || value.startsWith('fed') || value.startsWith('ff') ||
        value.startsWith('2001:db8:') || value.startsWith('2001:10:') || value.startsWith('2001:2:') || value.startsWith('2002:')) return false;
    // Accept only global-unicast 2000::/3, excluding the special-purpose ranges above.
    const first = parseInt(value.split(':')[0] || '0', 16);
    return first >= 0x2000 && first <= 0x3fff;
  }
  return false;
}
async function resolveSafeHost(hostname) {
  const host = hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (!host || host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local') || host.endsWith('.internal')) {
    throw new Error('Private or local network hosts are not allowed.');
  }
  const literalFamily = net.isIP(host);
  if (literalFamily) {
    if (!isPublicIp(host)) throw new Error('Private or local network addresses are not allowed.');
    return { address: host, family: literalFamily };
  }
  const records = await dns.lookup(host, { all: true, verbatim: true });
  if (!records.length || records.some(record => !isPublicIp(record.address))) {
    throw new Error('The host resolves to a private or restricted network address.');
  }
  return { address: records[0].address, family: records[0].family };
}
function requestLimited(url, depth) {
  return resolveSafeHost(url.hostname).then(({ address, family }) => new Promise((resolve, reject) => {
    const transport = url.protocol === 'https:' ? https : http;
    const agent = url.protocol === 'https:'
      ? new https.Agent({ keepAlive: false, lookup: (_host, _opts, callback) => callback(null, address, family) })
      : new http.Agent({ keepAlive: false, lookup: (_host, _opts, callback) => callback(null, address, family) });
    const request = transport.request({
      protocol: url.protocol, hostname: url.hostname, port: url.port || undefined,
      path: url.pathname + url.search, method: 'GET', agent,
      servername: url.protocol === 'https:' ? url.hostname : undefined,
      headers: { 'User-Agent': 'NEXTBYTE-LinkPreview/1.0', 'Accept': 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.1', 'Accept-Encoding': 'identity' }
    }, response => {
      response.on('error', () => {});
      const status = response.statusCode || 0;
      if ([301, 302, 303, 307, 308].includes(status)) {
        const location = response.headers.location;
        response.destroy(); agent.destroy();
        if (!location || depth >= REDIRECTS) return reject(new Error('The website redirected too many times.'));
        let next;
        try { next = new URL(location, url); } catch (_) { return reject(new Error('The website returned an invalid redirect.')); }
        if (!['http:', 'https:'].includes(next.protocol) || next.username || next.password) return reject(new Error('The redirect destination is not supported.'));
        return requestLimited(next, depth + 1).then(resolve, reject);
      }
      const type = String(response.headers['content-type'] || '').toLowerCase();
      if (status < 200 || status >= 300) { response.destroy(); agent.destroy(); return reject(new Error('The website could not be previewed.')); }
      if (!type.includes('text/html') && !type.includes('application/xhtml+xml') && !type.includes('application/json')) { response.destroy(); agent.destroy(); return resolve({ body: '', contentType: type, finalUrl: url.href }); }
      const chunks = []; let total = 0; let finished = false;
      response.on('data', chunk => {
        total += chunk.length;
        if (total > MAX_BYTES) { finished = true; response.destroy(); agent.destroy(); resolve({ body: Buffer.concat(chunks).toString('utf8'), contentType: type, finalUrl: url.href }); return; }
        chunks.push(chunk);
      });
      response.on('end', () => { if (!finished) { agent.destroy(); resolve({ body: Buffer.concat(chunks).toString('utf8'), contentType: type, finalUrl: url.href }); } });
      response.on('error', error => { if (!finished) { agent.destroy(); reject(error); } });
    });
    request.setTimeout(TIMEOUT_MS, () => request.destroy(new Error('Preview request timed out.')));
    request.on('error', error => { agent.destroy(); reject(error); });
    request.end();
  }));
}
function decodeEntities(value) {
  return String(value || '').replace(/&amp;/gi, '&').replace(/&quot;/gi, '"').replace(/&#39;|&apos;/gi, "'")
    .replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&#(\d+);/g, (_m, n) => String.fromCodePoint(Math.min(0x10ffff, Number(n))))
    .replace(/&#x([\da-f]+);/gi, (_m, n) => String.fromCodePoint(Math.min(0x10ffff, parseInt(n, 16))));
}
function stripText(value) { return decodeEntities(String(value || '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()).slice(0, 500); }
function metaMap(html) {
  const map = Object.create(null);
  const tags = html.match(/<meta\b[^>]*>/gi) || [];
  tags.forEach(tag => {
    const attrs = Object.create(null);
    tag.replace(/([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g, (_m, key, a, b, c) => { attrs[key.toLowerCase()] = a || b || c || ''; return _m; });
    const key = String(attrs.property || attrs.name || attrs.itemprop || '').toLowerCase();
    if (key && attrs.content && !map[key]) map[key] = attrs.content;
  });
  return map;
}
async function publicImageUrl(value, base) {
  if (!value) return null;
  try {
    const image = new URL(decodeEntities(value), base);
    if (!['http:', 'https:'].includes(image.protocol) || image.username || image.password) return null;
    await resolveSafeHost(image.hostname);
    return image.href.slice(0, 2048);
  } catch (_) { return null; }
}
module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  if (req.method !== 'GET') { res.statusCode = 405; res.end(JSON.stringify({ error: 'Method not allowed.' })); return; }
  let target;
  try {
    const requestUrl = new URL(req.url, 'https://nextbyte.invalid');
    target = new URL(requestUrl.searchParams.get('url') || '');
    if (!['http:', 'https:'].includes(target.protocol) || target.username || target.password || target.href.length > 2048) throw new Error('Enter a valid HTTP or HTTPS URL.');
  } catch (error) { res.statusCode = 400; res.end(JSON.stringify({ error: error.message || 'Invalid URL.' })); return; }
  try {
    const youtubeHost = /(^|\.)((youtube\.com)|(youtube-nocookie\.com)|(youtu\.be))$/i.test(target.hostname);
    if (youtubeHost) {
      const videoId = target.hostname.toLowerCase() === 'youtu.be' ? target.pathname.split('/').filter(Boolean)[0] :
        (target.searchParams.get('v') || (target.pathname.match(/\/(?:shorts|embed|live)\/([A-Za-z0-9_-]{6,20})/) || [])[1]);
      if (videoId && /^[A-Za-z0-9_-]{6,20}$/.test(videoId)) {
        const oembedUrl = new URL('https://www.youtube.com/oembed');
        oembedUrl.searchParams.set('url', target.href); oembedUrl.searchParams.set('format', 'json');
        try {
          const oembed = await requestLimited(oembedUrl, 0);
          const data = JSON.parse(oembed.body || '{}');
          const image = await publicImageUrl(data.thumbnail_url || ('https://i.ytimg.com/vi/' + videoId + '/hqdefault.jpg'), target.href);
          res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.statusCode = 200;
          res.end(JSON.stringify({ title: stripText(data.title || 'YouTube video').slice(0, 180), description: 'YouTube video' + (data.author_name ? ' · ' + stripText(data.author_name).slice(0, 100) : ''), image, siteName: 'YouTube', domain: 'youtube.com', canonical: target.href, type: 'youtube', videoId }));
          return;
        } catch (_) {
          const image = await publicImageUrl('https://i.ytimg.com/vi/' + videoId + '/hqdefault.jpg', target.href);
          res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.statusCode = 200;
          res.end(JSON.stringify({ title: 'YouTube video', description: 'Video preview information is unavailable.', image, siteName: 'YouTube', domain: 'youtube.com', canonical: target.href, type: 'youtube', videoId }));
          return;
        }
      }
    }
    const result = await requestLimited(target, 0);
    const meta = metaMap(result.body || '');
    const titleTag = (result.body || '').match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
    const title = stripText(meta['og:title'] || meta['twitter:title'] || (titleTag && titleTag[1]) || target.hostname).slice(0, 180);
    const description = stripText(meta['og:description'] || meta.description || meta['twitter:description'] || '').slice(0, 320);
    let canonical = result.finalUrl;
    const canonicalTag = (result.body || '').match(/<link\b(?=[^>]*\brel\s*=\s*["'][^"']*canonical)[^>]*\bhref\s*=\s*(?:"([^"]+)"|'([^']+)'|([^\s>]+))/i);
    if (canonicalTag) { try { const candidate = new URL(decodeEntities(canonicalTag[1] || canonicalTag[2] || canonicalTag[3]), result.finalUrl); if (['http:', 'https:'].includes(candidate.protocol)) canonical = candidate.href; } catch (_) {} }
    const image = await publicImageUrl(meta['og:image'] || meta['og:image:url'] || meta['twitter:image'] || '', result.finalUrl);
    const response = { title, description, image, siteName: stripText(meta['og:site_name'] || target.hostname).slice(0, 100), domain: new URL(result.finalUrl).hostname, canonical, contentType: result.contentType || 'text/html', type: 'website' };
    res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.statusCode = 200; res.end(JSON.stringify(response));
  } catch (error) {
    res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.statusCode = 422;
    res.end(JSON.stringify({ error: error.message || 'This link could not be previewed.' }));
  }
};
