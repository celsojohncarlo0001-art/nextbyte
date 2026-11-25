#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = path.resolve(__dirname, '..');
const errors = [];
const ok = (label) => console.log(`PASS  ${label}`);
const fail = (label, detail) => errors.push(`${label}: ${detail}`);

function checkSyntax(file, source) {
  try { new vm.Script(source, { filename: file }); ok(`JavaScript syntax: ${file}`); }
  catch (error) { fail(`JavaScript syntax: ${file}`, error.message); }
}

const htmlPath = path.join(root, 'index.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const inlineScripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi)]
  .filter((m) => !/\bsrc\s*=/.test(m[1]) && m[2].trim());
if (!inlineScripts.length) fail('HTML scripts', 'No inline script blocks were found.');
else {
  inlineScripts.forEach((m, i) => checkSyntax(`index.html:inline-script-${i + 1}`, m[2]));
  ok(`HTML inline JavaScript blocks found: ${inlineScripts.length}`);
}

for (const file of ['sw.js', 'supabase-config.js', 'api/link-preview.js']) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) { fail(file, 'Required project file is missing.'); continue; }
  checkSyntax(file, fs.readFileSync(full, 'utf8'));
}

if (/user-scalable\s*=\s*no|max(?:imum)?-scale\s*=\s*1(?:\.0)?/i.test(html)) {
  fail('Viewport accessibility', 'The viewport still disables user zoom.');
} else ok('Viewport allows browser zoom');

const iconStart = html.indexOf('var ICONS={');
const iconEnd = html.indexOf('\n};', iconStart);
if (iconStart < 0 || iconEnd < 0) fail('Icon registry', 'Could not locate the ICONS object.');
else {
  const iconBlock = html.slice(iconStart, iconEnd);
  const defined = new Set([...iconBlock.matchAll(/^\s*([A-Za-z_$][\w$]*):/gm)].map((m) => m[1]));
  const used = new Set([...html.matchAll(/\bicf?\(\s*['"]([A-Za-z_$][\w$]*)['"]/g)].map((m) => m[1]));
  const assigned = new Set([...html.matchAll(/\bICONS\.([A-Za-z_$][\w$]*)\s*=/g)].map((m) => m[1]));
  const missing = [...used].filter((name) => !defined.has(name) && !assigned.has(name));
  if (missing.length) fail('Icon registry', `Missing literal icon definitions: ${missing.join(', ')}`);
  else ok(`Icon registry: ${defined.size} base names, all ${used.size} literal references resolved`);
}

const sw = fs.readFileSync(path.join(root, 'sw.js'), 'utf8');
const version = (sw.match(/const\s+CACHE_VERSION\s*=\s*['"]([^'"]+)['"]/i) || [])[1];
if (version !== 'nexbyte-pwa-v26-icons-music-lockin-room') fail('Service worker cache', `Expected v26 cache namespace, found ${version || 'none'}.`);
else ok(`Service-worker cache namespace: ${version}`);

const manifestPath = path.join(root, 'manifest.webmanifest');
try {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  ok('PWA manifest JSON parses');
  for (const icon of (manifest.icons || [])) {
    const iconPath = path.join(root, icon.src.replace(/^\.\//, ''));
    if (!fs.existsSync(iconPath)) { fail('PWA icon', `${icon.src} does not exist.`); continue; }
    const png = fs.readFileSync(iconPath);
    if (png.length < 24 || png.toString('hex', 0, 8) !== '89504e470d0a1a0a') { fail('PWA icon', `${icon.src} is not a PNG.`); continue; }
    const width = png.readUInt32BE(16), height = png.readUInt32BE(20);
    const expected = (icon.sizes || '').split('x').map(Number);
    if (expected.length === 2 && (width !== expected[0] || height !== expected[1])) fail('PWA icon dimensions', `${icon.src}: manifest says ${icon.sizes}, file is ${width}x${height}.`);
    else ok(`PWA icon dimensions: ${icon.src} ${width}x${height}`);
  }
} catch (error) { fail('PWA manifest', error.message); }

for (const [label, needle] of [
  ['Music narrow-screen layout', 'grid-template-areas:"play track track track" "fav playlist download delete"'],
  ['Lock-In absolute timer deadline', 'LOCK.endsAt=LOCK.startedAt+LOCK.duration*1000'],
  ['Whiteboard stale-write guard', 'This whiteboard changed on another device before your save'],
  ['Supabase room visibility migration docs', 'NEXTBYTE_STUDY_ROOM_VISIBILITY.sql'],
  ['Supabase room repair migration docs', 'NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql'],
]) {
  if (html.includes(needle) || fs.readFileSync(path.join(root, 'README.md'), 'utf8').includes(needle)) ok(label);
  else fail(label, 'Expected implementation/documentation marker not found.');
}

if (errors.length) {
  console.error('\nVALIDATION FAILED');
  for (const error of errors) console.error(`FAIL  ${error}`);
  process.exitCode = 1;
} else console.log('\nAll project static validation checks passed.');
