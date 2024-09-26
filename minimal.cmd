docker build -t sprinter-images-minimal:dev -f Dockerfile-minimal .
docker run --privileged --rm sprinter-images-minimal:dev
