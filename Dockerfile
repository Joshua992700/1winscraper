FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip gnupg ca-certificates \
    libglib2.0-0 libnss3 libgconf-2-4 libfontconfig1 libxss1 \
    libappindicator3-1 libasound2 libatk-bridge2.0-0 libgtk-3-0 \
    fonts-liberation xdg-utils libgbm1 libxshmfence1 libxi6 libxtst6 \
     chromium chromium-driver \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CHROME_BIN=/usr/bin/chromium
ENV SELENIUM_MANAGER_SKIP_DOWNLOAD=true

RUN groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser

USER appuser

# Create working directory
WORKDIR /app

# Copy dependencies list
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY main.py .

# Run the app
CMD ["python", "main.py"]

