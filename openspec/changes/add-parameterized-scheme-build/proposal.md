## Why

fcitx5-rime 目前是 fcitx5 的通用 Rime 包裝器。我們需要讓它產生 5 個獨立的台文輸入法 addon（HanLo、POJ、POJHan、TOJ、TsuanLo），每個都以一級 fcitx5 輸入法的身份出現——與 fcitx5-rime 平起平坐，而非隸屬於它。使用者應該能夠只安裝想要的方案，以獨立套件的形式。這 5 個方案 repo（已在 Sujiphuat-Swift 中以 submodule 管理）需要在此處採用同樣的 submodule 管理方式，並且專案需要參數化的 CMake 建置，從單一程式碼庫產出不同的 addon 二進位檔，同時盡量減少與上游合併時的摩擦。

## What Changes

- 在 `schemes/` 下新增 5 個 git submodule（Rime-HanLo、Rime-POJ、Rime-POJHan、Rime-TOJ、Rime-TsuanLo），指向 `git@github.com:i3thuan5/Rime-*.git`
- 在專案根目錄新增 Rime-Logo git submodule（`git@github.com:i3thuan5/Rime-Logo.git`），提供各方案的主圖示
- 新增 CMake 參數化機制：一個 `-DSCHEME_ID=<id>` 選項，設定後會建置特定方案的 fcitx5 addon，而非通用的 rime addon
- 新增 `scheme_config.h.in` 樣板，用來產生 addon 名稱、顯示名稱、圖示前綴、資料目錄等編譯期定義
- 新增 `scheme_factory.cpp.in` 樣板，用來產生以正確 addon 名稱註冊的 `FCITX_ADDON_FACTORY_V2`
- 新增 `scheme.conf.in` 和 `scheme-addon.conf.in.in` 樣板，用於方案專屬的 fcitx5 輸入法與 addon 設定檔
- 將 `rimeengine.cpp` 中約 20 處硬編碼的 `"rime"` / `"fcitx-rime"` / `"fcitx_rime"` 字串替換為編譯期巨集，並以 `#ifndef` 預設值保留未設定 `-DSCHEME_ID` 時的上游行為
- 新增 `schemes.cmake` 模組，包含參數化建置邏輯，由主 `CMakeLists.txt` 有條件地引入
- 安裝方案資料檔（`*.schema.yaml`、`*.dict.yaml`、`*.symbol.yaml`、`default.yaml`），從 `schemes/<name>/sujiphoat/` 安裝到各方案的 `RIME_DATA_DIR`
- 新增 Ubuntu .deb 打包用的 Dockerfile（參考現有的 Rime-HanLo/ubuntu_script/Dockerfile-22.04 模式，升級為 fcitx5 版本）
- 新增 `packaging/build-all.sh`，一次建置所有 5 個 .deb 套件
- 提供常見 Linux 發行版的打包指引（Fedora/RPM、Arch/PKGBUILD、openSUSE）

## Capabilities

### New Capabilities

- `scheme-submodules`：在 `schemes/` 下以 git submodule 管理 5 個台文輸入法方案 repo，並在專案根目錄以 submodule 管理 Rime-Logo（圖示來源）
- `parameterized-build`：透過 `-DSCHEME_ID` 的 CMake 參數化機制，從共用程式碼庫產出特定方案的 fcitx5 addon
- `scheme-addon-identity`：編譯期身份系統（addon 名稱、圖示、action 名稱、使用者資料目錄），確保多個方案 addon 可以共存而不衝突
- `linux-packaging`：Dockerfile 與腳本，用於產出各方案的 .deb 套件，另附 Fedora、Arch、openSUSE 的打包參考

### Modified Capabilities

（無——沒有需要修改的既有規格）

## Impact

- **src/rimeengine.cpp**：約 20 處字串字面值替換為編譯期巨集。以 `#ifndef` 預設值保留原始行為。這是主要的合併敏感變更。
- **CMakeLists.txt**：小幅新增（約 5 行），有條件地引入 `schemes.cmake`。合併風險低。
- **新增檔案**（scheme_config.h.in、scheme_factory.cpp.in、scheme.conf.in、scheme-addon.conf.in.in、schemes.cmake、packaging/*）：全部為新增，不會與上游衝突。
- **.gitmodules**：新增檔案，包含 6 個 submodule 定義（5 個方案 + Rime-Logo）。
- **建置依賴**：無新增依賴。使用既有的 CMake、fcitx5 與 librime。librime.so 為動態連結（執行期由所有方案 addon 共享）。
- **磁碟空間**：每個 .deb 套件為獨立完整的（約 15-40 MB，視詞典大小而定）。
- **記憶體**：每個啟用的方案 addon 約使用 15-35 MB（主要為詞典）。librime.so 由作業系統共享。安裝 5 個但只啟用 1-2 個，與單一 addon 相比開銷可忽略不計。

### 方案參數（來自 appveyor.yml）

| 方案 | SCHEME_ID | APP_NAME | 詞典 |
|------|-----------|----------|------|
| Rime-HanLo | hanlo | 意傳教育部漢羅 | hanlo.dict.yaml |
| Rime-POJ | poj | ÌTHOÂN POJ | poj.dict.yaml |
| Rime-POJHan | pojhan | 意傳白話字 | pojhan.dict.yaml |
| Rime-TOJ | toj | ÌTHOÂN TOJ | poj.dict.yaml |
| Rime-TsuanLo | tsuanlo | ÌTHUÂN KIP | tsuanlo.dict.yaml |
