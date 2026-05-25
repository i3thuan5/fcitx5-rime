## Context

目前打包流程：
- `Dockerfile-25.10`：單一 stage，負責 build + install + dpkg-deb，最後 `CMD cat /output/*.deb`
- `build-all.sh`：呼叫 Docker build，再用 `docker create` + `docker cp` 取出 .deb
- `test-build.sh`：8 個 task（8.1~8.4），每個 task 內嵌 heredoc Dockerfile，各跑多次 `docker run` 做驗證，有邏輯 bug（pipe 導致 subshell 使計數無效）

升版至 Ubuntu 26.04 的同時，一併重構為 multi-stage Dockerfile，讓驗證邏輯進入 Dockerfile 本身。驗證已內建後，`test-build.sh` 變成多餘，直接刪除，CI 改用 Travis CI 跑 `build-all.sh`。

## Goals / Non-Goals

**Goals:**
- 所有打包相關的 `ubuntu:25.10` 改為 `ubuntu:26.04`
- Dockerfile 改為 5-stage，self-contained（build + pack + verify + export）
- 刪除 `test-build.sh`（驗證已內建於 Dockerfile）
- `build-all.sh` 更新 .deb 提取方式
- 新增 `.travis.yml`，CI 直接跑 `build-all.sh`

**Non-Goals:**
- 不更動 CI workflow（`check.yml` 使用 `ubuntu-latest`，與 Dockerfile 無關）
- 不更動 CMakeLists.txt 或 C++ 原始碼
- 不支援多版本 Ubuntu 並行（只保留 26.04）

## Decisions

### 決定 1：5-stage Dockerfile

```
Stage 1: deps      (FROM ubuntu:26.04)
Stage 2: builder   (FROM deps)          — cmake + make + install → /staging
Stage 3: packager  (FROM builder)       — dpkg-deb → /output/*.deb
Stage 4: verifier  (FROM ubuntu:26.04)  — 安裝 .deb，RUN test -f 驗證
Stage 5: exporter  (FROM verifier)      — COPY /output/*.deb，CMD cat
```

**為何 verifier 用全新 `FROM ubuntu:26.04` 而非 FROM packager？**
驗證目的是確認 .deb 能在乾淨環境裝起來，不應繼承 build 環境的套件。

**為何 exporter 繼承 verifier 而非 packager？**
確保 `docker build`（預設跑到最後 stage）必定執行 verifier。若 exporter 繼承 packager，verifier 只有明確 `--target=verifier` 才會跑。

**Stage 4 驗證內容（`RUN` assertions）：**
- `dpkg -i /tmp/*.deb` 安裝成功
- `test -f /usr/lib/*/fcitx5/lib${SCHEME_ID}.so`
- `test -f /usr/share/fcitx5/addon/${SCHEME_ID}.conf`
- `test -f /usr/share/fcitx5/inputmethod/${SCHEME_ID}.conf`
- `ls /usr/share/${SCHEME_ID}/data/*.yaml`
- `ls /usr/share/icons/hicolor/48x48/apps/fcitx-${SCHEME_ID}.png`
- `ls /usr/share/icons/hicolor/scalable/apps/fcitx-${SCHEME_ID}.svg`（若 SCHEME_ICON_TOO 有設定）

### 決定 2：刪除 test-build.sh，Travis CI 跑 build-all.sh

`build-all.sh` 對每個方案都呼叫 `docker build`（跑到 exporter stage），exporter 繼承 verifier，所以每次 build 都必定執行 stage 4 的安裝驗證。`build-all.sh` 通過 = 全部方案 build + pack + verify 完成，`test-build.sh` 沒有額外價值，刪除。

Travis CI 以 PangBoo/.travis.yml 為基底新增 `.travis.yml`，加入 `services: docker`，執行 `./packaging/build-all.sh`。

### 決定 3：build-all.sh 用 docker run 取 .deb

舊方式：`docker create` + `docker cp` + `docker rm`（3 個指令）

新方式：
```bash
docker run --rm TAG > "$OUTPUT_DIR/fcitx5-${ID}_${APP_VERSION}_ubuntu26.04.deb"
```
更簡潔，不留殘餘 container。

## Risks / Trade-offs

- **verifier stage 需要 apt-get install fcitx5 librime1**（runtime deps）→ build 時需要網路。Travis CI 有網路，不受影響；本地無網路環境需注意。

- **Stage 4 glob 路徑** `test -f /usr/lib/*/fcitx5/lib${SCHEME_ID}.so`：`test -f` 不支援 glob，需改用 `ls` 或 `find`。→ 實作時用 `ls /usr/lib/*/fcitx5/lib${SCHEME_ID}.so`。

## Migration Plan

1. 刪除 `packaging/Dockerfile-25.10`
2. 新增 `packaging/Dockerfile-26.04`（5 stages）
3. 更新 `packaging/build-all.sh`
4. 刪除 `packaging/test-build.sh`
5. 新增 `.travis.yml`
6. 更新 `README.md`

無需 rollback 策略（git revert 即可）。

## Open Questions

（無）
