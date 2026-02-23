#!/bin/bash
# test-build.sh - 驗證 tasks 8.1 ~ 8.4
#
# Usage: ./test-build.sh [8.1|8.2|8.3|8.4|all]
#   預設執行全部

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TASK="${1:-all}"
PASS=0
FAIL=0

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
header() { printf "\n\033[1;36m=== %s ===\033[0m\n" "$*"; }

check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        green "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        red "  ✗ $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_file() {
    local desc="$1" path="$2"
    if [ -f "$path" ]; then
        green "  ✓ $desc: $(basename "$path")"
        PASS=$((PASS + 1))
    else
        red "  ✗ $desc: $path not found"
        FAIL=$((FAIL + 1))
    fi
}

# ─── 8.1 不帶 SCHEME_ID 建置（回歸測試） ───
task_8_1() {
    header "8.1 回歸測試：不帶 -DSCHEME_ID 建置"

    local TAG="fcitx5-rime-regression-test"
    local BUILD_DIR="/tmp/test-8.1"

    docker build \
        -f "$SCRIPT_DIR/Dockerfile-24.04" \
        -t "$TAG" \
        "$PROJECT_DIR" \
        --target="" \
        2>&1 || true

    # 用原版方式建置（不帶 SCHEME_ID 參數）
    docker build \
        -f - \
        -t "$TAG" \
        "$PROJECT_DIR" <<'DOCKERFILE'
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
RUN apt-get update && apt-get install -y \
    build-essential cmake extra-cmake-modules gettext git pkg-config \
    fcitx5-modules-dev libfcitx5core-dev librime-dev \
    && rm -rf /var/lib/apt/lists/*
COPY . /src
WORKDIR /build
RUN cmake /src -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
RUN make -j$(nproc)
RUN make install DESTDIR=/staging
RUN find /staging -type f | sort > /file-list.txt
CMD ["cat", "/file-list.txt"]
DOCKERFILE

    echo ""
    echo "已安裝的檔案："
    docker run --rm "$TAG" cat /file-list.txt

    # 驗證產出
    local CONTAINER_ID
    CONTAINER_ID=$(docker create "$TAG")

    check "librime.so 存在" \
        docker run --rm "$TAG" test -f /staging/usr/lib/*/fcitx5/librime.so

    check "addon/rime.conf 存在" \
        docker run --rm "$TAG" test -f /staging/usr/share/fcitx5/addon/rime.conf

    check "inputmethod/rime.conf 存在" \
        docker run --rm "$TAG" test -f /staging/usr/share/fcitx5/inputmethod/rime.conf

    check "沒有產生 scheme 相關檔案" \
        docker run --rm "$TAG" sh -c '! ls /staging/usr/share/hanlo 2>/dev/null'

    docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
}

# ─── 8.2 帶 SCHEME_ID=hanlo 建置 ───
task_8_2() {
    header "8.2 方案建置：-DSCHEME_ID=hanlo"

    local TAG="fcitx5-hanlo-test"

    docker build \
        -f - \
        -t "$TAG" \
        "$PROJECT_DIR" <<'DOCKERFILE'
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
RUN apt-get update && apt-get install -y \
    build-essential cmake extra-cmake-modules gettext git pkg-config \
    fcitx5-modules-dev libfcitx5core-dev librime-dev \
    && rm -rf /var/lib/apt/lists/*
COPY . /src
WORKDIR /build
RUN cmake /src \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DSCHEME_ID=hanlo \
    -DSCHEME_NAME="意傳教育部漢羅" \
    -DSCHEME_SUBMODULE=Rime-HanLo \
    -DSCHEME_ICON_TOO=kip-hanlo \
    -DSCHEME_LABEL="漢" \
    -DSCHEME_LANG_CODE=nan-TW
RUN make -j$(nproc)
RUN make install DESTDIR=/staging
RUN find /staging -type f | sort > /file-list.txt
CMD ["cat", "/file-list.txt"]
DOCKERFILE

    echo ""
    echo "已安裝的檔案："
    docker run --rm "$TAG" cat /file-list.txt

    # 驗證產出
    check "libhanlo.so 存在" \
        docker run --rm "$TAG" sh -c 'ls /staging/usr/lib/*/fcitx5/libhanlo.so'

    check "addon/hanlo.conf 存在" \
        docker run --rm "$TAG" test -f /staging/usr/share/fcitx5/addon/hanlo.conf

    check "inputmethod/hanlo.conf 存在" \
        docker run --rm "$TAG" test -f /staging/usr/share/fcitx5/inputmethod/hanlo.conf

    check "RIME_DATA_DIR 資料檔存在" \
        docker run --rm "$TAG" sh -c 'ls /staging/usr/share/hanlo/data/*.yaml'

    check "squirrel 檔案未安裝" \
        docker run --rm "$TAG" sh -c '! ls /staging/usr/share/hanlo/data/*.squirrel.* 2>/dev/null'

    check "主圖示 fcitx-hanlo.png 存在" \
        docker run --rm "$TAG" sh -c 'ls /staging/usr/share/icons/hicolor/48x48/apps/fcitx-hanlo.png'

    check "主圖示 fcitx-hanlo.svg 存在" \
        docker run --rm "$TAG" sh -c 'ls /staging/usr/share/icons/hicolor/scalable/apps/fcitx-hanlo.svg'

    check "狀態圖示 fcitx_hanlo_im 存在" \
        docker run --rm "$TAG" sh -c 'ls /staging/usr/share/icons/hicolor/48x48/apps/fcitx_hanlo_im.png'

    check "沒有產生原版 rime 檔案" \
        docker run --rm "$TAG" sh -c '! test -f /staging/usr/share/fcitx5/addon/rime.conf'
}

# ─── 8.3 用 Dockerfile-24.04 建 .deb ───
task_8_3() {
    header "8.3 打包：Dockerfile-24.04 建置 hanlo .deb"

    local TAG="fcitx5-hanlo-deb-test"
    local OUTPUT_DIR="$PROJECT_DIR/build/test-deb"
    mkdir -p "$OUTPUT_DIR"

    docker build \
        -f "$SCRIPT_DIR/Dockerfile-24.04" \
        --build-arg "SCHEME_SUBMODULE=Rime-HanLo" \
        --build-arg "SCHEME_ID=hanlo" \
        --build-arg "SCHEME_NAME=意傳教育部漢羅" \
        --build-arg "SCHEME_LABEL=漢" \
        --build-arg "SCHEME_LANG_CODE=nan-TW" \
        --build-arg "SCHEME_ICON_TOO=kip-hanlo" \
        --build-arg "APP_VERSION=1.0.0" \
        -t "$TAG" \
        "$PROJECT_DIR"

    # 取出 .deb
    local CONTAINER_ID
    CONTAINER_ID=$(docker create "$TAG")
    docker cp "$CONTAINER_ID:/output/." "$OUTPUT_DIR/"
    docker rm "$CONTAINER_ID" >/dev/null

    local DEB
    DEB=$(ls "$OUTPUT_DIR"/fcitx5-hanlo_*.deb 2>/dev/null | head -1)

    check ".deb 檔案已產生" test -n "$DEB"

    if [ -n "$DEB" ]; then
        echo ""
        echo "dpkg -c 內容："
        dpkg -c "$DEB" || docker run --rm -v "$DEB:/tmp/pkg.deb" ubuntu:24.04 dpkg -c /tmp/pkg.deb

        echo ""
        echo "dpkg -I 資訊："
        dpkg -I "$DEB" || docker run --rm -v "$DEB:/tmp/pkg.deb" ubuntu:24.04 dpkg -I /tmp/pkg.deb

        # 驗證 .deb 內容
        local DEB_CONTENTS
        DEB_CONTENTS=$(dpkg -c "$DEB" 2>/dev/null || docker run --rm -v "$DEB:/tmp/pkg.deb" ubuntu:24.04 dpkg -c /tmp/pkg.deb)

        check ".deb 包含 libhanlo.so" \
            echo "$DEB_CONTENTS" | grep -q "libhanlo.so"

        check ".deb 包含 addon/hanlo.conf" \
            echo "$DEB_CONTENTS" | grep -q "addon/hanlo.conf"

        check ".deb 包含 inputmethod/hanlo.conf" \
            echo "$DEB_CONTENTS" | grep -q "inputmethod/hanlo.conf"

        check ".deb 包含 hanlo data 資料" \
            echo "$DEB_CONTENTS" | grep -q "hanlo/data/"

        check ".deb 包含 fcitx-hanlo 圖示" \
            echo "$DEB_CONTENTS" | grep -q "fcitx-hanlo"

        echo ""
        green "產出 .deb: $DEB"
    fi
}

# ─── 8.4 安裝 .deb 並驗證 ───
task_8_4() {
    header "8.4 安裝驗證：在 Ubuntu 容器中安裝 .deb"

    local DEB
    DEB=$(ls "$PROJECT_DIR/build/test-deb"/fcitx5-hanlo_*.deb 2>/dev/null | head -1)

    if [ -z "$DEB" ]; then
        red "  找不到 .deb，請先執行 8.3"
        FAIL=$((FAIL + 1))
        return
    fi

    local DEB_BASENAME
    DEB_BASENAME=$(basename "$DEB")

    docker run --rm -v "$DEB:/tmp/$DEB_BASENAME" ubuntu:24.04 bash -c "
        apt-get update -qq
        apt-get install -y -qq fcitx5 librime1 >/dev/null 2>&1 || true
        dpkg -i /tmp/$DEB_BASENAME 2>&1 || apt-get install -f -y -qq 2>&1

        echo '--- 已安裝的檔案 ---'
        dpkg -L fcitx5-hanlo 2>/dev/null || echo '套件未成功安裝'

        echo ''
        echo '--- addon conf 內容 ---'
        cat /usr/share/fcitx5/addon/hanlo.conf 2>/dev/null || echo 'addon conf 不存在'

        echo ''
        echo '--- inputmethod conf 內容 ---'
        cat /usr/share/fcitx5/inputmethod/hanlo.conf 2>/dev/null || echo 'inputmethod conf 不存在'

        echo ''
        echo '--- 資料檔 ---'
        ls -la /usr/share/hanlo/data/ 2>/dev/null || echo '資料目錄不存在'

        echo ''
        echo '--- 圖示 ---'
        find /usr/share/icons -name '*hanlo*' 2>/dev/null || echo '無 hanlo 圖示'
    "

    check ".deb 安裝成功" \
        docker run --rm -v "$DEB:/tmp/$DEB_BASENAME" ubuntu:24.04 bash -c "
            apt-get update -qq >/dev/null 2>&1
            apt-get install -y -qq fcitx5 librime1 >/dev/null 2>&1 || true
            dpkg -i /tmp/$DEB_BASENAME >/dev/null 2>&1 || apt-get install -f -y -qq >/dev/null 2>&1
            dpkg -L fcitx5-hanlo >/dev/null 2>&1
        "
}

# ─── Main ───
echo "專案目錄: $PROJECT_DIR"

case "$TASK" in
    8.1) task_8_1 ;;
    8.2) task_8_2 ;;
    8.3) task_8_3 ;;
    8.4) task_8_4 ;;
    all)
        task_8_1
        task_8_2
        task_8_3
        task_8_4
        ;;
    *)
        echo "Usage: $0 [8.1|8.2|8.3|8.4|all]"
        exit 1
        ;;
esac

# ─── 結果 ───
header "測試結果"
green "通過: $PASS"
if [ "$FAIL" -gt 0 ]; then
    red "失敗: $FAIL"
    exit 1
else
    green "全部通過！"
fi
