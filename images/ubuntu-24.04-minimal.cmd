docker build -t sprinters-images-ubuntu-24.04-minimal:dev -f Dockerfile-ubuntu-24.04 --build-arg MINIMAL=true .
docker run -it --rm sprinters-images-ubuntu-24.04-minimal:dev
