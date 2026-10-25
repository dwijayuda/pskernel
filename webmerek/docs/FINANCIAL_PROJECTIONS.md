# Financial scenarios — planning assumptions, not forecasts

Version: 25 October 2026. Currency IDR. These are internally constructed operating scenarios, not observed demand, investment advice or verified income. `../scripts/finance.py` reproduces the monthly arithmetic from `../site.json`; GitHub Actions checks expected totals.

## Accounting assumptions

Recognize project revenue in the modeled period only when the relevant work is earned under the eventual accounting policy; cash deposits are tracked separately. Direct labor is Rp90,000/hour, including founder delivery effort. Other direct costs are Rp200k/320k/480k per brand/web/combined project and Rp70k per care account. Tax, financing, depreciation and owner distributions are excluded. The operator must review actual tax/accounting treatment [L3, L3b].

Overhead includes nondelivery management/admin, shared tools and acquisition, not the same direct delivery hours twice. Illustrative fixed monthly allocation is Rp8m in conservative/base: Rp5m nondelivery management, Rp1m shared tools/admin, Rp2m contingency/reserve. Optimistic fixed overhead is Rp9m. Cash acquisition budgets are Rp1.5m, Rp2m and Rp3m respectively. These are allowances to replace with quotes and actual staffing, not known salaries.

## Monthly steady-state cases

Amounts in **Rp million** except hours/accounts. Care counts are active paid accounts for that month, not new projects.

| Metric | Conservative | Base | Optimistic |
|---|---:|---:|---:|
| Brand projects | 1 | 0 | 1 |
| Website projects | 1 | 1 | 2 |
| Combined projects | 0 | 2 | 2 |
| Care accounts | 2 | 4 | 8 |
| Revenue | 14.10 | 34.30 | 49.70 |
| Direct cost including delivery labor | 5.70 | 13.80 | 20.00 |
| Gross contribution | 8.40 | 20.50 | 29.70 |
| Fixed overhead + cash acquisition | 9.50 | 10.00 | 12.00 |
| Operating result before tax | **-1.10** | **10.50** | **17.70** |
| Delivery hours consumed | 56 | 136 | 196 |
| Assumed available delivery capacity | 160 | 160 | 224 |

The optimistic case requires additional supported capacity. It is not a promise that a solo founder can sell, administer, design and develop all those hours. Unused conservative capacity does not make the fixed cost disappear.

## Break-even and sensitivity

Base gross-contribution ratio is 20.5 / 34.3, approximately 59.77%. At that assumed mix and Rp10m overhead, monthly earned revenue break-even is approximately **Rp16.73m**. This is not a universal break-even because service mix and utilization change it.

- Base direct costs rising 20% reduce operating result to **Rp7.74m**. If the increase is entirely delivery hours, 163.2 hours exceed the 160-hour capacity; contracting or rescheduling is required.
- Base revenue falling 20% while costs remain unchanged reduces operating result to **Rp3.64m**.
- One Rp11.9m combined project deferred with its Rp4.8m cost also deferred reduces the base result to **Rp3.4m**. If all its cost is already incurred but revenue is delayed, that period's result becomes **-Rp1.4m**. Cash timing may differ again.

Do not use these sensitivities as probability-weighted outcomes; no probability distribution has been estimated.

## Illustrative 90-day ramp

A separate ramp avoids pretending the steady-state base exists from day one. This example assumes launch gates are cleared and work is earned within each period; it is a scenario, not a sales commitment.

| Period | Earned work | Revenue | Direct cost | Overhead/acquisition | Operating result |
|---|---|---:|---:|---:|---:|
| Month 1 | One brand project | 4.90 | 2.00 | 9.00 | -6.10 |
| Month 2 | One website + one combined | 19.80 | 8.00 | 9.50 | 2.30 |
| Month 3 | Base monthly mix above | 34.30 | 13.80 | 10.00 | 10.50 |
| Total | Before one-time setup | **59.00** | **23.80** | **28.50** | **6.70** |

An illustrative Rp4.5m one-time setup allowance leaves **Rp2.2m** before tax over this ramp. The four care accounts in month three require actual completed/eligible clients and acceptance; remove that revenue and cost if those accounts do not exist. No startup capital has been committed.

## Cash controls

Maintain a rolling 13-week cash register separate from this profit model: opening bank balance + collected milestones - paid delivery costs - overhead - taxes/remittances - approved owner withdrawals = closing balance. Record unearned deposits and remaining obligations. Track invoice gross, cash net of any lawful withholding and supporting documents separately.

A proposed initial reserve discussion point is Rp20m, not a proven minimum. Derive the actual reserve from signed schedules, staffing commitments, owner living needs and payment delays. Never buy staff capacity on the assumption that unsigned proposals are cash.

## Validation data to collect

Actual paid acceptance, time by phase, rework, subcontractor rates, collection delays, refunds, tax treatment, software/hosting costs, fully loaded acquisition costs and care usage. Reforecast monthly. No competitor or Flourish revenue, margin, CAC or customer lifetime value is invented to make the projection look authoritative.
