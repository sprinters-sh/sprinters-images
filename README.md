# sprinters-images
Sprinters Docker images

## Images

### Ubuntu 26.04

#### x64
- [`ubuntu-26.04`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-26.04)
- [`ubuntu-26.04-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-26.04-minimal)

#### arm64
- [`ubuntu-26.04-arm`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-26.04-arm)
- [`ubuntu-26.04-arm-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-26.04-arm-minimal)

### Ubuntu 24.04

#### x64
- [`ubuntu-24.04`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-24.04)
- [`ubuntu-24.04-slim`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-24.04-slim)
- [`ubuntu-24.04-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-24.04-minimal)

#### arm64
- [`ubuntu-24.04-arm`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-24.04-arm)
- [`ubuntu-24.04-arm-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-24.04-arm-minimal)

### Ubuntu 22.04

#### x64
- [`ubuntu-22.04`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-22.04)
- [`ubuntu-22.04-slim`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-22.04-slim)
- [`ubuntu-22.04-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-22.04-minimal)

#### arm64
- [`ubuntu-22.04-arm`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-22.04-arm)
- [`ubuntu-22.04-arm-minimal`](https://github.com/sprinters-sh/sprinters-images/pkgs/container/sprinters-images-ubuntu-22.04-arm-minimal)

## Build structure

Both Dockerfiles run the scripts in [`images/build`](images/build), which wrap GitHub's
[runner-images](https://github.com/actions/runner-images) scripts, and are split into stages that BuildKit builds in parallel:

- `prepared`, `system-1`, `java` and `system-2` install everything that changes shared state, such as packages, users and
  profiles. They must run one after another, in the order of GitHub's runner images.
- One stage per self-contained tool (Android SDK, CodeQL, PyPy, ...) installs it in isolation with `tool.sh`. Each tool
  is listed in [`tools.txt`](images/build/tools.txt), together with the image variants that exclude it.
- `build` merges the tools into the image with `merge.sh`, installs the toolcache, and finalizes and cleans up.

`tool.sh` exports what an installer added, and fails the build if it did more than adding files below `/usr` and `/opt`
or setting environment variables (apart from `PATH`). Such installers belong in one of the `system` stages.

To add a tool, list it in `tools.txt`, add a stage that runs `tool.sh <name>` to the Dockerfiles, and mount that stage
in the `build` stage. A single stage can be built with `--target`, for example
`docker build -f images/Dockerfile-ubuntu-24.04 --target pypy images`.

## License
MIT License

Copyright (c) 2026 InfrastructureX GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
