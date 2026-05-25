## Requirements

### Requirement: Ubuntu 26.04 base image
所有打包相關的 Docker 操作 SHALL 使用 `ubuntu:26.04` 作為 base image，不再使用 `ubuntu:25.10`。

#### Scenario: Dockerfile FROM 宣告
- **WHEN** 讀取 `packaging/Dockerfile-26.04`
- **THEN** 第一個 `FROM` 宣告為 `FROM ubuntu:26.04`

### Requirement: Multi-stage Dockerfile
`packaging/Dockerfile-26.04` SHALL 包含 5 個 stage：`deps`、`builder`、`packager`、`verifier`、`exporter`。

#### Scenario: Stage 名稱存在
- **WHEN** 讀取 `packaging/Dockerfile-26.04`
- **THEN** 包含 `AS deps`、`AS builder`、`AS packager`、`AS verifier`、`AS exporter` 共 5 個 stage 宣告

### Requirement: Verifier stage 安裝並驗證 .deb
`verifier` stage SHALL 在乾淨的 `ubuntu:26.04` 環境中安裝 .deb，並以 `RUN` 指令驗證關鍵檔案存在。

#### Scenario: 安裝成功
- **WHEN** `docker build` 執行到 verifier stage
- **THEN** `dpkg -i /tmp/*.deb` 成功，且所有 `RUN ls/test` 指令通過

#### Scenario: 關鍵檔案驗證
- **WHEN** .deb 安裝完成
- **THEN** 以下路徑存在：`/usr/lib/*/fcitx5/lib${SCHEME_ID}.so`、`/usr/share/fcitx5/addon/${SCHEME_ID}.conf`、`/usr/share/fcitx5/inputmethod/${SCHEME_ID}.conf`、`/usr/share/${SCHEME_ID}/data/*.yaml`、`/usr/share/icons/hicolor/48x48/apps/fcitx-${SCHEME_ID}.png`

### Requirement: Exporter stage 繼承 verifier
`exporter` stage SHALL 以 `FROM verifier` 為基礎，確保 `docker build`（預設跑到最後 stage）必定執行驗證。

#### Scenario: 預設 build 執行驗證
- **WHEN** 執行 `docker build -f Dockerfile-26.04 ...`（不指定 `--target`）
- **THEN** verifier stage 的所有 RUN 指令皆被執行

#### Scenario: CMD 輸出 .deb
- **WHEN** 執行 `docker run <image>`
- **THEN** stdout 輸出 .deb 的二進位內容

### Requirement: test-build.sh 刪除
`packaging/test-build.sh` SHALL 不存在於 repository 中。

#### Scenario: 檔案不存在
- **WHEN** 查看 `packaging/` 目錄
- **THEN** 不存在 `test-build.sh` 檔案

### Requirement: Travis CI 執行 build-all.sh
`.travis.yml` SHALL 存在於 repository 根目錄，並在每次 push 時執行 `./packaging/build-all.sh`。

#### Scenario: Travis CI 設定存在
- **WHEN** 讀取 `.travis.yml`
- **THEN** 包含 `services: docker` 與執行 `./packaging/build-all.sh` 的 job

#### Scenario: CI 通過代表全部驗證通過
- **WHEN** Travis CI job `./packaging/build-all.sh` 成功
- **THEN** 所有方案皆已完成 build、pack、以及 verifier stage 的安裝驗證

### Requirement: build-all.sh 用 docker run 提取 .deb
`packaging/build-all.sh` SHALL 使用 `docker run --rm TAG > output.deb` 方式提取 .deb，不使用 `docker create` + `docker cp`。

#### Scenario: .deb 提取
- **WHEN** `build-all.sh` 完成一個方案的 build
- **THEN** 以 `docker run --rm` 將 .deb 內容導出至輸出目錄，無殘餘 container
