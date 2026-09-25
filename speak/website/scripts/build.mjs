#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { transform } from 'esbuild';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DIST = path.join(ROOT, 'dist');
const read = (file) => fs.readFileSync(path.join(ROOT, file), 'utf8');
const sha256 = (value) => crypto.createHash('sha256').update(value).digest('hex');
const shortHash = (value) => sha256(value).slice(0, 12);

const sourceHtml = read('index.html');
const appMarker = '<script type="text/babel" data-presets="react">';
const runtimeStart = sourceHtml.indexOf('<script src="https://unpkg.com/react@');
const appOpen = sourceHtml.indexOf(appMarker);
const appContentStart = appOpen + appMarker.length;
const appClose = sourceHtml.indexOf('</script>', appContentStart);

if (runtimeStart < 0 || appOpen < 0 || appClose < 0 || runtimeStart > appOpen) {
  throw new Error('无法定位 index.html 中的 React/Babel 开发运行时');
}

const jsxSource = sourceHtml.slice(appContentStart, appClose);
const compiled = await transform(jsxSource, {
  loader: 'jsx',
  jsx: 'transform',
  jsxFactory: 'React.createElement',
  jsxFragment: 'React.Fragment',
  target: ['es2019'],
  minify: true,
  legalComments: 'none',
});

const scenesSource = read('scenes.json');
const scenesVersion = shortHash(scenesSource);
const productionAppCode = compiled.code.replaceAll('./scenes.json', `./scenes.json?v=${scenesVersion}`);
if (productionAppCode === compiled.code) throw new Error('生产脚本未找到 scenes.json 请求，无法注入内容版本');
const appFile = `app.${shortHash(productionAppCode)}.js`;
const vendorSources = [
  ['react', path.join(ROOT, 'node_modules/react/umd/react.production.min.js')],
  ['react-dom', path.join(ROOT, 'node_modules/react-dom/umd/react-dom.production.min.js')],
];

for (const [, file] of vendorSources) {
  if (!fs.existsSync(file)) throw new Error(`缺少生产运行时：${file}`);
}

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(path.join(DIST, 'vendor'), { recursive: true });
fs.mkdirSync(path.join(DIST, 'assets'), { recursive: true });

const vendorFiles = [];
for (const [name, source] of vendorSources) {
  const bytes = fs.readFileSync(source);
  const targetName = `${name}.${shortHash(bytes)}.js`;
  fs.writeFileSync(path.join(DIST, 'vendor', targetName), bytes);
  vendorFiles.push(targetName);
}

fs.writeFileSync(path.join(DIST, appFile), productionAppCode);

const runtimeEnd = appClose + '</script>'.length;
const productionScripts = [
  `<script defer src="./vendor/${vendorFiles[0]}"></script>`,
  `<script defer src="./vendor/${vendorFiles[1]}"></script>`,
  `<script defer src="./${appFile}"></script>`,
].join('\n');
const productionHtml = `${sourceHtml.slice(0, runtimeStart)}${productionScripts}${sourceHtml.slice(runtimeEnd)}`;

for (const forbidden of ['unpkg.com', 'text/babel', 'react.development.js', 'babel.min.js']) {
  if (productionHtml.includes(forbidden)) throw new Error(`生产 HTML 仍包含开发依赖：${forbidden}`);
}

fs.writeFileSync(path.join(DIST, 'index.html'), productionHtml);
for (const file of ['scenes.json', 'terms.html', 'privacy.html']) {
  fs.copyFileSync(path.join(ROOT, file), path.join(DIST, file));
}
for (const file of ['app-icon-180.png']) {
  fs.copyFileSync(path.join(ROOT, 'assets', file), path.join(DIST, 'assets', file));
}
fs.cpSync(path.join(ROOT, 'audio'), path.join(DIST, 'audio'), { recursive: true });

const manifest = {
  builtAt: new Date().toISOString(),
  sourceIndexSha256: sha256(sourceHtml),
  sourceScenesSha256: sha256(scenesSource),
  scenesVersion,
  entrypoints: {
    html: 'index.html',
    app: appFile,
    react: `vendor/${vendorFiles[0]}`,
    reactDom: `vendor/${vendorFiles[1]}`,
  },
};
fs.writeFileSync(path.join(DIST, 'build-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);

console.log(`Built dist/ with ${appFile}`);
console.log(`Vendored ${vendorFiles.join(', ')}`);
