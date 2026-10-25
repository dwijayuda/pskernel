import {defineConfig, devices} from '@playwright/test';
export default defineConfig({
  testDir: './tests', fullyParallel: false, workers: 2, retries: 0,
  timeout: 45000,
  reporter: [['list'], ['json', {outputFile: 'results.json'}], ['html', {open: 'never'}]],
  use: {baseURL: 'http://127.0.0.1:4173/webmerek/', trace: 'retain-on-failure', screenshot: 'only-on-failure'},
  webServer: {command: 'python3 -m http.server 4173 --bind 127.0.0.1 --directory ../..', url: 'http://127.0.0.1:4173/webmerek/', reuseExistingServer: false},
  projects: [
    {name: 'chromium-desktop', use: {...devices['Desktop Chrome'], viewport: {width: 1440, height: 1000}}},
    {name: 'chromium-mobile', use: {...devices['Pixel 7']}},
    {name: 'firefox-desktop', use: {...devices['Desktop Firefox'], viewport: {width: 1280, height: 900}}},
    {name: 'webkit-mobile', use: {...devices['iPhone 13']}}
  ]
});
