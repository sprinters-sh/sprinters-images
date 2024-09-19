docker build -t sprinter-image-minimal:dev -f Dockerfile-minimal .
docker run --privileged --rm sprinter-image-minimal:dev
