#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
i18n_summary.py
-------------------------------------------------
Scan letters JSON (2.x) and summarize:
- i18n missing counts for keys: title, description, definition, subtitle, note, notes
- freq distribution across items: high/mid/low

Usage (Windows PowerShell/CMD):
  py tools\i18n_summary.py --root . --out .\i18n_summary_output

Outputs:
  <out>\summary.csv
"""

import os, json, csv, argparse

LANGS = ["ko","en","zh","ja","vi","fr","es","ru","mn"]
I18N_KEYS = ["title","description","definition","subtitle","note","notes"]

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def iter_items(data):
    """Yield item-like nodes that may carry `freq` etc."""
    # flat chars
    if isinstance(data.get("chars"), list):
        for ch in data["chars"]:
            yield ch
    # nested sections: cv / cvc
    sections = data.get("sections", {})
    if isinstance(sections, dict):
        cv = sections.get("cv", {})
        if isinstance(cv, dict):
            if isinstance(cv.get("chars"), list):
                for ch in cv["chars"]:
                    yield ch
            if isinstance(cv.get("examples"), list):
                for ex in cv["examples"]:
                    for it in ex.get("items", []):
                        yield it
        cvc = sections.get("cvc", {})
        if isinstance(cvc, dict):
            if isinstance(cvc.get("examples"), list):
                for ex in cvc["examples"]:
                    for it in ex.get("items", []):
                        yield it
            if isinstance(cvc.get("groups"), list):
                for grp in cvc["groups"]:
                    for it in grp.get("items", []):
                        yield it
                    for it in grp.get("doubleFinals", []):
                        yield it

def count_i18n_missing(node, key):
    """Count per-language missing entries for a given i18n key."""
    missing = {lang: 0 for lang in LANGS}

    def check_obj(obj):
        for lang in LANGS:
            if (lang not in obj) or (not obj.get(lang)):
                missing[lang] += 1

    def walk(n):
        if isinstance(n, dict):
            if key in n:
                val = n[key]
                if isinstance(val, dict):
                    check_obj(val)
            for v in n.values():
                walk(v)
        elif isinstance(n, list):
            for v in n:
                walk(v)

    walk(node)
    return missing

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="Project root")
    ap.add_argument("--out", default="./i18n_summary_output", help="Output folder")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    out_csv = os.path.join(out, "summary.csv")

    # collect candidate files (letters 2.x + any *_index)
    letters_dir = os.path.join(root, "assets", "data", "letters")
    files = []
    if os.path.isdir(letters_dir):
        for fn in os.listdir(letters_dir):
            if fn.endswith(".json") and (
                fn.startswith(("2_1_","2_2_","2_3_","2_4_")) or "index" in fn
            ):
                files.append(os.path.join(letters_dir, fn))
    else:
        print(f"[WARN] letters folder not found: {letters_dir}")

    # CSV header
    header = ["file_id","file_name"]
    header += [f"miss_{k}_{lang}" for k in I18N_KEYS for lang in LANGS]
    header += ["freq_high","freq_mid","freq_low","freq_total_items"]

    rows = [header]

    for path in sorted(files):
        data = load_json(path)
        file_id = data.get("id", os.path.basename(path))
        file_name = os.path.basename(path)

        # i18n missing counts
        per_key = {key: count_i18n_missing(data, key) for key in I18N_KEYS}

        # freq distribution
        high = mid = low = 0
        total_items = 0
        for it in iter_items(data):
            f = it.get("freq")
            if f == "high":
                high += 1
            elif f == "low":
                low += 1
            else:
                mid += 1
            total_items += 1

        row = [file_id, file_name]
        for key in I18N_KEYS:
            for lang in LANGS:
                row.append(per_key[key][lang])
        row += [high, mid, low, total_items]
        rows.append(row)

    with open(out_csv, "w", encoding="utf-8-sig", newline="") as f:
        csv.writer(f).writerows(rows)

    print(f"Summary CSV saved to: {out_csv}")
    print(f"Files scanned: {len(files)}")

if __name__ == "__main__":
    main()
