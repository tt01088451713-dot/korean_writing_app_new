import os
import json
import argparse
import csv

# 시드 목록 (기본값)
HIGH_SEEDS = {"관","광","국","글","근","원","월","웰","윈","윌","윙","흰"}
MID_SEEDS = {"괄","괌","곽","곤","골","곰","공","군","굴","굼","궁","급"}
LOW_SEEDS = {"괵","웝"}

def detect_freq(glyph, core=False, guideOnly=False, samples=None,
                high_seeds=HIGH_SEEDS, mid_seeds=MID_SEEDS, low_seeds=LOW_SEEDS):
    if glyph in high_seeds:
        return "high"
    if glyph in mid_seeds:
        return "mid"
    if glyph in low_seeds:
        return "low"
    if core or (samples and len(samples) > 0):
        return "high"
    if guideOnly:
        return "low"
    return "mid"

def patch_file(path, outdir, force=False, high_seeds=HIGH_SEEDS,
               mid_seeds=MID_SEEDS, low_seeds=LOW_SEEDS):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    modified = False
    summary = []
    def process_node(node):
        nonlocal modified
        if not isinstance(node, dict):
            return
        if "glyph" in node:
            glyph = node.get("glyph")
            prev_freq = node.get("freq")
            if prev_freq is None or force:
                new_freq = detect_freq(
                    glyph,
                    core=node.get("core", False),
                    guideOnly=node.get("guideOnly", False),
                    samples=node.get("samples"),
                    high_seeds=high_seeds,
                    mid_seeds=mid_seeds,
                    low_seeds=low_seeds
                )
                node["freq"] = new_freq
                modified = True
                summary.append((os.path.basename(path), glyph, prev_freq, new_freq))
        for k, v in node.items():
            if isinstance(v, dict):
                process_node(v)
            elif isinstance(v, list):
                for x in v:
                    process_node(x)
    process_node(data)
    if modified:
        os.makedirs(outdir, exist_ok=True)
        with open(os.path.join(outdir, os.path.basename(path)), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    return summary

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, help="Root directory to scan")
    parser.add_argument("--out", required=True, help="Output directory for patched JSON")
    parser.add_argument("--force", action="store_true", help="Force overwrite existing freq")
    parser.add_argument("--high", type=str, help="Comma-separated list of extra high seeds")
    parser.add_argument("--mid", type=str, help="Comma-separated list of extra mid seeds")
    parser.add_argument("--low", type=str, help="Comma-separated list of extra low seeds")
    args = parser.parse_args()

    high_seeds = set(HIGH_SEEDS)
    mid_seeds = set(MID_SEEDS)
    low_seeds = set(LOW_SEEDS)
    if args.high:
        high_seeds.update([x.strip() for x in args.high.split(",") if x.strip()])
    if args.mid:
        mid_seeds.update([x.strip() for x in args.mid.split(",") if x.strip()])
    if args.low:
        low_seeds.update([x.strip() for x in args.low.split(",") if x.strip()])

    summary_rows = []
    for root, dirs, files in os.walk(args.root):
        for fn in files:
            if fn.endswith(".json") and (fn.startswith("2_1_") or fn.startswith("2_2_") or fn.startswith("2_3_") or fn.startswith("2_4_")):
                path = os.path.join(root, fn)
                rows = patch_file(path, args.out, force=args.force,
                                  high_seeds=high_seeds, mid_seeds=mid_seeds, low_seeds=low_seeds)
                summary_rows.extend(rows)

    if summary_rows:
        with open(os.path.join(args.out, "summary.csv"), "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["source_file","glyph","prev_freq","new_freq"])
            writer.writerows(summary_rows)

if __name__ == "__main__":
    main()
