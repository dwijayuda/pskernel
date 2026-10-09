import glob, json, sys
group = sys.argv[1]
rows = [json.load(open(p, encoding="utf-8")) for p in glob.glob("_results/pskernel-435_*.json")]
rows = [r for r in rows if r.get("test", "").startswith(group + "/")] if group in ("tutorial", "bugs") else [r for r in rows if r.get("test") == group]
expected = {"tutorial": 141, "bugs": 18}.get(group, 1)
assert len(rows) == expected and len({r["test"] for r in rows}) == expected, (group, "coverage", len(rows), expected)
bad = []
for r in rows:
    print("ARENA_RESULT", r.get("test"), r.get("status"), r.get("correctness"), r.get("exit_code"), r.get("wall_time"), r.get("max_rss"))
    # This known decline is recorded explicitly; it is never counted as a rejection.
    known = group == "bugs" and r.get("test") == "bugs/rec-missing-ih" and r.get("correctness") == "declined"
    if r.get("correctness") != "correct":
        print((r.get("stderr") or "")[-12000:])
        if not known:
            bad.append(r)
assert not bad, [(r.get("test"), r.get("status"), r.get("correctness")) for r in bad]
print("ARENA_COVERAGE_PASS", group, len(rows), "correct", sum(r.get("correctness") == "correct" for r in rows), "declined", sum(r.get("correctness") == "declined" for r in rows))
