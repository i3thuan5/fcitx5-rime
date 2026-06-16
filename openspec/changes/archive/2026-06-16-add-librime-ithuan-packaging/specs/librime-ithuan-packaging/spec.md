## ADDED Requirements

### Requirement: librime-ithuan 可獨立打包為 .deb
客製 librime（`i3thuan5/librime`）SHALL 可被打包為 `librime-ithuan_VERSION_ubuntu24.04.deb`，且安裝後 `librime-ithuan.so.1` 與系統 `librime.so.1` 完全獨立共存，不產生衝突。

#### Scenario: library 名稱與系統版本不同
- **WHEN** 系統已安裝 `librime1`
- **THEN** 安裝 `librime-ithuan.deb` 後，`/usr/lib/x86_64-linux-gnu/librime-ithuan.so.1` 存在，且 `librime.so.1` 不受影響

#### Scenario: pkg-config 可找到 rime-ithuan
- **WHEN** 執行 `pkg-config --libs rime-ithuan`
- **THEN** 輸出包含 `-lrime-ithuan`，不包含 `-lrime`

### Requirement: 方案 .deb 依賴 librime-ithuan 而非 librime1
`fcitx5-{hanlo,poj,pojhan,toj,tsuanlo}.deb` 的 `Depends` 欄位 SHALL 列出 `librime-ithuan`，不列 `librime1`。

#### Scenario: 方案 .deb 可在無系統 librime1 的環境安裝
- **WHEN** 乾淨的 Ubuntu 24.04 環境安裝 `librime-ithuan.deb` + `fcitx5-hanlo.deb`
- **THEN** `dpkg -i` 成功，fcitx5-hanlo 可正常載入，不需要 `librime1` 套件

#### Scenario: 方案 .deb 的 Depends 欄位正確
- **WHEN** 執行 `dpkg -I fcitx5-hanlo.deb`
- **THEN** 輸出的 `Depends:` 包含 `librime-ithuan`，不包含 `librime1`

### Requirement: Docker build 流程先建 librime 再建方案
`packaging/build-all.sh` SHALL 在建立方案 .deb 前先完成 librime-ithuan Docker image 的建置，並透過 Docker image（`COPY --from`）將 librime 的 headers/.so 傳入方案 build stage，不需要在 host 手動傳遞檔案。

#### Scenario: build-all.sh 自動依序執行
- **WHEN** 執行 `./packaging/build-all.sh 2.0.0`
- **THEN** 先產生 `build/deb/librime-ithuan_VERSION_ubuntu24.04.deb`，再產生 5 個方案 .deb，共 6 個檔案

#### Scenario: librime Docker cache 跨方案共用
- **WHEN** 連續 build 5 個方案（librime 原始碼未變動）
- **THEN** librime build stage 僅執行一次（後續由 Docker cache 提供），不重複編譯

### Requirement: librime-ithuan.deb 版本號從原始碼讀取
`librime-ithuan.deb` 的版本號 SHALL 從 `librime-ithuan/CMakeLists.txt` 的 `rime_version` 自動讀取，不由 `build-all.sh` 的參數決定。

#### Scenario: 版本號自動讀取
- **WHEN** 執行 `./packaging/build-all.sh 2.0.0`
- **THEN** librime .deb 版本為 `librime-ithuan/CMakeLists.txt` 中 `rime_version` 的值加 `~ubuntu24.04` 後綴，與傳入的 `2.0.0` 無關

### Requirement: librime-ithuan submodule 納入本 repo
`librime-ithuan/` SHALL 以 git submodule 形式存在於本 repo，指向 `git@github.com:i3thuan5/librime.git`，並在 `.gitmodules` 中正確登錄。

#### Scenario: submodule 可正常初始化
- **WHEN** 執行 `git submodule update --init librime-ithuan`
- **THEN** `librime-ithuan/CMakeLists.txt` 存在，`rime_version` 可讀取
