# Use Python 3.12 as the base image
FROM python:3.12-slim

# Install necessary system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install UV tool
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Set the working directory in the container
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/enggaraziz/minercli.git /app

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install poetry --root-user-action=ignore && \
    poetry lock --no-update && \
    poetry install --no-root --no-interaction --no-ansi


# Expose any required ports (optional, if the application requires network access)
# EXPOSE 8080

# Pull the latest code and start the miner
CMD ["sh", "-c", "git pull origin main && ./bin/volara mine start"]
