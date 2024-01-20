# Stage 1: Build stage
FROM alpine:latest as builder

# Update and upgrade packages
RUN apk update && apk upgrade

# Install required dependencies
RUN apk add --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

# Clone the Telegram Bot API repository
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git

# Navigate to the cloned repository
WORKDIR /telegram-bot-api

# Remove existing build directory
RUN rm -rf build

# Create a new build directory
RUN mkdir build

# Navigate to the build directory
WORKDIR /telegram-bot-api/build

# Run cmake to configure the build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. ..

# Build the application
RUN cmake --build . --target telegram-bot-api

# Stage 2: Final stage
FROM alpine:latest

# Copy only the necessary artifacts from the builder stage
COPY --from=builder /telegram-bot-api/build/bin/telegram-bot-api /usr/local/bin/

# Optionally, you can set the default command to run the application
# CMD ["telegram-bot-api"]
