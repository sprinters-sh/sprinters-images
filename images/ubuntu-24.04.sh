docker build -t sprinters-images-ubuntu-24.04:dev -f Dockerfile-ubuntu-24.04 --progress=plain .
docker run -it --rm sprinters-images-ubuntu-24.04:dev
