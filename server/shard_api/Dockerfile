FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies including Docker client and Godot dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        wget \
        unzip \
        xvfb \
        libasound2 \
        libgl1-mesa-glx \
        libglu1-mesa \
        libxrandr2 \
        libxi6 \
        libxinerama1 \
        libxcursor1 \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Download and install Godot headless server
RUN wget -q https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip \
    && unzip Godot_v4.3-stable_linux.x86_64.zip \
    && mv Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v4.3-stable_linux.x86_64.zip

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Copy the compiled Godot project (client executable renamed for server use)
# This should be your exported Godot client that can run as both client and server
COPY project-corridor-server /app/project-corridor-server
RUN chmod +x /app/project-corridor-server

# Create Godot project directory and copy project files
RUN mkdir -p /app/godot_server
COPY godot_server/ /app/godot_server/

# Create directory for Godot user data and ensure permissions
RUN mkdir -p /root/.local/share/godot \
    && chmod -R 755 /app/godot_server \
    && chmod +x /app/project-corridor-server

# Start Xvfb for headless display (needed even for headless Godot)
RUN echo '#!/bin/bash\nXvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &\nexport DISPLAY=:99\nexec "$@"' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8081/health || exit 1

# Use entrypoint script to start Xvfb and then the application
ENTRYPOINT ["/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081"]
