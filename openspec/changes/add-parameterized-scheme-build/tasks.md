## 1. Git Submodules 設定

- [ ] 1.1 新增 `schemes/` 目錄，加入 5 個輸入法方案 submodule（Rime-HanLo、Rime-POJ、Rime-POJHan、Rime-TOJ、Rime-TsuanLo），URL 指向 `git@github.com:i3thuan5/Rime-*.git`
- [ ] 1.2 執行 `git submodule update --init` 驗證全部 5 個 submodule 正確 checkout
- [ ] 1.3 從 Rime-Logo repo 複製各方案主圖示到 `data/icons/`（fcitx-hanlo.png/svg、fcitx-poj.png/svg 等），納入版本控制

## 2. 編譯期身份巨集（scheme_config.h.in）

- [ ] 2.1 建立 `src/scheme_config.h.in`，包含 `SCHEME_ADDON_NAME`、`SCHEME_ICON_PREFIX`、`SCHEME_CONF_PREFIX`、`SCHEME_DISPLAY_NAME` 的 `@` 變數定義
- [ ] 2.2 在 `rimeengine.cpp` 頂部（`#include` 區塊之後）加入 `#ifdef HAVE_SCHEME_CONFIG` / `#include "scheme_config.h"` / `#endif` 及 4 個 `#ifndef` 預設值區塊
- [ ] 2.3 在 `rimeengine.h` 頂部加入相同的 `#ifdef` / `#ifndef` 預設值區塊（供行 105、135 使用）

## 3. rimeengine.cpp / rimeengine.h 字串替換

- [ ] 3.1 替換 `rimeengine.cpp` 中約 24 處硬編碼字串為對應巨集（依 design 決策 2 的替換清單逐一執行）
- [ ] 3.2 替換 `rimeengine.h` 中 2 處硬編碼字串：行 105 的 `"rime"` → `SCHEME_ADDON_NAME`，行 135 的 `"conf/rime.conf"` → `"conf/" SCHEME_ADDON_NAME ".conf"`
- [ ] 3.3 替換 `rimefactory.cpp` 行 14 的 `"fcitx5-rime"` → `"fcitx5-" SCHEME_ADDON_NAME`

## 4. 方案專屬樣板檔

- [ ] 4.1 建立 `src/scheme_factory.cpp.in`，包含 `FCITX_ADDON_FACTORY_V2(@SCHEME_ID@, ...)` 的樣板內容
- [ ] 4.2 建立 `src/scheme.conf.in`，包含 InputMethod 設定樣板（Name、Icon、Label、LangCode、Addon）
- [ ] 4.3 建立 `src/scheme-addon.conf.in.in`，包含 Addon 設定樣板（Name、Library、Type、Dependencies）

## 5. CMake 參數化建置（schemes.cmake）

- [ ] 5.1 建立 `schemes.cmake`，包含：驗證 SCHEME_ID/SCHEME_NAME 必要參數、設定 RIME_DATA_DIR 為 `/usr/share/${SCHEME_ID}/data`
- [ ] 5.2 在 `schemes.cmake` 中加入 `configure_file()` 產生 `scheme_config.h`、`scheme_factory.cpp`
- [ ] 5.3 在 `schemes.cmake` 中加入 `add_fcitx5_addon()` 建置方案專屬 .so（使用 scheme_factory.cpp 取代 rimefactory.cpp，加上 `-DHAVE_SCHEME_CONFIG` 編譯定義）
- [ ] 5.4 在 `schemes.cmake` 中加入 `configure_file()` 產生方案專屬的 `.conf` 設定檔，並加入對應的 install 規則
- [ ] 5.5 在 `schemes.cmake` 中加入方案資料檔安裝邏輯（glob sujiphoat/*.yaml，排除 squirrel，安裝到 RIME_DATA_DIR）
- [ ] 5.6 在 `schemes.cmake` 中加入圖示安裝邏輯（主圖示從 data/icons/ 讀取，狀態圖示從 data/ 複製並改名）
- [ ] 5.7 在主 `CMakeLists.txt` 的 `feature_summary` 之前加入 `if(SCHEME_ID)` / `include(schemes.cmake)` / `endif()`

## 6. 打包：Ubuntu .deb

- [ ] 6.1 建立 `packaging/schemes.conf`，定義 5 個方案的參數（SCHEME_SUBMODULE、SCHEME_ID、SCHEME_NAME、SCHEME_LABEL、SCHEME_LANG_CODE、TOO）
- [ ] 6.2 建立 `packaging/Dockerfile-22.04`，基於 Ubuntu 22.04，安裝 fcitx5 開發依賴、建置指定方案、產出 .deb（動態連結 librime）
- [ ] 6.3 建立 `packaging/Dockerfile-24.04`，基於 Ubuntu 24.04 的對應版本
- [ ] 6.4 建立 `packaging/build-all.sh`，讀取 schemes.conf 對每個方案分別以 22.04 和 24.04 各建置一次，產出 10 個 .deb 至 `build/` 目錄

## 7. 打包：Fedora 與 Arch Linux

- [ ] 7.1 建立 `packaging/fcitx5-scheme.spec`，提供 Fedora/openSUSE RPM spec 範例（參數化 SCHEME_ID/SCHEME_NAME）
- [ ] 7.2 建立 `packaging/PKGBUILD`，提供 Arch Linux PKGBUILD 範例（參數化 SCHEME_ID/SCHEME_NAME）

## 8. 驗證

- [ ] 8.1 不帶 `-DSCHEME_ID` 建置，確認行為與上游 fcitx5-rime 一致（回歸測試）
- [ ] 8.2 以 `-DSCHEME_ID=hanlo -DSCHEME_NAME=意傳教育部漢羅` 建置，確認產出 `libhanlo.so`、`hanlo.conf`、addon conf，且資料檔正確安裝
- [ ] 8.3 使用 Dockerfile-22.04 建置 hanlo 的 .deb，確認 `dpkg -c` 內容正確
- [ ] 8.4 在 Ubuntu 環境安裝 .deb，確認 fcitx5 輸入法清單出現漢羅輸入法
