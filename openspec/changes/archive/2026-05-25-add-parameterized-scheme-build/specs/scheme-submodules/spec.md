## ADDED Requirements

### Requirement: 五個輸入法方案以 git submodule 管理
專案 SHALL 在 `schemes/` 目錄下，以 git submodule 的方式管理以下 5 個台文輸入法方案 repo：
- `schemes/Rime-HanLo` → `git@github.com:i3thuan5/Rime-HanLo.git`
- `schemes/Rime-POJ` → `git@github.com:i3thuan5/Rime-POJ.git`
- `schemes/Rime-POJHan` → `git@github.com:i3thuan5/Rime-POJHan.git`
- `schemes/Rime-TOJ` → `git@github.com:i3thuan5/Rime-TOJ.git`
- `schemes/Rime-TsuanLo` → `git@github.com:i3thuan5/Rime-TsuanLo.git`

此配置 SHALL 與 Sujiphuat-Swift 專案的 submodule 結構一致。

### Requirement: Rime-Logo 以 git submodule 管理
專案 SHALL 在根目錄以 git submodule 的方式管理圖示來源 repo：
- `Rime-Logo/` → `git@github.com:i3thuan5/Rime-Logo.git`

Rime-Logo submodule 提供各方案的主圖示，建置時 SHALL 從此 submodule 讀取對應方案的圖示檔案。

#### Scenario: clone 後初始化 submodule
- **WHEN** 使用者執行 `git clone --recursive` 或 `git submodule update --init`
- **THEN** `schemes/` 下的 5 個子目錄及 `Rime-Logo/` SHALL 各自 checkout 對應 repo 的內容

#### Scenario: submodule 路徑結構
- **WHEN** submodule 初始化完成
- **THEN** 每個方案的 `sujiphoat/` 子目錄 SHALL 存在且包含輸入法資料檔
- **THEN** `Rime-Logo/` 底下 SHALL 包含各方案對應的圖示目錄

#### Scenario: Rime-Logo 圖示路徑
- **WHEN** submodule 初始化完成
- **THEN** 各方案的主圖示 SHALL 位於以下路徑：

| 方案 | 圖示路徑 |
|------|----------|
| hanlo | `Rime-Logo/kip-hanlo/fcitx-rime/ithuan.png` 及 `.svg` |
| poj | `Rime-Logo/poj-choanlo/fcitx-rime/ithuan.png` 及 `.svg` |
| pojhan | `Rime-Logo/poj-hanlo/fcitx-rime/ithuan.png` 及 `.svg` |
| toj | `Rime-Logo/toj/fcitx-rime/ithuan.png` 及 `.svg` |
| tsuanlo | `Rime-Logo/kip-tsuanlo/fcitx-rime/ithuan.png` 及 `.svg` |

### Requirement: 方案資料檔的安裝
建置系統 SHALL 將各方案 `schemes/<name>/sujiphoat/` 底下的必要檔案安裝到 `RIME_DATA_DIR`。

每個方案需要安裝的檔案類型：
- `*.schema.yaml`（輸入法方案定義）
- `*.dict.yaml`（詞典）
- `*.symbol.yaml`（標點符號表，fcitx 版本）
- `default.yaml`（schema_list 設定）

以下檔案 SHALL NOT 被安裝：
- `*.squirrel.symbol.yaml`（macOS Squirrel 專用，fcitx5 不需要）

#### Scenario: 安裝 Rime-HanLo 方案的資料檔
- **WHEN** 以 `-DSCHEME_ID=hanlo` 建置並安裝
- **THEN** 以下檔案 SHALL 被安裝到 `RIME_DATA_DIR`：`default.yaml`、`hanlo.schema.yaml`、`hanlo.dict.yaml`、`hanlo.symbol.yaml`
- **THEN** `hanlo.squirrel.symbol.yaml` SHALL NOT 被安裝

#### Scenario: 各方案資料檔對照
- **WHEN** 分別以各方案的 SCHEME_ID 建置並安裝
- **THEN** 安裝的檔案 SHALL 符合以下對照：

| 方案 | schema.yaml | dict.yaml | symbol.yaml | default.yaml |
|------|-------------|-----------|-------------|--------------|
| hanlo | hanlo.schema.yaml | hanlo.dict.yaml | hanlo.symbol.yaml | default.yaml |
| poj | poj.schema.yaml | poj.dict.yaml | （無） | default.yaml |
| pojhan | pojhan.schema.yaml | pojhan.dict.yaml | pojhan.symbol.yaml | default.yaml |
| toj | poj.schema.yaml | poj.dict.yaml | （無） | default.yaml |
| tsuanlo | tsuanlo.schema.yaml | tsuanlo.dict.yaml | （無） | default.yaml |
