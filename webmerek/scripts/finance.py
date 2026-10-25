#!/usr/bin/env python3
"""Transparent planning arithmetic, not revenue forecasts or tax calculations."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
config = json.loads((ROOT / 'site.json').read_text())
products = {p['id']: p for p in config['packages']}
products['care'] = config['care']
scenarios = {
    'Conservative': ({'fondasi': 1, 'website': 1, 'lengkap': 0, 'care': 2}, 9500000, 160),
    'Base': ({'fondasi': 0, 'website': 1, 'lengkap': 2, 'care': 4}, 10000000, 160),
    'Optimistic': ({'fondasi': 1, 'website': 2, 'lengkap': 2, 'care': 8}, 12000000, 224),
}
expected = {'Conservative': (14100000, 5700000, -1100000, 56), 'Base': (34300000, 13800000, 10500000, 136), 'Optimistic': (49700000, 20000000, 17700000, 196)}
result = {}
for name, (counts, overhead, capacity) in scenarios.items():
    revenue = sum(products[k]['price'] * n for k, n in counts.items())
    direct = sum((products[k]['hours'] * config['laborRate'] + products[k]['otherCost']) * n for k, n in counts.items())
    hours = sum(products[k]['hours'] * n for k, n in counts.items())
    operating = revenue - direct - overhead
    assert (revenue, direct, operating, hours) == expected[name]
    assert hours <= capacity
    result[name] = {'revenue': revenue, 'directCost': direct, 'overheadIncludingAcquisition': overhead, 'operatingBeforeTax': operating, 'deliveryHours': hours, 'capacity': capacity}
print(json.dumps({'assumptionsOnly': True, 'scenarios': result}, indent=2))
