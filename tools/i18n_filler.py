import os
import json

# 다국어 필드 자동 보강 툴
# freq_patch_output 내부의 모든 JSON을 점검하고, i18n이 비어있으면 ko 값을 복사

PATCH_DIR = "./freq_patch_output"

def fill_i18n(data):
    changed = False
    if isinstance(data, dict):
        for k, v in data.items():
            if k == "i18n" and isinstance(v, dict):
                ko_val = v.get("ko", "")
                for lang in ["en", "zh", "ja", "vi", "fr", "es", "ru", "mn"]:
                    if not v.get(lang):  # 값이 없거나 빈 문자열이면 ko 값 복사
                        v[lang] = ko_val
                        changed = True
            else:
                if isinstance(v, (dict, list)):
                    if fill_i18n(v):
                        changed = True
    elif isinstance(data, list):
        for item in data:
            if fill_i18n(item):
                changed = True
    return changed

def process_file(path):
    with open(path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except Exception as e:
            print(f"[ERROR] JSON 로드 실패: {path}, {e}")
            return
    if fill_i18n(data):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"[UPDATED] {path}")
    else:
        print(f"[OK] {path}")

def main():
    if not os.path.exists(PATCH_DIR):
        print(f"경로 없음: {PATCH_DIR}")
        return
    for fn in os.listdir(PATCH_DIR):
        if fn.endswith(".json"):
            process_file(os.path.join(PATCH_DIR, fn))

if __name__ == "__main__":
    main()
