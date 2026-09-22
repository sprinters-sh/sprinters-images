docker build -t sprinters-images-ubuntu-26.04-minimal:dev -f Dockerfile-ubuntu-26.04 --build-arg MINIMAL=true --progress=plain .
docker run -it --rm sprinters-images-ubuntu-26.04-minimal:dev
