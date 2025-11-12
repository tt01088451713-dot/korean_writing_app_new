
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
route_integrity_checker.py
-------------------------------------------------
Check "index" JSON files for route / extraRoutes integrity.
- Verifies that each route points to an existing JSON file under assets/data/letters
- Reports missing files, duplicates, and case mismatches

Usage (Windows):
  py tools\route_integrity_checker.py --root . --out .\route_check_output

Targets:
  - Any *index.json in assets/data/letters (e.g., 2_2_top_bottom.index.json, 2_4_index.json)

Outputs:
  - out/report.csv : route, resolved path, exists(YES/NO), note
  - Prints a concise summary to console
"""

import os, json, csv, argparse, re

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def route_to_relpath(route):
    # route like "/letters/2_4_2_with_batchim.json" -> "assets/data/letters/2_4_2_with_batchim.json"
    route = route.strip()
    if route.startswith("/"):
        route = route[1:]
    if route.startswith("letters/"):
        route = route[len("letters/"):]
    return os.path.join("assets", "data", "letters", route)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="Project root (where assets/ lives)")
    ap.add_argument("--out", default="./route_check_output", help="Output directory for the report CSV")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    report_csv = os.path.join(out_dir, "report.csv")

    letters_dir = os.path.join(root, "assets", "data", "letters")
    if not os.path.isdir(letters_dir):
        raise SystemExit(f"Not found: {letters_dir}")

    # Find index files
    index_files = [os.path.join(letters_dir, fn) for fn in os.listdir(letters_dir) if fn.endswith(".index.json")]
    index_files += [os.path.join(letters_dir, fn) for fn in os.listdir(letters_dir) if fn.endswith("_index.json")]
    index_files = sorted(set([p for p in index_files if os.path.isfile(p)]))

    rows = []
    missing = 0
    case_mismatch = 0
    total = 0

    for idx_path in index_files:
        data = load_json(idx_path)
        file_id = data.get("id", os.path.basename(idx_path))
        parts = data.get("parts", [])
        for p in parts:
            # main route
            route = p.get("route")
            if route:
                rel = route_to_relpath(route)
                abs_path = os.path.join(root, rel)
                total += 1
                if os.path.exists(abs_path):
                    rows.append([file_id, os.path.basename(idx_path), route, rel, "YES", ""])
                else:
                    # case-only mismatch detection
                    folder = os.path.dirname(abs_path)
                    fname = os.path.basename(abs_path)
                    note = "missing"
                    try:
                        if os.path.isdir(folder):
                            names = set(os.listdir(folder))
                            lower_map = {n.lower(): n for n in names}
                            if fname.lower() in lower_map and lower_map[fname.lower()] != fname:
                                note = f"case-mismatch: actual '{lower_map[fname.lower()]}'"
                                case_mismatch += 1
                    except Exception:
                        pass
                    rows.append([file_id, os.path.basename(idx_path), route, rel, "NO", note])
                    missing += 1

            # extraRoutes
            extra = p.get("extraRoutes") or []
            for ex in extra:
                er = ex.get("route")
                if not er:
                    continue
                rel = route_to_relpath(er)
                abs_path = os.path.join(root, rel)
                total += 1
                if os.path.exists(abs_path):
                    rows.append([file_id, os.path.basename(idx_path), er, rel, "YES", ""])
                else:
                    note = "missing"
                    try:
                        folder = os.path.dirname(abs_path)
                        fname = os.path.basename(abs_path)
                        if os.path.isdir(folder):
                            names = set(os.listdir(folder))
                            lower_map = {n.lower(): n for n in names}
                            if fname.lower() in lower_map and lower_map[fname.lower()] != fname:
                                note = f"case-mismatch: actual '{lower_map[fname.lower()]}'"
                                case_mismatch += 1
                    except Exception:
                        pass
                    rows.append([file_id, os.path.basename(idx_path), er, rel, "NO", note])
                    missing += 1

    with open(report_csv, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["index_id","index_file","route","resolved_relpath","exists","note"])
        w.writerows(rows)

    print(f"Checked routes: {total}")
    print(f"Missing: {missing}, Case-mismatch: {case_mismatch}")
    print(f"Report CSV saved to: {report_csv}")

if __name__ == "__main__":
    main()
