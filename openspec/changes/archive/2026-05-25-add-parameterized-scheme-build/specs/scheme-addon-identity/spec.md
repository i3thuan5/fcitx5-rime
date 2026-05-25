## ADDED Requirements

### Requirement: 編譯期身份巨集系統
`rimeengine.cpp` 中所有硬編碼的身份字串 SHALL 替換為編譯期巨集。當未定義 `SCHEME_ADDON_NAME` 時，所有巨集 SHALL 以 `#ifndef` 回退到與上游一致的預設值。

需要參數化的身份字串：
- addon 名稱：`"rime"` → `SCHEME_ADDON_NAME`
- 帶前綴的名稱：`"fcitx-rime"` → `"fcitx-" SCHEME_ADDON_NAME`
- 圖示前綴：`"fcitx_rime"` → `SCHEME_ICON_PREFIX`
- action 名稱：`"fcitx-rime-im"` → `"fcitx-" SCHEME_ADDON_NAME "-im"` 等
- property 名稱：`"rimeState"` → `SCHEME_ADDON_NAME "State"`
- 使用者資料目錄：`"rime"` → `SCHEME_ADDON_NAME`
- 設定檔路徑：`"conf/rime.conf"` → `"conf/" SCHEME_ADDON_NAME ".conf"`
- rime traits 的 app_name、distribution_name、distribution_code_name
- i18n domain：`"fcitx5-rime"` → `"fcitx5-" SCHEME_ADDON_NAME`

#### Scenario: 未定義 SCHEME_ADDON_NAME 時保持上游行為
- **WHEN** 不帶 `-DSCHEME_ID` 編譯
- **THEN** `rimeengine.cpp` 的行為 SHALL 與上游 fcitx5-rime 完全一致（所有字串皆為原始值）

#### Scenario: 定義 SCHEME_ADDON_NAME 後身份切換
- **WHEN** 以 `-DSCHEME_ID=hanlo` 編譯
- **THEN** 所有身份字串 SHALL 使用 `hanlo` 相關的值

### Requirement: 多方案共存無衝突
當使用者同時安裝多個方案 addon（例如 hanlo 和 poj）時，各 addon SHALL 能共存而不發生衝突。

衝突點包含：
- fcitx5 action 名稱 MUST 各自不同
- fcitx5 property 名稱 MUST 各自不同
- 使用者資料目錄 MUST 各自獨立
- 設定檔路徑 MUST 各自獨立
- addon 載入的 shared library 名稱 MUST 各自不同

#### Scenario: 同時安裝 hanlo 和 poj
- **WHEN** 系統同時安裝了 hanlo addon 和 poj addon
- **THEN** 兩者 SHALL 各自正常運作，fcitx5 不會因名稱衝突而報錯

#### Scenario: action 名稱不重複
- **WHEN** hanlo addon 註冊 action
- **THEN** action 名稱 SHALL 為 `"fcitx-hanlo-im"`、`"fcitx-hanlo-deploy"` 等
- **WHEN** poj addon 註冊 action
- **THEN** action 名稱 SHALL 為 `"fcitx-poj-im"`、`"fcitx-poj-deploy"` 等

### Requirement: 圖示命名與來源
每個方案 addon SHALL 使用以方案名稱為前綴的圖示名稱。主圖示 SHALL 來自 Rime-Logo submodule，狀態圖示 SHALL 複製自現有 fcitx5-rime 圖示並重新命名。

#### Scenario: hanlo 方案的圖示
- **WHEN** hanlo addon 在 fcitx5 中顯示狀態
- **THEN** 使用的圖示名稱 SHALL 為 `fcitx-hanlo`（主圖示）、`fcitx_hanlo_im`（輸入模式）、`fcitx_hanlo_deploy`（部署）、`fcitx_hanlo_latin`（英文模式）、`fcitx_hanlo_disable`（停用）、`fcitx_hanlo_sync`（同步）

#### Scenario: 主圖示來自 Rime-Logo submodule
- **WHEN** 以 `-DSCHEME_ID=hanlo -DSCHEME_ICON_TOO=kip-hanlo` 建置
- **THEN** 主圖示 SHALL 從 `Rime-Logo/kip-hanlo/fcitx-rime/ithuan.png` 及 `.svg` 讀取，安裝為 `fcitx-hanlo.png` 及 `.svg`

### Requirement: 與 fcitx5-rime 共存
方案 addon SHALL 能與原版 fcitx5-rime 在同一系統中共存。

#### Scenario: 與 fcitx5-rime 並存
- **WHEN** 系統已安裝 fcitx5-rime（原版 rime addon），再安裝 hanlo addon
- **THEN** 兩者 SHALL 各自獨立運作，不互相干擾
