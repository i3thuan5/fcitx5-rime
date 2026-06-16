## Context

目前 `packaging/Dockerfile-24.04` 在 `deps` stage 執行 `apt install librime-dev`，取得系統的 `librime.so.1`（Ubuntu 24.04 套件庫版本）。意傳客製 librime（`i3thuan5/librime`）與上游差異達 4–5 年，版本為 `1.5.3`，已放置快照於 `other/librime/`。本 change 的目標是將此客製版打包為 `librime-ithuan.deb` 並讓方案 .deb 依賴它。

## Goals / Non-Goals

**Goals:**
- 客製 librime 輸出 `librime-ithuan.so.1`，與系統 `librime.so.1` 名稱不同，零衝突共存
- `Dockerfile-librime-24.04` 獨立打包 librime，`Dockerfile-24.04` 透過 Docker image 取用
- `build-all.sh` 自動先 build librime 再 build 5 個方案，共輸出 6 個 .deb
- `CMakeLists.txt` 改找 `rime-ithuan` pkg-config

**Non-Goals:**
- 不修改 Ubuntu 24.04 以外的打包流程
- 不處理 librime-ithuan ARM64 cross-compile
- 不提供 PPA 或 apt repo（使用者手動 dpkg -i）
- 不更動 fcitx5-rime 的 C++ 業務邏輯

## Decisions

### 決策 1：library 名稱用 `librime-ithuan`，不用 RPATH

**決定**：修改 `i3thuan5/librime` 的 `src/CMakeLists.txt` 加入 `OUTPUT_NAME rime-ithuan`，使輸出為 `librime-ithuan.so.1`。

**理由**：不同 soname 是最乾淨的共存方式。相比 RPATH 方案：
- RPATH 需要在每個 scheme .so 嵌入路徑，若安裝路徑變動就壞掉
- OUTPUT_NAME 只需改一行，loader 自動用不同名稱區分

**替代方案**：RPATH + 安裝到 `/usr/lib/ithuan/`（已排除：路徑脆弱）

### 決策 2：兩個獨立 Dockerfile（librime + scheme）

**決定**：`Dockerfile-librime-24.04` 負責建 librime，`Dockerfile-24.04` 負責建方案。scheme Dockerfile 用 `COPY --from=librime-ithuan-ubuntu24.04` 取 headers/.so（方案 3）。

**理由**：
- 單一 Dockerfile 多 stage 會讓 librime .deb 輸出需要 `--target` 才能取出，流程較複雜
- 兩個 Dockerfile 分工清楚，librime 可獨立 rebuild
- `COPY --from=image-name`（方案 3）不需要把 .deb 複製進 build context，比方案 1（暫存 .deb）乾淨

**替代方案**：單一 Dockerfile 多 stage（已排除：librime .deb 取出流程複雜）

### 決策 3：librime 版本號從原始碼讀取

**決定**：在 `Dockerfile-librime-24.04` 的 packager stage 讀取 `rime_version`，寫入 `/librime-version.txt`，`build-all.sh` 從 container 取出後用於 .deb 版本欄位。

**理由**：librime 版本與方案版本獨立，由 librime fork 自行管理，不應由 `build-all.sh` 參數決定。

### 決策 4：需修改 i3thuan5/librime fork

以下 3 個修改需在上游 repo 進行（不在本 repo 範圍內，需另行 commit/PR）：

| 檔案 | 修改內容 |
|---|---|
| `src/CMakeLists.txt` | `set_target_properties(rime PROPERTIES OUTPUT_NAME rime-ithuan ...)` |
| `rime.pc.in` | `Name: rime-ithuan`、`Libs: -lrime-ithuan` |
| `CMakeLists.txt` | `configure_file(rime.pc.in rime-ithuan.pc)`、`install(... rime-ithuan.pc)` |

這些修改使 pkg-config 名稱為 `rime-ithuan`，對應本 repo `CMakeLists.txt` 的 `pkg_check_modules` 改動。

### 決策 5：librime-ithuan 以 git submodule 管理

**決定**：路徑 `librime-ithuan/`，URL `git@github.com:i3thuan5/librime.git`，加入 `.gitmodules`。

**理由**：與現有 5 個 scheme submodule 一致的管理方式。`other/librime/` 僅為探索期的快照，不作為 build source。

## Risks / Trade-offs

- [風險] `COPY --from=image-name` 要求 scheme `docker build` 執行前 image 已存在 → `build-all.sh` 的 Step 0 必須先完成 librime build，不可並行
- [風險] `i3thuan5/librime` 的修改是外部 repo，本 repo 無法強制保持同步 → 用固定 submodule commit 鎖版本
- [取捨] 使用者需安裝 6 個 .deb（原為 5 個）→ 可接受（使用者確認 3 個以下都可以）
- [取捨] Docker cache 讓 librime 後續不重編，但首次 build 時間增加（librime 需編譯） → 可接受

## Open Questions（已解決）

- ~~版本號後綴格式~~ → 確認用 `~ubuntu24.04`（與方案 .deb 一致）
- ~~headers 驗證~~ → 確認在 verifier stage 加入：`echo '#include <rime_api.h>\nint main(){return 0;}' | gcc -x c - $(pkg-config --cflags rime-ithuan) -o /dev/null`，同時驗證 header 存在與 pkg-config cflags 正確

### 決策 6：套件名稱遵循 Debian 共享函式庫慣例

**決定**：套件名稱用 `librime-ithuan1`（加 soversion `1`），library 檔案仍為 `librime-ithuan.so.1`。

| 項目 | 值 |
|---|---|
| library 檔案 | `librime-ithuan.so.1` |
| **套件名稱** | **`librime-ithuan1`** |
| .deb 檔名 | `librime-ithuan1_1.5.3~ubuntu24.04_amd64.deb` |
| 方案 Depends | `librime-ithuan1` |

**理由**：遵循 Debian 慣例（`librime.so.1` → `librime1`），未來若 ABI 有破壞性變更可出 `librime-ithuan2` 共存。
