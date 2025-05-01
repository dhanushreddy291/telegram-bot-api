# Telegram Local Bot API Server (Docker Image)

This repository provides a Docker image for running the Telegram Bot API server locally.

## Why Run a Local Telegram Bot API Server?

The standard way to interact with the Telegram Bot API is by sending HTTPS requests directly to Telegram's servers (e.g., `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage`). While convenient, this approach has certain limitations, particularly regarding file uploads and potential latency depending on your server's location relative to Telegram's data centers.

The Telegram Bot API team provides a binary that allows developers to run the *same* Bot API server software on their own infrastructure. Running the Bot API server locally offers several advantages:

1.  **Increased File Size Limit:** The standard Bot API has a file upload limit (currently 50MB for regular files, 20MB for photos). Running the local server allows you to upload files up to **2GB** using `sendDocument`, `sendVideo`, etc. This is a significant benefit for applications dealing with larger media.
2.  **Potential Lower Latency:** If your application server is geographically closer to your local Bot API server than to Telegram's main servers, you might experience slightly lower request latency for basic API calls.
3.  **More Control:** You have direct control over the server environment.

This project simplifies the process of setting up and running the local Bot API server by providing a pre-built Docker image.

## Getting Started

To run the local Telegram Bot API server using this Docker image, you need to execute a simple `docker run` command.

**Prerequisites:**

* [Docker](https://www.docker.com/get-started/) installed on your system.
* Your Telegram API ID and API Hash. You can obtain these by logging into [Telegram API Development Tools](https://my.telegram.org/apps). You will need to register a new application.

**Running the Docker Container:**

Execute the following command in your terminal:

```bash
docker run -d -p 3002:3002 \
  -e API_ID="YOUR_TELEGRAM_API_ID" \
  -e API_HASH="YOUR_TELEGRAM_API_HASH" \
  dhanushreddy29/telegram-bot-api
```

Let's break down this command:

* `docker run`: This command runs a Docker container.
* `-d`: This flag runs the container in detached mode, meaning it runs in the background without occupying your terminal.
* `-p 3002:3002`: This maps port 3002 on your host machine to port 3002 inside the container. The local Bot API server listens on port 3002 by default.
* `-e API_ID="YOUR_TELEGRAM_API_ID"`: This sets an environment variable `API_ID` inside the container to your Telegram API ID. **Replace `"YOUR_TELEGRAM_API_ID"` with your actual ID.**
* `-e API_HASH="YOUR_TELEGRAM_API_HASH"`: This sets an environment variable `API_HASH` inside the container to your Telegram API Hash. **Replace `"YOUR_TELEGRAM_API_HASH"` with your actual Hash.**
* `dhanushreddy29/telegram-bot-api`: This is the name of the Docker image to use. The `latest` tag is implicitly used if not specified. This image is multi-architecture (supports `amd64` and `arm64`), so Docker will automatically pull the correct version for your system.

After running this command, the Telegram Bot API server will be running locally, accessible via `http://localhost:3002`.

## Dockerfile Explained

The Docker image is built using the following Dockerfile. Understanding the Dockerfile can be helpful if you want to customize the build process or verify its contents.

```Dockerfile
FROM alpine:latest as builder
RUN apk update && \
    apk upgrade && \
    apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake
WORKDIR /app
RUN git clone --recursive [https://github.com/tdlib/telegram-bot-api.git](https://github.com/tdlib/telegram-bot-api.git)
WORKDIR /app/telegram-bot-api
RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local .. && \
    cmake --build . --target install && \
    chmod +x /usr/local/bin/telegram-bot-api*
FROM alpine:latest
RUN apk --no-cache add libstdc++ libgcc
COPY --from=builder /usr/local/bin/telegram-bot-api* /usr/local/bin/
EXPOSE 3002
CMD ["sh", "-c", "telegram-bot-api --local --http-port 3002 --api-id \"$API_ID\" --api-hash \"$API_HASH\""]
```

This Dockerfile uses a multi-stage build approach:

1.  **Builder Stage (`FROM alpine:latest as builder`)**:
    * This stage is responsible for building the `telegram-bot-api` binary from source code.
    * It starts with a minimal Alpine Linux image.
    * `apk update`, `apk upgrade`, `apk add`: Installs necessary build tools and dependencies (like compilers, git, cmake, zlib, openssl) required to compile the Telegram Bot API source code. `--no-cache` reduces image size.
    * `WORKDIR /app`: Sets the working directory inside the container to `/app`.
    * `git clone --recursive ...`: Clones the official `telegram-bot-api` source code from GitHub, including its submodules.
    * `WORKDIR /app/telegram-bot-api`: Changes the directory to the cloned source code.
    * `rm -rf build && mkdir build && cd build`: Cleans up any previous build artifacts and creates a new `build` directory.
    * `cmake ...`: Configures the build using CMake. `-DCMAKE_BUILD_TYPE=Release` optimizes for performance. `-DCMAKE_INSTALL_PREFIX:PATH=/usr/local` specifies where the built binary should be installed.
    * `cmake --build . --target install`: Compiles the source code and installs the resulting `telegram-bot-api` binary into `/usr/local/bin` within the builder stage.
    * `chmod +x ...`: Ensures the compiled binary is executable.

2.  **Final Stage (`FROM alpine:latest`)**:
    * This is the final, lightweight image that will run the server.
    * It starts with a fresh, minimal Alpine Linux image. This keeps the final image size small by not including build tools.
    * `apk --no-cache add libstdc++ libgcc`: Installs the minimal runtime libraries required by the compiled `telegram-bot-api` binary.
    * `COPY --from=builder ...`: Copies the compiled `telegram-bot-api` binary *from the builder stage* into the final image's `/usr/local/bin` directory.
    * `EXPOSE 3002`: Informs Docker that the container listens on port 3002 at runtime. This is documentation and doesn't actually publish the port; the `-p` flag in `docker run` does that.
    * `CMD ["sh", "-c", "telegram-bot-api --local --http-port 3002 --api-id \"$API_ID\" --api-hash \"$API_HASH\""]`: Specifies the command to run when the container starts.
        * `sh -c`: Executes the following command string using the shell. This is done to correctly handle the environment variables `$API_ID` and `$API_HASH`.
        * `telegram-bot-api`: The name of the executable.
        * `--local`: Tells the API server to run in local mode.
        * `--http-port 3002`: Configures the server to listen on HTTP port 3002.
        * `--api-id "$API_ID"` and `--api-hash "$API_HASH"`: Passes your Telegram API credentials to the server, reading them from the environment variables set by the `docker run -e` flags.

## How to Use the Local API

Once the Docker container is running, you can interact with the local Telegram Bot API server by sending HTTP requests to `http://localhost:3002/`. The format of the requests is similar to the standard Bot API, but you prepend `http://localhost:3002/bot<YOUR_BOT_TOKEN>/` to the method name.

For example, to send a message:

```
http://localhost:3002/bot<YOUR_BOT_TOKEN>/sendMessage?chat_id=xxxx&text=Works
```

Replace `<YOUR_BOT_TOKEN>` with your bot's actual token and `xxxx` with the target chat ID.

You can call any standard Bot API method this way. Importantly, methods for sending files (`sendPhoto`, `sendVideo`, `sendDocument`, etc.) now support file sizes up to **2GB** when using the local API endpoint.

## GitHub Actions Workflow

This section describes the automated process used to build and push the multi-architecture Docker image to Docker Hub whenever changes are made or triggered manually.

```yaml
name: build-and-push

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ${{ matrix.runner }}
    strategy:
      matrix:
        platform: [amd64, arm64] # Build for both AMD64 and ARM64 architectures
        include: # Maps platforms to specific GitHub Actions runners
          - platform: amd64
            runner: ubuntu-24.04 # Use a standard Ubuntu runner for AMD64
          - platform: arm64
            runner: ubuntu-24.04-arm # Use an ARM-based Ubuntu runner for ARM64
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push Docker image
        run: |
            # Builds the Docker image for the specific platform using the Dockerfile in the repository
            docker build --platform linux/${{ matrix.platform }} -t ${{ secrets.DOCKERHUB_USERNAME }}/telegram-bot-api:latest-${{ matrix.platform }} .
            # Pushes the platform-specific image to Docker Hub with a tag indicating the platform
            docker push ${{ secrets.DOCKERHUB_USERNAME }}/telegram-bot-api:latest-${{ matrix.platform }}

  create-manifest:
    runs-on: ubuntu-24.04
    needs: build # This job runs only after the 'build' job has successfully completed
    steps:
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Create and push Docker Manifest
        run: |
            # Define the base image name (e.g., your_dockerhub_username/telegram-bot-api)
            IMAGE_NAME=${{ secrets.DOCKERHUB_USERNAME }}/telegram-bot-api
            # Define the target manifest tag (e.g., latest)
            MANIFEST_TAG=latest

            # Creates a multi-architecture manifest list on Docker Hub
            # This manifest list points to the individual amd64 and arm64 images pushed in the previous job.
            # When a user pulls the manifest tag (e.g., 'latest'), Docker automatically pulls the correct image
            # for their system's architecture.
            docker manifest create \
              $IMAGE_NAME:$MANIFEST_TAG \
              --amend $IMAGE_NAME:latest-amd64 \
              --amend $IMAGE_NAME:latest-arm64

            # Pushes the created manifest list to Docker Hub
            docker manifest push $IMAGE_NAME:$MANIFEST_TAG
```

This workflow performs the following steps:

1.  **Trigger:** It's configured to run manually (`workflow_dispatch`) or can optionally be triggered on pushes to the `main` branch.
2.  **Build Job:**
    * This job runs in parallel for different architectures (`amd64` and `arm64`) using GitHub Actions runners that support those architectures.
    * It checks out the repository code.
    * It logs into Docker Hub using secrets stored in the repository.
    * For each architecture, it builds the Docker image (`docker build`) specifying the target platform (`--platform linux/${{ matrix.platform }}`).
    * It then pushes the built image to Docker Hub with a tag that includes the platform (e.g., `dhanushreddy29/telegram-bot-api:latest-amd64`).
3.  **Create Manifest Job:**
    * This job runs only after *both* the `amd64` and `arm64` builds are successful (`needs: build`).
    * It logs into Docker Hub again.
    * It uses `docker manifest create` to create a *manifest list*. This list is a single tag (`latest` in this case) that points to the platform-specific images pushed in the build job.
    * It then pushes the manifest list to Docker Hub using `docker manifest push`.

The manifest list is crucial because it allows users to simply pull `dhanushreddy29/telegram-bot-api:latest` regardless of their system architecture. Docker will consult the manifest list and automatically pull the `latest-amd64` image if they are on an AMD64 machine or the `latest-arm64` image if they are on an ARM64 machine. This provides a seamless experience for users on different hardware.

> PS: Readme written by Gemini. Too lazy to write it 😎