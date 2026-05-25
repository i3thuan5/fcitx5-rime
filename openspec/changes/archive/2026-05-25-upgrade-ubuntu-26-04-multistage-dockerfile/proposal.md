## Why

Ubuntu 25.10 (Questing Quokka) 已不再是維護目標，Ubuntu 26.04 LTS (Resolute Raccoon) 於 2026 年 4 月發布，套件（`fcitx5-modules-dev`、`libfcitx5core-dev`、`librime-dev`）名稱不變且已確認存在。同時，現有的打包 Dockerfile 是單一 stage，驗證邏輯散在 `test-build.sh` 的多個容器呼叫中，結構零散且有邏輯 bug，趁升版一併整頓。

## What Changes

- 刪除 `packaging/Dockerfile-25.10`，新增 `packaging/Dockerfile-26.04`（5 個 stage：deps / builder / packager / verifier / exporter）
- `packaging/build-all.sh`：`UBUNTU_VER` 改為 `26.04`，`.deb` 提取方式從 `docker create`+`docker cp` 改為 `docker run TAG | cat`
- `packaging/test-build.sh`：**刪除**（驗證已內建於 Dockerfile verifier stage，`build-all.sh` 即是完整驗證）
- 新增 `.travis.yml`：以 PangBoo/.travis.yml 為基底，加入 Docker 服務，CI 直接執行 `build-all.sh`
- `README.md`：補充打包與驗證的使用說明

## Capabilities

### New Capabilities

- `multistage-deb-build`：Dockerfile 以 multi-stage 方式同時負責建置、打包、安裝驗證、.deb 匯出，一個 `docker build` 完成所有流程

### Modified Capabilities

（無 spec 層級的行為變更）

## Impact

- `packaging/Dockerfile-25.10`：刪除
- `packaging/Dockerfile-26.04`：新增（取代舊檔）
- `packaging/build-all.sh`：更新版本變數與 .deb 提取邏輯
- `packaging/test-build.sh`：刪除
- `.travis.yml`：新增
- `README.md`：新增說明
- CI (`check.yml`)：不受影響（使用 `ubuntu-latest`，與 Dockerfile 無關）
