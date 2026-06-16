## 1. 本 repo：加入 librime-ithuan submodule

- [x] 1.1 執行 `git submodule add git@github.com:i3thuan5/librime.git librime-ithuan` 加入 submodule
- [x] 1.2 確認 `.gitmodules` 正確新增 `librime-ithuan` 條目
- [x] 1.3 確認 `librime-ithuan/CMakeLists.txt` 存在且 `rime_version` 可讀取

## 2. 修改 i3thuan5/librime fork（在 librime-ithuan/ 內修改後 push 到上游）

- [x] 2.1 `librime-ithuan/src/CMakeLists.txt`：在 `set_target_properties(rime PROPERTIES ...)` 加入 `OUTPUT_NAME rime-ithuan`（讓 .so 輸出為 `librime-ithuan.so.1`）
- [x] 2.2 `librime-ithuan/rime.pc.in`：`Name:` 改為 `rime-ithuan`，`Libs:` 改為 `-lrime-ithuan`
- [x] 2.3 `librime-ithuan/CMakeLists.txt`：`configure_file(rime.pc.in rime-ithuan.pc)` 並修改 `install(FILES ... rime-ithuan.pc)`
- [ ] 2.4 在 `librime-ithuan/` 內 commit 並 push 到 `i3thuan5/librime`

## 3. 新增 packaging/Dockerfile-librime-24.04

- [x] 3.1 Stage 1（deps）：`FROM ubuntu:24.04`，安裝 librime 的 build dependencies（`build-essential cmake git libboost-all-dev libleveldb-dev libmarisa-dev libyaml-cpp-dev`）
- [x] 3.2 Stage 2（builder）：`COPY librime-ithuan/ /src/librime-ithuan/`，cmake 並 `make install DESTDIR=/staging`
- [x] 3.3 Stage 3（packager）：從 `rime_version` 讀取版本號，寫入 `/librime-version.txt`；建立 DEBIAN/control（`Package: librime-ithuan2`），`Depends` 列出 librime 的 runtime 依賴（leveldb、marisa、yaml-cpp、boost）；`dpkg-deb --build`
- [x] 3.4 Stage 4（verifier）：乾淨 `ubuntu:24.04`，`dpkg -i librime-ithuan2_*.deb`，驗證 `/usr/lib/*/librime-ithuan.so.1` 存在；執行 `printf '#include <rime_api.h>\nint main(){return 0;}' | gcc -x c - $(pkg-config --cflags rime-ithuan) -o /dev/null` 驗證 header 與 pkg-config
- [x] 3.5 Stage 5（exporter）：`FROM verifier`，`CMD cat /output/*.deb`

## 4. 修改 packaging/Dockerfile-24.04（scheme build）

- [x] 4.1 Stage 1（deps）：移除 `apt install librime-dev`；改為 `COPY --from=librime-ithuan-ubuntu24.04 /staging/ /`（取 headers + .so）
- [x] 4.2 Stage 3（packager）：`Depends:` 從 `librime1 (>= 1.7.0)` 改為 `librime-ithuan2`
- [x] 4.3 Stage 4（verifier）：移除 `apt install librime1`；改為 `COPY --from=librime-ithuan-ubuntu24.04 /staging/ /`

## 5. 修改 CMakeLists.txt

- [x] 5.1 `pkg_check_modules(Rime REQUIRED IMPORTED_TARGET "rime>=1.0.0")` 改為 `"rime-ithuan>=1.0.0"`

## 6. 修改 packaging/build-all.sh

- [x] 6.1 Step 0：`docker build -f Dockerfile-librime-24.04 -t librime-ithuan-ubuntu${UBUNTU_VER} $PROJECT_DIR`
- [x] 6.2 Step 0：從 container 取出 `librime-version.txt`，讀取 `LIBRIME_VERSION`
- [x] 6.3 Step 0：`docker run --rm librime-ithuan-ubuntu${UBUNTU_VER} > $OUTPUT_DIR/librime-ithuan2_${LIBRIME_VERSION}~ubuntu${UBUNTU_VER}.deb`
- [x] 6.4 Step 1–5 的迴圈確認沒有傳入 `librime-dev` 相關 build-arg（改由 Docker image 提供）

## 7. 手動驗證（需有 Docker 的機器）

- [ ] 7.1 執行 `./packaging/build-all.sh 2.0.0`，確認 `build/deb/` 出現 6 個 .deb（`librime-ithuan2_1.5.3~ubuntu24.04_amd64.deb` + 5 個方案）
- [ ] 7.2 在乾淨 Ubuntu 24.04 環境安裝 `librime-ithuan2.deb` + `fcitx5-hanlo.deb`，確認無 `librime1` 依賴錯誤
- [ ] 7.3 確認 `librime.so.1`（系統版）與 `librime-ithuan.so.1`（客製版）可同時存在
