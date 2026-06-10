docker buildx build --platform linux/arm64 -t sprinters-images-ubuntu-24.04-arm-minimal:dev -f Dockerfile-ubuntu-24.04 --build-arg MINIMAL=true --progress=plain . \
  && docker run --platform linux/arm64 -it --rm sprinters-images-ubuntu-24.04-arm-minimal:dev
