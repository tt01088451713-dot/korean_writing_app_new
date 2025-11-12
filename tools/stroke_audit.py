#!/usr/bin/env python3
import os, json, csv
from glob import glob

def ensure_writing_block(obj):
    stroke_path = obj.get("strokeOrder")
    writing = obj.get("writing", {})
    if stroke_path and "order" not in writing:
        writing["order"] = stroke_path
    if "strokes" not in writing:
        writing.setdefault("strokes", [])
    if "guideOnly" not in writing:
        writing["guideOnly"] = obj.get("guideOnly", False)
    obj["writing"] = writing
    if "guideOnly" not in obj:
        obj["guideOnly"] = writing.get("guideOnly", False)
    if "strokeOrder" not in obj and "order" in writing:
        obj["strokeOrder"] = writing["order"]

def audit_item(file_id, fname, item, results, base_dir):
    glyph = item.get("glyph") or item.get("label") or item.get("syllable") or ""
    path = item.get("strokeOrder")
    ensure_writing_block(item)
    path = item.get("strokeOrder")
    exists = False
    if path and isinstance(path, str):
        exists = os.path.exists(os.path.join(base_dir, path)) or os.path.exists(path)
    action = ""
    if not exists:
        prev = item.get("guideOnly", False)
        item["guideOnly"] = True
        item["writing"]["guideOnly"] = True
        action = f"guideOnly set True (was {prev})"
    results.append((file_id, fname, glyph, path or "", "YES" if exists else "NO", action))

def visit_json(fname, data, results, base_dir):
    file_id = data.get("id", os.path.basename(fname))
    # A) top-level chars
    if isinstance(data.get("chars"), list):
        for ch in data["chars"]:
            audit_item(file_id, fname, ch, results, base_dir)
    # B) sections.*
    sections = data.get("sections", {})
    if isinstance(sections, dict):
        cv = sections.get("cv", {})
        if isinstance(cv, dict):
            if isinstance(cv.get("chars"), list):
                for ch in cv["chars"]:
                    audit_item(file_id, fname, ch, results, base_dir)
            if isinstance(cv.get("examples"), list):
                for ex in cv["examples"]:
                    for it in ex.get("items", []):
                        audit_item(file_id, fname, it, results, base_dir)
        cvc = sections.get("cvc", {})
        if isinstance(cvc, dict):
            if isinstance(cvc.get("examples"), list):
                for ex in cvc["examples"]:
                    for it in ex.get("items", []):
                        audit_item(file_id, fname, it, results, base_dir)
            if isinstance(cvc.get("groups"), list):
                for grp in cvc["groups"]:
                    for it in grp.get("items", []):
                        audit_item(file_id, fname, it, results, base_dir)
                    for it in grp.get("doubleFinals", []):
                        audit_item(file_id, fname, it, results, base_dir)

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="Project root (where assets/ lives)")
    ap.add_argument("--out", default="./stroke_audit_output", help="Output directory for patched JSON & report")
    args = ap.parse_args()

    base_dir = os.path.abspath(args.root)
    out_dir = os.path.join(args.out, "json")
    os.makedirs(out_dir, exist_ok=True)
    report_csv = os.path.join(args.out, "report.csv")
    os.makedirs(os.path.dirname(report_csv), exist_ok=True)

    # Discover target JSON files (letters only, exclude Jamo 1.x)
    all_json = sorted(glob(os.path.join(base_dir, "assets", "data", "letters", "*.json")) + 
                      glob(os.path.join(base_dir, "*.json")))
    letters_json = [p for p in all_json if os.path.basename(p).startswith(("2_1_", "2_2_", "2_3_", "2_4_"))]

    rows = []
    for path in letters_json:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        visit_json(path, data, rows, base_dir)
        # save patched beside
        out_path = os.path.join(out_dir, os.path.basename(path))
        with open(out_path, "w", encoding="utf-8") as wf:
            json.dump(data, wf, ensure_ascii=False, indent=2)

    with open(report_csv, "w", encoding="utf-8", newline="") as cf:
        writer = csv.writer(cf)
        writer.writerow(["file_id", "source_file", "glyph", "strokeOrder_path", "asset_exists", "action"])
        writer.writerows(rows)

    print(f"Patched JSON saved to: {out_dir}")
    print(f"Report CSV saved to: {report_csv}")

if __name__ == "__main__":
    main()
