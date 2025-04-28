FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip gnupg ca-certificates \
    libglib2.0-0 libnss3 libgconf-2-4 libfontconfig1 libxss1 \
    libappindicator3-1 libasound2 libatk-bridge2.0-0 libgtk-3-0 \
    fonts-liberation xdg-utils libgbm1 libxshmfence1 libxi6 libxtst6 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set version
ENV CFT_VERSION=135.0.7049.95

# Detect architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      CFT_PLATFORM="arm64"; \
    else \
      CFT_PLATFORM="linux64"; \
    fi && \
    \
    # Install Chrome for Testing
    wget -O /tmp/chrome.zip https://storage.googleapis.com/chrome-for-testing-public/${CFT_VERSION}/${CFT_PLATFORM}/chrome-${CFT_PLATFORM}.zip && \
    unzip /tmp/chrome.zip -d /opt/ && \
    mv /opt/chrome-${CFT_PLATFORM} /opt/chrome && \
    ln -s /opt/chrome/chrome /usr/bin/google-chrome && \
    rm /tmp/chrome.zip && \
    \
    # Install matching ChromeDriver
    wget -O /tmp/chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/${CFT_VERSION}/${CFT_PLATFORM}/chromedriver-${CFT_PLATFORM}.zip && \
    unzip /tmp/chromedriver.zip -d /opt/ && \
    mv /opt/chromedriver-${CFT_PLATFORM}/chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    rm /tmp/chromedriver.zip

# Set environment variables
ENV CHROME_BIN=/usr/bin/google-chrome
ENV PATH="/usr/bin:$PATH"

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

