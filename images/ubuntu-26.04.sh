docker build -t sprinters-images-ubuntu-26.04:dev -f Dockerfile-ubuntu-26.04 --progress=plain .
docker run -it --rm sprinters-images-ubuntu-26.04:dev
