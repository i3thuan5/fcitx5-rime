## Context

fcitx5-rime 是上游 fcitx5 的 Rime 輸入法引擎包裝器。我們 fork 了這個專案，目標是從同一份程式碼庫產出 5 個獨立的台文輸入法 fcitx5 addon。現有的 fcitx4 版本（fcitx-rime）已透過 Dockerfile 中的 sed 全文替換達成類似目的，但該方法脆弱且難以維護。

目前 `rimeengine.cpp` 中約有 25 處硬編碼的身份字串（`"rime"`、`"fcitx-rime"`、`"fcitx_rime"`），分布在 action 註冊、property 註冊、圖示名稱、rime traits 設定、設定檔路徑等處。這些字串若不參數化，多個方案 addon 同時安裝會發生名稱衝突。

## Goals / Non-Goals

**Goals:**
- 透過 CMake 參數化，讓單一程式碼庫能為每個方案產出獨立的 fcitx5 addon
- 未設定 `-DSCHEME_ID` 時，建置行為與上游完全一致
- 最小化對上游檔案的修改，降低合併摩擦
- 產出 5 個可獨立安裝的 .deb 套件
- 各方案 addon 可與原版 fcitx5-rime 及彼此共存

**Non-Goals:**
- 不修改 librime 本身
- 不在單次建置中同時產出多個 addon（每次建置一個，用腳本跑 5 次）
- 不處理 macOS/Windows 平台的建置（那是 Sujiphuat-Swift 和 weasel 的範圍）
- 不設計 CI/CD 流程（但提供可被 CI 呼叫的腳本）
- 圖示檔案的實際設計不在範圍內（但提供安裝機制）

## Decisions

### 決策 1：使用 `#include "scheme_config.h"` + `#ifndef` 預設值

**選擇：** 在 `rimeengine.cpp` 頂部加入條件式 include，巨集未定義時回退到上游預設值。

**做法：**
```cpp
// rimeengine.cpp 頂部新增
#ifdef HAVE_SCHEME_CONFIG
#include "scheme_config.h"
#endif

#ifndef SCHEME_ADDON_NAME
#define SCHEME_ADDON_NAME "rime"
#endif
#ifndef SCHEME_ICON_PREFIX
#define SCHEME_ICON_PREFIX "fcitx_rime"
#endif
#ifndef SCHEME_CONF_PREFIX
#define SCHEME_CONF_PREFIX "fcitx-rime"
#endif
#ifndef SCHEME_DISPLAY_NAME
#define SCHEME_DISPLAY_NAME "Rime"
#endif
```

**替代方案考慮：**
- **sed 全文替換（Dockerfile 做法）：** 已被驗證可行（fcitx4 版本在用），但脆弱——上游改了任何字串位置就會壞。放棄。
- **CMake 的 `add_definitions(-DSCHEME_ADDON_NAME=...)`：** 可行但巨集定義散落在 CMakeLists.txt，不如集中在一個 .h.in 樣板清楚。放棄。

**理由：** `#ifndef` 保證不帶參數時行為不變。`scheme_config.h` 由 CMake `configure_file()` 產生，巨集定義集中管理。合併上游時，衝突僅發生在被替換的字串行（上游很少動這些）。

### 決策 2：rimeengine.cpp 中的具體替換清單

以下為所有需要替換的位置與對應巨集：

**rimeengine.cpp:**

| 行號 | 原始值 | 替換為 |
|------|--------|--------|
| 51 | `"rime"` (log category) | `SCHEME_ADDON_NAME` |
| 136 | `"conf/rime.conf"` (safeSaveAsIni) | `"conf/" SCHEME_ADDON_NAME ".conf"` |
| 167 | `"fcitx_rime_disabled"` | `SCHEME_ICON_PREFIX "_disabled"` |
| 169 | `"fcitx_rime_im"` | `SCHEME_ICON_PREFIX "_im"` |
| 194 | `"fcitx-rime-im"` | `SCHEME_CONF_PREFIX "-im"` |
| 199 | `"fcitx-rime-separator"` | `SCHEME_CONF_PREFIX "-separator"` |
| 201 | `"fcitx_rime_deploy"` | `SCHEME_ICON_PREFIX "_deploy"` |
| 210 | `"fcitx-rime-deploy"` | `SCHEME_CONF_PREFIX "-deploy"` |
| 213 | `"fcitx_rime_sync"` | `SCHEME_ICON_PREFIX "_sync"` |
| 223 | `"fcitx-rime-sync"` | `SCHEME_CONF_PREFIX "-sync"` |
| 251 | `"rime"` (user data dir) | `SCHEME_ADDON_NAME` |
| 261 | `"rime.fcitx-rime"` (app_name) | `SCHEME_ADDON_NAME "." SCHEME_CONF_PREFIX` |
| 263 | `"Rime"` (distribution_name) | `SCHEME_DISPLAY_NAME` |
| 264 | `"fcitx-rime"` (distribution_code_name) | `SCHEME_CONF_PREFIX` |
| 317 | `"conf/rime.conf"` (readAsIni) | `"conf/" SCHEME_ADDON_NAME ".conf"` |
| 342 | `"rimeState"` (registerProperty) | `SCHEME_ADDON_NAME "State"` |
| 357 | `"rime"` (inputMethod check) | `SCHEME_ADDON_NAME` |
| 400 | `"rime"` (inputMethod check) | `SCHEME_ADDON_NAME` |
| 523 | `"fcitx-rime-deploy"` (tipId) | `SCHEME_CONF_PREFIX "-deploy"` |
| 524 | `"fcitx_rime_deploy"` (icon) | `SCHEME_ICON_PREFIX "_deploy"` |
| 593 | `"fcitx-rime"` (subModeIcon) | `SCHEME_CONF_PREFIX` |
| 601 | `"fcitx_rime_disable"` | `SCHEME_ICON_PREFIX "_disable"` |
| 603 | `"fcitx_rime_latin"` | `SCHEME_ICON_PREFIX "_latin"` |
| 605 | `"fcitx-rime"` (subModeIcon) | `SCHEME_CONF_PREFIX` |

**rimeengine.h:**

| 行號 | 原始值 | 替換為 |
|------|--------|--------|
| 105 | `"rime"` (userDirectory path) | `SCHEME_ADDON_NAME` |
| 135 | `"conf/rime.conf"` (safeSaveAsIni) | `"conf/" SCHEME_ADDON_NAME ".conf"` |

**rimefactory.cpp:**

| 行號 | 原始值 | 替換為 |
|------|--------|--------|
| 14 | `"fcitx5-rime"` (registerDomain) | `"fcitx5-" SCHEME_ADDON_NAME` |

注意：`rimefactory.cpp` 第 20 行的 `FCITX_ADDON_FACTORY_V2(rime, ...)` **不修改**——改用新的 `scheme_factory.cpp.in` 樣板來處理。

### 決策 3：新增檔案結構

```
Rime-Logo/                    ← git submodule（圖示來源）
schemes/
├── Rime-HanLo/               ← git submodule（方案資料）
├── Rime-POJ/
├── Rime-POJHan/
├── Rime-TOJ/
└── Rime-TsuanLo/
src/
├── scheme_config.h.in        ← CMake configure_file() 樣板
├── scheme_factory.cpp.in     ← 方案專屬的 factory 樣板
├── scheme.conf.in            ← InputMethod 設定樣板
└── scheme-addon.conf.in.in   ← Addon 設定樣板
schemes.cmake                 ← 參數化建置邏輯模組
packaging/
├── Dockerfile-25.10          ← Ubuntu 25.10 .deb 建置
├── build-all.sh              ← 一次建置 5 個 .deb
├── schemes.conf              ← 5 個方案的參數定義
├── fcitx5-scheme.spec        ← Fedora/openSUSE RPM 範例
└── PKGBUILD                  ← Arch Linux 範例
```

### 決策 4：schemes.cmake 的結構

**選擇：** 把參數化建置邏輯獨立成 `schemes.cmake`，主 `CMakeLists.txt` 只加一行引入。

```cmake
# CMakeLists.txt 末尾（feature_summary 之前）新增：
if(SCHEME_ID)
  include(schemes.cmake)
endif()
```

`schemes.cmake` 負責：
1. 驗證必要參數（`SCHEME_ID`、`SCHEME_NAME`）
2. `configure_file()` 產生 `scheme_config.h`
3. `configure_file()` 產生 `scheme_factory.cpp`
4. 為 `rimeengine.cpp` 加上 `-DHAVE_SCHEME_CONFIG` 編譯定義
5. 建置 scheme 專屬的 `.so`（使用 `scheme_factory.cpp` 取代 `rimefactory.cpp`）
6. `configure_file()` 產生 `.conf` 設定檔
7. 安裝 `.so`、`.conf`、scheme 資料檔、圖示檔

**替代方案考慮：**
- **直接在 CMakeLists.txt 裡面寫：** 會增加主檔案的修改量，合併風險上升。放棄。

**理由：** 主 CMakeLists.txt 只加 2 行（`if` + `include`），絕大多數邏輯在新檔案中，與上游零衝突。

### 決策 5：scheme_factory.cpp.in 取代修改 rimefactory.cpp

**選擇：** 不修改 `rimefactory.cpp`，新增 `scheme_factory.cpp.in` 樣板。

```cpp
// src/scheme_factory.cpp.in
#include "rimefactory.h"
#include "rimeengine.h"
#include <fcitx-utils/i18n.h>

namespace fcitx::rime {
AddonInstance *RimeEngineFactory::create(AddonManager *manager) {
    registerDomain("fcitx5-@SCHEME_ID@", FCITX_INSTALL_LOCALEDIR);
    return new RimeEngine(manager->instance());
}
} // namespace fcitx::rime

FCITX_ADDON_FACTORY_V2(@SCHEME_ID@, fcitx::rime::RimeEngineFactory)
```

在 `schemes.cmake` 中用 `configure_file()` 產生 `scheme_factory.cpp`，編譯時用它取代原本的 `rimefactory.cpp`。

**理由：** `rimefactory.cpp` 完全不動，上游更新時零衝突。

### 決策 6：設定檔樣板

**scheme.conf.in:**
```ini
[InputMethod]
Name=@SCHEME_NAME@
Icon=fcitx-@SCHEME_ID@
Label=@SCHEME_LABEL@
LangCode=@SCHEME_LANG_CODE@
Addon=@SCHEME_ID@
Configurable=True
```

**scheme-addon.conf.in.in:**
```ini
[Addon]
Name=@SCHEME_NAME@
Comment=@SCHEME_NAME@ Input Method For Fcitx5
Category=InputMethod
Version=@PROJECT_VERSION@
Library=export:lib@SCHEME_ID@
Type=@FCITX_ADDON_TYPE@
OnDemand=True
Configurable=True

[Addon/Dependencies]
0=core:@REQUIRED_FCITX_VERSION@

[Addon/OptionalDependencies]
0=notifications
1=dbus
```

### 決策 7：scheme 資料檔安裝邏輯

在 `schemes.cmake` 中，安裝 `schemes/${SCHEME_SUBMODULE}/sujiphoat/` 底下的檔案到 `RIME_DATA_DIR`：

```cmake
file(GLOB SCHEME_DATA_FILES "${CMAKE_SOURCE_DIR}/schemes/${SCHEME_SUBMODULE}/sujiphoat/*.yaml")
list(FILTER SCHEME_DATA_FILES EXCLUDE REGEX ".*\\.squirrel\\..*")
install(FILES ${SCHEME_DATA_FILES} DESTINATION "${RIME_DATA_DIR}")
```

用 `EXCLUDE REGEX` 過濾掉 `*.squirrel.symbol.yaml`（macOS 專用）。

### 決策 8：schemes.conf 參數定義檔

在 `packaging/schemes.conf` 集中定義 5 個方案的建置參數：

```
# SCHEME_SUBMODULE  SCHEME_ID  SCHEME_NAME          SCHEME_LABEL  SCHEME_LANG_CODE
Rime-HanLo          hanlo      意傳教育部漢羅        漢             nan-TW
Rime-POJ             poj        ÌTHOÂN_POJ           POJ            nan-TW
Rime-POJHan          pojhan     意傳白話字            白             nan-TW
Rime-TOJ             toj        ÌTHOÂN_TOJ           TOJ            nan-TW
Rime-TsuanLo         tsuanlo    ÌTHUÂN_KIP           全             nan-TW
```

`build-all.sh` 讀取此檔並對每個方案執行一次 cmake 建置。

### 決策 9：Dockerfile 採用 fcitx5 動態連結

**選擇：** 動態連結系統的 `librime.so`，不靜態連結。

**替代方案考慮：**
- **靜態連結 librime（Dockerfile-22.04 的做法）：** 套件更獨立，但體積大、安全更新困難。放棄。

**理由：** fcitx5 生態系統中 `librime` 通常由系統套件提供，動態連結使 .deb 更小且自動受益於系統安全更新。Dependencies 欄位宣告即可確保執行期有 librime。

### 決策 10：圖示檔處理

每個方案需要 6 個圖示（主圖示、im、deploy、latin、disable、sync），分為 48x48 PNG 和 scalable SVG 兩種格式。

**選擇：** 以 git submodule 方式在專案根目錄加入 Rime-Logo（`Rime-Logo/`），建置時從 submodule 中讀取各方案的主圖示。其他 5 個狀態圖示（im、deploy、latin、disable、sync）複製自現有 fcitx5-rime 的圖示並改名。

Rime-Logo submodule 中各方案的圖示路徑：

| 方案 | Rime-Logo 路徑 (TOO) | 安裝為 |
|------|----------------------|--------|
| hanlo | `Rime-Logo/kip-hanlo/fcitx-rime/ithuan.png/svg` | `fcitx-hanlo.png/svg` |
| poj | `Rime-Logo/poj-choanlo/fcitx-rime/ithuan.png/svg` | `fcitx-poj.png/svg` |
| pojhan | `Rime-Logo/poj-hanlo/fcitx-rime/ithuan.png/svg` | `fcitx-pojhan.png/svg` |
| toj | `Rime-Logo/toj/fcitx-rime/ithuan.png/svg` | `fcitx-toj.png/svg` |
| tsuanlo | `Rime-Logo/kip-tsuanlo/fcitx-rime/ithuan.png/svg` | `fcitx-tsuanlo.png/svg` |

`schemes.cmake` 在安裝時直接從 `Rime-Logo/<TOO>/fcitx-rime/` 讀取主圖示，安裝到 icon theme 路徑。需要新增 CMake 參數 `SCHEME_ICON_TOO` 來指定各方案在 Rime-Logo 中對應的目錄名稱。

**替代方案考慮：**
- **預先複製到 `data/icons/`：** 可行但圖示更新時需手動重新複製，不如 submodule 自動同步。放棄。

### 決策 11：RIME_DATA_DIR 採用各方案獨立目錄

**選擇：** 每個方案使用獨立的 `RIME_DATA_DIR`，路徑為 `/usr/share/<SCHEME_ID>/data`。

在 `schemes.cmake` 中覆蓋：
```cmake
set(RIME_DATA_DIR "${CMAKE_INSTALL_PREFIX}/share/${SCHEME_ID}/data")
```

**理由：** 多方案各有自己的 `default.yaml`（`schema_list` 不同），獨立目錄避免互相覆蓋，也與 Dockerfile-22.04 的做法一致（`/usr/share/${APP_LINUX_ID}/data`）。

### 決策 12：Dockerfile 支援 Ubuntu 25.10，另附 Fedora/Arch 套件

**選擇：** 提供一個 Dockerfile variant：
- `packaging/Dockerfile-25.10` — Ubuntu 25.10 (Questing)

另外提供：
- `packaging/fcitx5-scheme.spec` — Fedora/openSUSE RPM spec 範例
- `packaging/PKGBUILD` — Arch Linux PKGBUILD 範例

`build-all.sh` 預設建置 25.10 版本，共 5 個 .deb 檔。

**版本限制：** 本專案使用 `FCITX_ADDON_FACTORY_V2` 巨集（fcitx5 5.1.9 引入），且上游 CMakeLists.txt 要求 Fcitx5Core >= 5.1.13。Ubuntu 24.04 的 fcitx5 僅 5.1.7，不符合要求。Ubuntu 25.10 提供 fcitx5 5.1.14，滿足需求。

**替代方案考慮：**
- **Rebase 到 fcitx5-rime 5.1.5（相容 fcitx5 5.1.7）：** 可支援 Ubuntu 24.04，但需放棄 namespace 重構、StandardPath 新 API 等上游改進，工作量大。放棄。
- **加 PPA 取得新版 fcitx5：** 增加外部依賴，不穩定。放棄。

## Risks / Trade-offs

**[rimeengine.cpp 合併衝突] → 衝突僅在被替換行**
約 27 處字串替換，上游若修改同一行會衝突。但這些大多是 icon/action 名稱等穩定字串，上游很少動。衝突時修改模式明確（字串 → 巨集），容易解決。

**[rimeengine.h 也需修改] → 2 處修改**
第 105 行和第 135 行有硬編碼的 `"rime"` 和 `"conf/rime.conf"`，也需替換為巨集。需要在 `rimeengine.h` 頂部加入同樣的 `#ifdef` / `#ifndef` 區塊。合併風險與 rimeengine.cpp 相同。

**[RIME_DATA_DIR 共用問題] → 已決定採用獨立目錄**
每個方案使用獨立的 `RIME_DATA_DIR`（例如 `/usr/share/hanlo/data`），避免 `default.yaml` 互相覆蓋。見決策 11。

**[librime 版本相容性] → 依賴系統套件版本**
動態連結意味著依賴系統提供的 librime 版本。若特定方案需要較新的 librime 功能，可能與舊版系統不相容。緩解方式：在 .deb 的 Depends 中宣告最低版本要求。

**[圖示部分差異化] → 主圖示來自 Rime-Logo submodule，狀態圖示仍共用**
主圖示由 Rime-Logo submodule 提供各方案專屬設計，建置時直接從 submodule 路徑讀取。5 個狀態圖示（im、deploy、latin、disable、sync）暫時共用 fcitx5-rime 的設計改名。使用者在輸入法清單中可透過主圖示區分方案，但狀態列圖示外觀相同。

## Open Questions

（已全部解決，記錄於決策 10-12）
