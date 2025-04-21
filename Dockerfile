FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip gnupg ca-certificates \
    libglib2.0-0 libnss3 libgconf-2-4 libfontconfig1 libxss1 \
    libappindicator3-1 libasound2 libatk-bridge2.0-0 libgtk-3-0 \
    fonts-liberation xdg-utils libgbm1 libxshmfence1 libxi6 libxtst6 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Add Google's signing key and repo
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Install Google Chrome
RUN apt-get update && apt-get install -y chromium chromium-driver
ENV CHROME_BIN=/usr/bin/chromium

# Install ChromeDriver to match
RUN CHROME_VERSION=$(google-chrome --version | grep -oP '\d+\.\d+\.\d+\.\d+') && \
    DRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION%.*}") && \
    wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${DRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip

# Set environment
ENV CHROME_BIN=/usr/bin/google-chrome
ENV PATH="/usr/local/bin:$PATH"

# Set working dir and copy files
WORKDIR /app
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run your app
CMD ["python", "main.py"]
