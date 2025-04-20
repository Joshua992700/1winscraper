FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip gnupg ca-certificates \
    libglib2.0-0 libnss3 libgconf-2-4 libfontconfig1 libxss1 \
    libappindicator3-1 libasound2 libatk-bridge2.0-0 libgtk-3-0 \
    fonts-liberation xdg-utils libgbm1 libxshmfence1 libxi6 libxtst6 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# ===== Install Google Chrome (latest stable) =====
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# ===== Dynamically install matching ChromeDriver =====
RUN CHROME_VERSION=$(google-chrome --version | grep -oP '\d+' | head -1) && \
    DRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}") && \
    wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${DRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip

ENV CHROME_BIN=/usr/bin/google-chrome
ENV PATH="/usr/local/bin:$PATH"

# Create working dir
WORKDIR /app

# Copy app files
COPY . /app

# Install Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Run your script
CMD ["python", "main.py"]
