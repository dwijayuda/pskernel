import {chromium} from '@playwright/test';
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const browser = await chromium.launch();
try {
  const page = await browser.newPage({viewport: {width: 1200, height: 630}, deviceScaleFactor: 1});
  const svg = await readFile(resolve('../assets/og.svg'), 'utf8');
  await page.setContent('<!doctype html><html lang="id"><head><title>WebMerek artwork</title></head><body style="margin:0">' + svg + '</body></html>');
  await page.screenshot({path: resolve('../assets/og.png')});
} finally { await browser.close(); }
