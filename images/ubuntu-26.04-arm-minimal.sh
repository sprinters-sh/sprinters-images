RUNNER_IMAGE_VERSION=$(sed -n 's/^ARG RUNNER_IMAGE_VERSION_ARM64=//p' Dockerfile-ubuntu-26.04)
docker buildx build --platform linux/arm64 -t sprinters-images-ubuntu-26.04-arm-minimal:dev -f Dockerfile-ubuntu-26.04 --build-arg RUNNER_IMAGE_VERSION="$RUNNER_IMAGE_VERSION" --build-arg MINIMAL=true --progress=plain . \
  && docker run --platform linux/arm64 -it --rm sprinters-images-ubuntu-26.04-arm-minimal:dev
