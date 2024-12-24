# Use an appropriate base image with Java 17 installed
FROM openjdk:17-slim

# Set the working directory
WORKDIR /usr/local/p2rank

# Install wget and tar, download and extract p2rank
RUN apt-get update && apt-get install -y wget tar \
    && wget https://github.com/rdk/p2rank/releases/download/2.5/p2rank_2.5.tar.gz \
    && tar -xzf p2rank_2.5.tar.gz --strip-components=1 \
    && rm p2rank_2.5.tar.gz \
    && chmod +x prank

# Set the environment variable for p2rank
ENV P2RANK_HOME=/usr/local/p2rank

# Add p2rank to the PATH
ENV PATH="$P2RANK_HOME:$PATH"