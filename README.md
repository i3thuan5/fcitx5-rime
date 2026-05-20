## RIME support for Fcitx

RIME(中州韻輸入法引擎) is _mainly_ a Traditional Chinese input method engine.

[![Jenkins Build Status](https://img.shields.io/jenkins/s/https/jenkins.fcitx-im.org/job/fcitx5-rime.svg)](https://jenkins.fcitx-im.org/job/fcitx5-rime/)

[![Coverity Scan Status](https://img.shields.io/coverity/scan/13835.svg)](https://scan.coverity.com/projects/fcitx-fcitx5-rime)

## 打包 .deb（Ubuntu 26.04）

### 建置全部方案

```bash
./packaging/build-all.sh [APP_VERSION]
```

產出所有方案的 `.deb` 至 `build/deb/`。`APP_VERSION` 預設 `2.0.0`。

每個方案的 `docker build` 會執行完整的 build → pack → 安裝驗證流程，成功即輸出 `.deb`。

### 手動建置單一方案

```bash
docker build \
    -f packaging/Dockerfile-26.04 \
    --build-arg SCHEME_SUBMODULE=Rime-HanLo \
    --build-arg SCHEME_ID=hanlo \
    --build-arg "SCHEME_NAME=意傳教育部漢羅" \
    --build-arg SCHEME_LABEL=漢 \
    --build-arg SCHEME_LANG_CODE=nan-TW \
    --build-arg SCHEME_ICON_TOO=kip-hanlo \
    --build-arg APP_VERSION=2.0.0 \
    -t fcitx5-hanlo \
    .

docker run --rm fcitx5-hanlo > fcitx5-hanlo_2.0.0_amd64.deb
```

### 方案清單

方案參數定義於 [`packaging/schemes.conf`](packaging/schemes.conf)。
