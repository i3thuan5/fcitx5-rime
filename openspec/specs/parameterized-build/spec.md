## Requirements

### Requirement: CMake 參數化建置選項
`CMakeLists.txt` SHALL 提供 `SCHEME_ID` CMake 選項。當設定此選項時（例如 `-DSCHEME_ID=hanlo`），建置系統 SHALL 產出以該方案命名的 fcitx5 addon，而非預設的 `rime` addon。

#### Scenario: 未設定 SCHEME_ID 時保持上游行為
- **WHEN** 未設定 `-DSCHEME_ID` 進行建置
- **THEN** 建置結果 SHALL 與上游 fcitx5-rime 完全一致（addon 名稱為 `rime`，library 為 `librime`）

#### Scenario: 設定 SCHEME_ID 建置特定方案
- **WHEN** 以 `-DSCHEME_ID=hanlo -DSCHEME_NAME=意傳教育部漢羅` 進行建置
- **THEN** 建置結果 SHALL 產出名為 `hanlo` 的 fcitx5 addon（library 為 `libhanlo`）

### Requirement: 相關 CMake 參數
當設定 `SCHEME_ID` 時，建置系統 SHALL 同時接受以下參數：
- `SCHEME_NAME`：方案顯示名稱（例如「意傳教育部漢羅」）
- `SCHEME_LABEL`：輸入法指示器標籤（例如「漢」）
- `SCHEME_LANG_CODE`：語言代碼（例如 `nan-TW`）

#### Scenario: CMake configure 輸出確認
- **WHEN** 以 `-DSCHEME_ID=hanlo -DSCHEME_NAME=意傳教育部漢羅` 執行 cmake
- **THEN** CMake 的 status 訊息 SHALL 顯示正在建置的方案名稱與 ID

### Requirement: 單次建置產出單一方案
每次 CMake 建置 SHALL 只產出一個方案的 addon。若需要 5 個方案，MUST 執行 5 次獨立的建置（各自使用不同的 build 目錄）。

#### Scenario: 建置全部 5 個方案
- **WHEN** 依序以 5 組不同的 SCHEME_ID 參數各自建置
- **THEN** SHALL 產出 5 個獨立的 .so 檔案與對應的 .conf 設定檔

### Requirement: scheme_config.h.in 樣板
專案 SHALL 提供 `src/scheme_config.h.in` 樣板檔，CMake 的 `configure_file()` SHALL 將其中的 `@SCHEME_ID@`、`@SCHEME_NAME@` 等變數替換為實際值，產生 `scheme_config.h`。

#### Scenario: 產生的 scheme_config.h 內容
- **WHEN** 以 `-DSCHEME_ID=hanlo` 執行 cmake configure
- **THEN** 產生的 `scheme_config.h` SHALL 包含 `#define SCHEME_ADDON_NAME "hanlo"` 等定義

### Requirement: scheme_factory.cpp.in 樣板
專案 SHALL 提供 `src/scheme_factory.cpp.in` 樣板檔，用來產生以正確 addon 名稱呼叫 `FCITX_ADDON_FACTORY_V2(@SCHEME_ID@, ...)` 的原始碼。

#### Scenario: 產生的 factory 原始碼
- **WHEN** 以 `-DSCHEME_ID=hanlo` 建置
- **THEN** 產生的 factory 原始碼 SHALL 包含 `FCITX_ADDON_FACTORY_V2(hanlo, ...)`

### Requirement: 方案專屬的 fcitx5 設定檔樣板
專案 SHALL 提供方案專屬的 `.conf` 樣板：
- `src/scheme.conf.in`：InputMethod 設定（Name、Icon、Label、LangCode、Addon）
- `src/scheme-addon.conf.in.in`：Addon 設定（Name、Library、Type 等）

#### Scenario: 產生的 InputMethod 設定檔
- **WHEN** 以 `-DSCHEME_ID=hanlo -DSCHEME_NAME=意傳教育部漢羅` 建置
- **THEN** 產生的 InputMethod 設定 SHALL 包含 `Name=意傳教育部漢羅`、`Addon=hanlo`、`Icon=fcitx-hanlo`
