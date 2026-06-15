## Why

目前 5 個台文方案 .deb 依賴系統的 `librime1`，但意傳的客製 librime（`i3thuan5/librime`）與上游已有 4–5 年的差異，系統版本無法支援台文方案所需的特定行為。需要打包客製版 librime 並讓方案 .deb 改為依賴它，同時與系統 `librime1` 共存不衝突。

## What Changes

- **新增** `librime-ithuan/` git submodule（指向 `git@github.com:i3thuan5/librime.git`）
- **新增** `packaging/Dockerfile-librime-24.04`：將客製 librime 打包為 `librime-ithuan_VERSION_ubuntu24.04.deb`
- **修改** `packaging/Dockerfile-24.04`：scheme build 改從客製 librime Docker image 取得 headers/.so，verifier 也改用客製版
- **修改** `packaging/build-all.sh`：Step 0 先 build librime image，再 build 5 個方案
- **修改** `CMakeLists.txt`：`pkg_check_modules` 改找 `rime-ithuan` 而非 `rime`
- **修改** `.gitmodules`：加入 librime-ithuan submodule
- **修改** `i3thuan5/librime` fork（上游 repo）3 個地方，使 library 輸出名稱為 `librime-ithuan`、pkg-config 為 `rime-ithuan.pc`

## Capabilities

### New Capabilities

- `librime-ithuan-packaging`：為 Ubuntu 24.04 打包客製 librime，輸出 `librime-ithuan.so.1`（與系統 `librime.so.1` 完全獨立），並提供 `.deb` 供使用者安裝

### Modified Capabilities

（無 spec-level 行為變更，原有台文方案 packaging 功能不變，僅改變 librime 來源）

## Impact

- **依賴鏈變更**：`fcitx5-hanlo` 等方案的 `Depends` 從 `librime1 (>=1.7.0)` 改為 `librime-ithuan`
- **新增套件**：使用者需額外安裝 `librime-ithuan.deb`（共 6 個 .deb，原為 5 個）
- **上游 repo 改動**：需修改 `i3thuan5/librime`（不在本 repo 內，需另行 PR 或直接 push）
- **Docker build 時間**：首次 build 增加 librime 編譯時間；後續因 Docker cache 不重建
- **不影響**：fcitx5-rime 核心 C++ 邏輯、scheme 資料檔案、.travis.yml 結構
