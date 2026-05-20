## 1. 移除舊 Dockerfile

- [x] 1.1 刪除 `packaging/Dockerfile-25.10`

## 2. 新增 Dockerfile-26.04（5 stages）

- [x] 2.1 新增 `packaging/Dockerfile-26.04`，Stage 1 `deps`：`FROM ubuntu:26.04`，`apt-get install` 所有 build deps
- [x] 2.2 Stage 2 `builder`：`FROM deps`，`COPY . /src`，cmake + make + `install DESTDIR=/staging`
- [x] 2.3 Stage 3 `packager`：`FROM builder`，建 `DEBIAN/control`，`dpkg-deb --build /staging /output/`
- [x] 2.4 Stage 4 `verifier`：`FROM ubuntu:26.04`，`COPY --from=packager /output/*.deb /tmp/`，`apt-get install fcitx5 librime1`，`dpkg -i`，加所有 `RUN ls/test` 驗證指令
- [x] 2.5 Stage 5 `exporter`：`FROM verifier`，`COPY --from=packager /output/ /output/`，`CMD ["sh","-c","cat /output/*.deb"]`

## 3. 更新 build-all.sh

- [x] 3.1 `UBUNTU_VER` 改為 `26.04`，更新 comment
- [x] 3.2 `DOCKERFILE` 路徑改為 `Dockerfile-26.04`
- [x] 3.3 `.deb` 提取改為 `docker run --rm "$TAG" > "$OUTPUT_DIR/$DEB_FILE"`，移除 `docker create`+`docker cp`+`docker rm`

## 4. 刪除 test-build.sh 並新增 Travis CI

- [x] 4.1 刪除 `packaging/test-build.sh`
- [x] 4.2 新增 `.travis.yml`：以 PangBoo/.travis.yml 為基底，加入 `services: docker`，job 執行 `./packaging/build-all.sh`

## 5. 更新 README.md

- [x] 5.1 補充打包說明：如何用 `build-all.sh` 產生所有方案的 .deb
- [x] 5.2 補充單一方案手動 build 指令範例
- [x] 5.3 移除 test-build.sh 相關說明（若有）
