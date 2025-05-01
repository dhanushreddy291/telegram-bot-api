# Stage 1: Build Stage
# Use a minimal base image like Alpine for the build environment
FROM alpine:latest as builder

# Update package lists and install necessary build dependencies
# --no-cache reduces image size by not storing the apk cache
RUN apk update && \
    apk upgrade && \
    apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

# Set the working directory inside the container
WORKDIR /app

# Clone the telegram-bot-api repository and its submodules
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git
WORKDIR /app/telegram-bot-api

# Clean up previous builds if any, create a build directory,
# configure with CMake for a Release build and install to /usr/local,
# then build and install the project.
RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local .. && \
    cmake --build . --target install && \
    chmod +x /usr/local/bin/telegram-bot-api*

# Stage 2: Final Image
# Use a minimal base image again for the final runtime environment
FROM alpine:latest
RUN apk --no-cache add libstdc++ libgcc

# Copy only the necessary compiled binary from the build stage to the final image
COPY --from=builder /usr/local/bin/telegram-bot-api* /usr/local/bin/

# Expose the port that the telegram-bot-api application will listen on inside the container (3002)
EXPOSE 3002

# Reference environment variables $API_ID and $API_HASH, which will be substituted at runtime
CMD ["sh", "-c", "telegram-bot-api --local --http-port 3002 --api-id \"$API_ID\" --api-hash \"$API_HASH\""]