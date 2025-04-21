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

# Install Chrome for Testing
RUN wget -O /tmp/chrome-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/${CFT_VERSION}/linux64/chrome-linux64.zip && \
    unzip /tmp/chrome-linux64.zip -d /opt/ && \
    mv /opt/chrome-linux64 /opt/chrome && \
    ln -s /opt/chrome/chrome /usr/bin/google-chrome && \
    rm /tmp/chrome-linux64.zip

# Install matching ChromeDriver
RUN wget -O /tmp/chromedriver-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/${CFT_VERSION}/linux64/chromedriver-linux64.zip && \
    unzip /tmp/chromedriver-linux64.zip -d /opt/ && \
    mv /opt/chromedriver-linux64/chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    rm /tmp/chromedriver-linux64.zip

# Set environment variables
ENV CHROME_BIN=/usr/bin/google-chrome
ENV PATH="/usr/bin:$PATH"

# Create working directory
WORKDIR /app

# Copy application files
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run the app
CMD ["python", "main.py"]
