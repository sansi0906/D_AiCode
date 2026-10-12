# -*- coding: utf-8 -*-
"""为 assets/audio 下所有 mp3 生成变速不变调(atemo=0.8)的 _slow 版本"""
import os, subprocess, sys

ROOT = r"E:\DAI\kuaile_yingyu\assets\audio"
FF = r"E:\DAI\POC\tools\ffmpeg\ffmpeg-9.0.1-essentials_build\bin\ffmpeg.exe"
LOG = r"E:\DAI\slow_audio_log.txt"

def main():
    count, skip, fail = 0, 0, 0
    log = open(LOG, "a", encoding="utf-8")
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if "_backup" not in d]
        for f in sorted(filenames):
            if not f.lower().endswith(".mp3"):
                continue
            if f.lower().endswith("_slow.mp3"):
                continue
            src = os.path.join(dirpath, f)
            dst = os.path.join(dirpath, f[:-4] + "_slow.mp3")
            if os.path.exists(dst):
                skip += 1
                continue
            r = subprocess.run(
                [FF, "-y", "-i", src, "-filter:a", "atempo=0.8",
                 "-codec:a", "libmp3lame", "-b:a", "128k", dst],
                capture_output=True, text=True)
            if r.returncode != 0:
                fail += 1
                log.write(f"FAIL {src}: {r.stderr[-300:]}\n")
                log.flush()
            else:
                count += 1
            if count % 200 == 0 and count > 0:
                log.write(f"progress {count}\n")
                log.flush()
    log.write(f"DONE ok={count} skip={skip} fail={fail}\n")
    log.flush()
    log.close()
    print(f"ok={count} skip={skip} fail={fail}")

if __name__ == "__main__":
    main()
