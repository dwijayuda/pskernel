'use strict';

const labels = Object.freeze({
  pending: 'Waiting for check', checking: 'Checking', checked: 'Checked',
  partial: 'Partially checked', rejected: 'Rejected', error: 'Check unavailable',
  unsupported: 'Unsupported', untrusted: 'Workspace not trusted', stopped: 'Server stopped'
});

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[character]);
}

function stateLabel(state) { return labels[state] || 'Not checked'; }

/** No scripts, command links, workspace resources, or unescaped compiler text. */
function renderInfoview(info, location, nonce) {
  const state = Object.hasOwn(labels, info?.state) ? info.state : 'pending';
  const declaration = info?.declaration;
  const messages = Array.isArray(info?.messages) ? info.messages : (info?.diagnostics || []);
  const currentLine = location?.line ?? -1;
  const nearby = messages.filter(message => message.range &&
    message.range.start.line <= currentLine && message.range.end.line >= currentLine);
  const renderMessage = message => {
    const severity = ({ 1: 'Error', 2: 'Warning', 3: 'Information', 4: 'Hint' })[message.severity] || 'Message';
    const line = Number.isInteger(message.range?.start?.line) ? ` · line ${message.range.start.line + 1}` : '';
    return `<article class="message"><div class="message-label">${severity}${line}</div><pre>${escapeHtml(message.message)}</pre></article>`;
  };
  const title = location ? `${escapeHtml(location.name)}:${location.line + 1}:${location.character + 1}` : 'ProofScript';
  const checkedDeclaration = declaration?.verified === true && ['checked', 'partial'].includes(state);
  const declarationSection = declaration ? `<section>
    <h2>Declaration</h2><div class="declaration-name">${escapeHtml(declaration.name)}</div>
    <p class="hint">${checkedDeclaration ? 'Checked by the PSC1 compiler.' : 'No current verification for this declaration.'}</p>
    ${declaration.type ? `<h3>Declared type</h3><pre class="type">${escapeHtml(declaration.type)}</pre>` : ''}
  </section>` : `<p class="hint">${location ? 'Move the cursor into a declaration to inspect it.' : 'Open a ProofScript source file to begin.'}</p>`;
  const goals = info?.goalsAvailable === true && Array.isArray(info.goals)
    ? `<section><h2>Goals</h2>${info.goals.length ? info.goals.map(goal => `<pre>${escapeHtml(goal)}</pre>`).join('') : checkedDeclaration ? '<p class="success">Goals accomplished!</p>' : '<p class="hint">No goal snapshot at this position.</p>'}</section>`
    : '<section><h2>Proof state</h2><p class="hint">This compiler provides declaration checks. Cursor-level tactic goals and expected types are not available yet.</p></section>';
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'nonce-${escapeHtml(nonce)}';">
<title>ProofScript Infoview</title>
<style nonce="${escapeHtml(nonce)}">
body { margin:0; padding:16px; color:var(--vscode-foreground); background:var(--vscode-sideBar-background); font:var(--vscode-font-size)/1.55 var(--vscode-font-family); }
header { border-bottom:1px solid var(--vscode-widget-border, transparent); padding-bottom:14px; margin-bottom:18px; }
.location { color:var(--vscode-descriptionForeground); font-size:11px; overflow-wrap:anywhere; }
.status { display:inline-block; margin:9px 0 3px; font-weight:600; }
.state-checked .status,.success { color:var(--vscode-testing-iconPassed, var(--vscode-charts-green)); }
.state-rejected .status,.state-error .status { color:var(--vscode-errorForeground); }
.state-partial .status,.state-unsupported .status { color:var(--vscode-editorWarning-foreground); }
.summary { margin:3px 0 0; overflow-wrap:anywhere; }
section { margin:0 0 22px; }
h2 { margin:0 0 10px; font-size:12px; font-weight:600; letter-spacing:.025em; }
h3 { margin:14px 0 6px; font-size:11px; font-weight:500; color:var(--vscode-descriptionForeground); }
.hint { color:var(--vscode-descriptionForeground); font-size:12px; margin:6px 0; }
pre,.declaration-name { font-family:var(--vscode-editor-font-family); font-size:var(--vscode-editor-font-size); }
pre { white-space:pre-wrap; overflow-wrap:anywhere; margin:5px 0 0; line-height:1.5; }
.type { padding:10px 12px; border-left:2px solid var(--vscode-focusBorder); background:var(--vscode-textCodeBlock-background); }
.declaration-name { font-weight:600; overflow-wrap:anywhere; }
.message { margin:0 0 12px; padding:10px 0; border-bottom:1px solid var(--vscode-widget-border, transparent); }
.message-label { font-size:11px; color:var(--vscode-descriptionForeground); }
details { margin-top:16px; } summary { cursor:pointer; color:var(--vscode-descriptionForeground); }
summary:focus-visible { outline:1px solid var(--vscode-focusBorder); outline-offset:3px; }
.details { font-size:11px; } footer { margin-top:24px; color:var(--vscode-descriptionForeground); font-size:11px; }
</style></head><body class="state-${state}">
<header><div class="location">${title}</div><div class="status" role="status">${stateLabel(state)}</div>
<p class="summary">${escapeHtml(info?.summary || 'Waiting for compiler feedback.')}</p></header>
${declarationSection}${goals}
${nearby.length ? `<section><h2>Messages at cursor</h2>${nearby.map(renderMessage).join('')}</section>` : ''}
<section><h2>All messages (${messages.length})</h2>${messages.length ? messages.map(renderMessage).join('') : '<p class="hint">No compiler messages for this snapshot.</p>'}</section>
<details><summary>Check details</summary><pre class="details">${escapeHtml(JSON.stringify({ version: info?.version, projectGeneration: info?.projectGeneration, elapsedMs: info?.elapsedMs, state: info?.state }, null, 2))}</pre></details>
<footer>Feedback follows the current source version.</footer>
</body></html>`;
}

module.exports = { escapeHtml, stateLabel, renderInfoview };
