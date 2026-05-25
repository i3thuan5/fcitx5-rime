## Requirements

### Requirement: Ubuntu .deb 套件打包
專案 SHALL 提供 Dockerfile，能為每個方案分別產出獨立的 .deb 套件。

每個 .deb 套件 SHALL 包含：
- 方案專屬的 fcitx5 addon shared library（`.so`）
- fcitx5 InputMethod 與 Addon 設定檔（`.conf`）
- 方案資料檔（`*.schema.yaml`、`*.dict.yaml`、`*.symbol.yaml`、`default.yaml`）
- 方案專屬的圖示檔

#### Scenario: 建置 hanlo 的 .deb 套件
- **WHEN** 使用 Dockerfile 以 hanlo 參數建置
- **THEN** SHALL 產出一個可安裝的 .deb 檔案
- **THEN** 該 .deb 的套件名稱 SHALL 包含方案識別（例如 `ithuan-kip-hanlo`）

#### Scenario: 在 Ubuntu 上安裝 .deb
- **WHEN** 使用者在 Ubuntu 上執行 `dpkg -i <hanlo>.deb`
- **THEN** 安裝完成後，fcitx5 的輸入法清單 SHALL 出現漢羅輸入法

### Requirement: 一次建置全部方案的腳本
專案 SHALL 提供 `packaging/build-all.sh` 腳本，一次建置全部 5 個方案的 .deb 套件。

#### Scenario: 執行 build-all.sh
- **WHEN** 執行 `packaging/build-all.sh`
- **THEN** SHALL 在 `build/` 目錄下產出 5 個 .deb 檔案，分別對應 5 個方案

### Requirement: 5 包獨立安裝
每個方案的 .deb 套件 SHALL 為完全獨立的安裝單位。使用者可以自由選擇安裝其中任意一個或多個。

#### Scenario: 只安裝一個方案
- **WHEN** 使用者只安裝 hanlo 的 .deb
- **THEN** hanlo 輸入法 SHALL 正常運作，不依賴其他方案的套件

#### Scenario: 安裝多個方案
- **WHEN** 使用者安裝了 hanlo 和 poj 的 .deb
- **THEN** 兩個輸入法 SHALL 同時出現在 fcitx5 清單中，各自獨立運作

### Requirement: .deb 套件依賴宣告
每個 .deb 套件的 DEBIAN/control SHALL 正確宣告對 fcitx5 與 librime 的執行期依賴。SHALL NOT 將 librime 靜態連結（改為動態連結系統的 librime.so）。

#### Scenario: 依賴檢查
- **WHEN** 檢視 .deb 的 control 檔
- **THEN** Depends 欄位 SHALL 包含 `fcitx5` 與 `librime` 相關套件

### Requirement: 常見 Linux 發行版打包指引
專案 SHALL 在文件中提供以下發行版的打包參考：
- Fedora / RHEL：RPM spec 檔範例
- Arch Linux：PKGBUILD 範例
- openSUSE：RPM spec 或 OBS 建置指引

#### Scenario: 參考文件存在
- **WHEN** 查看 `packaging/` 目錄
- **THEN** SHALL 找到各發行版打包的參考範例或指引文件
