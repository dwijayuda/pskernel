import {test, expect} from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import {readFile, mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
const manifest = JSON.parse(await readFile(new URL('../../generated-manifest.json', import.meta.url), 'utf8'));

for (const slug of manifest.pages) {
  test('page quality: ' + slug, async ({page}, info) => {
    const errors = [];
    const remote = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('response', response => { if (response.status() >= 400) errors.push(response.status() + ' ' + response.url()); });
    page.on('request', request => { if (!request.url().startsWith('http://127.0.0.1:4173/') && !request.url().startsWith('data:')) remote.push(request.url()); });
    const response = await page.goto(slug);
    expect(response.status()).toBe(200);
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', 'noindex, nofollow');
    const widths = await page.evaluate(() => ({scroll: document.documentElement.scrollWidth, viewport: window.innerWidth}));
    expect(widths.scroll).toBeLessThanOrEqual(widths.viewport + 1);
    expect(errors).toEqual([]);
    expect(remote).toEqual([]);
    const scan = await new AxeBuilder({page}).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
    await info.attach('axe-summary', {body: JSON.stringify({url: slug, violations: scan.violations, incomplete: scan.incomplete.map(item => item.id)}), contentType: 'application/json'});
    expect(scan.violations).toEqual([]);
    if (['index.html', 'paket.html', 'kontak.html', 'karya.html'].includes(slug)) {
      await mkdir(resolve('../.artifacts/screenshots'), {recursive: true});
      await page.screenshot({path: resolve('../.artifacts/screenshots/' + info.project.name + '-' + slug.replace('.html', '') + '.png'), fullPage: true});
    }
  });
}

test('navigation and keyboard menu', async ({page}) => {
  await page.goto('index.html');
  const menu = page.locator('.menu-toggle');
  const compact = await page.evaluate(() => matchMedia('(max-width: 900px)').matches);
  if (compact) {
    await expect(menu).toBeVisible();
    await menu.click();
    await expect(menu).toHaveAttribute('aria-expanded', 'true');
    await page.keyboard.press('Escape');
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
    await expect(menu).toBeFocused();
    await menu.click();
  } else {
    await expect(menu).toBeHidden();
  }
  await page.locator('#main-nav').getByRole('link', {name: 'Layanan', exact: true}).click();
  await expect(page).toHaveURL(/layanan.html$/);
  await expect(page.locator('#main-nav a[aria-current="page"]')).toHaveText('Layanan');
});

test('brief: local generation, literal input, download and invalidation', async ({page}) => {
  const dataRequests = [];
  page.on('request', request => { if (request.method() !== 'GET') dataRequests.push(request.url()); });
  await page.goto('kontak.html?paket=lengkap');
  await expect(page.locator('#paket')).toHaveValue('lengkap');
  await page.locator('#bisnis').fill('Contoh & <script>window.bad = true</script>');
  await page.locator('#anggaran').selectOption({label: 'Rp10–15 juta'});
  await page.locator('#tujuan').fill('Memperjelas layanan pelatihan, tanpa mengirim data pribadi.');
  await page.getByRole('button', {name: 'Susun ringkasan brief'}).click();
  await expect(page.locator('#brief-output')).toBeVisible();
  await expect(page.locator('#brief-text')).toContainText('<script>window.bad = true</script>');
  expect(await page.evaluate(() => window.bad)).toBeUndefined();
  await expect(page.locator('#brief-status')).toContainText('Belum dikirim');
  await expect(page.locator('#send-options')).toBeHidden();
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', {name: 'Unduh brief (.txt)'}).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe('brief-webmerek.txt');
  const stream = await download.createReadStream();
  let downloaded = '';
  for await (const chunk of stream) downloaded += chunk.toString();
  expect(downloaded).toContain('BRIEF WEBMEREK — BELUM DIKIRIM');
  expect(downloaded).toContain('Merek + Website');
  expect(downloaded).toContain('<script>window.bad = true</script>');
  expect(dataRequests).toEqual([]);
  expect(await page.evaluate(() => localStorage.length)).toBe(0);
  await page.locator('#tujuan').fill('Tujuan berubah');
  await expect(page.locator('#brief-output')).toBeHidden();
  await expect(page.locator('#brief-text')).toHaveText('');
});

test('blank required fields never create brief', async ({page}) => {
  await page.goto('kontak.html');
  await page.getByRole('button', {name: 'Susun ringkasan brief'}).click();
  await expect(page.locator('#brief-output')).toBeHidden();
  await page.locator('#bisnis').fill('   ');
  await page.locator('#paket').selectOption('fondasi');
  await page.locator('#anggaran').selectOption({label: 'Belum ditentukan'});
  await page.locator('#tujuan').fill('   ');
  await page.getByRole('button', {name: 'Susun ringkasan brief'}).click();
  await expect(page.locator('#brief-status')).toContainText('tidak boleh hanya berisi spasi');
  await expect(page.locator('#brief-text')).toHaveText('');
});

test('assessment deterministic zero and full scores', async ({page}) => {
  await page.goto('cek-merek.html');
  for (let i = 1; i <= 5; i++) await page.locator('#a' + i).selectOption('0');
  await page.getByRole('button', {name: 'Lihat prioritas saya'}).click();
  await expect(page.locator('#assessment-score')).toContainText('0 dari 10');
  await expect(page.locator('#assessment-tips li')).toHaveCount(5);
  for (let i = 1; i <= 5; i++) await page.locator('#a' + i).selectOption('2');
  await expect(page.locator('#assessment-result')).toBeHidden();
  await page.getByRole('button', {name: 'Lihat prioritas saya'}).click();
  await expect(page.locator('#assessment-score')).toContainText('10 dari 10');
  await expect(page.locator('#assessment-tips li')).toHaveCount(1);
  expect(await page.evaluate(() => localStorage.length)).toBe(0);
});

test('FAQ opens with keyboard', async ({page}) => {
  await page.goto('faq.html');
  const first = page.locator('summary').first();
  await first.focus();
  await page.keyboard.press('Enter');
  await expect(page.locator('details').first()).toHaveAttribute('open', '');
});

test('without JavaScript navigation and copy survive; forms stay inert', async ({browser}) => {
  const context = await browser.newContext({javaScriptEnabled: false, viewport: {width: 390, height: 844}});
  const page = await context.newPage();
  await page.goto('http://127.0.0.1:4173/webmerek/kontak.html');
  await expect(page.locator('#main-nav')).toBeVisible();
  // Check the fieldset attribute and actual controls. Playwright's disabled
  // assertion is intended for controls, not the fieldset grouping element.
  await expect(page.locator('#brief-form fieldset')).toHaveAttribute('disabled', '');
  const controls = page.locator('#brief-form input, #brief-form select, #brief-form textarea, #brief-form button');
  expect(await controls.count()).toBe(7);
  for (const control of await controls.all()) await expect(control).toBeDisabled();
  await expect(page.locator('noscript')).toBeVisible();
  await expect(page.getByRole('link', {name: /Unduh template kosong/})).toBeVisible();
  await context.close();
});

test('320px layout and reduced motion', async ({page}) => {
  await page.setViewportSize({width: 320, height: 800});
  await page.emulateMedia({reducedMotion: 'reduce'});
  await page.goto('index.html');
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(321);
  expect(await page.evaluate(() => getComputedStyle(document.documentElement).scrollBehavior)).toBe('auto');
});
