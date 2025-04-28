from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, StaleElementReferenceException
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv
import os
import csv
import time

load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# === Setup Headless Chrome ===
chrome_options = Options()
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

service = Service(executable_path="/usr/bin/chromedriver")

driver = webdriver.Chrome(service=service, options=chrome_options)

driver.get("https://1wugnu.com/casino/play/1play_1play_luckyjet")
print("🌐 Loading page...")
time.sleep(15)

# === Switch to iframe if present ===
try:
    iframes = driver.find_elements(By.TAG_NAME, "iframe")
    if iframes:
        print("🔁 Switching to iframe...")
        driver.switch_to.frame(iframes[0])
except Exception as e:
    print(f"⚠️ Iframe error: {e}")

csv_file = "luckyjet_dataset.csv"
index_counter = 1
last_logged_id = None

try:
    with open(csv_file, mode="r") as f:
        index_counter += sum(1 for _ in f) - 1
except FileNotFoundError:
    with open(csv_file, mode="w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["index", "timestamp", "multiplier"])

try:
    while True:
        try:
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((By.ID, "history-item-0"))
            )
            elem = driver.find_element(By.ID, "history-item-0")
            elem_id = elem.get_attribute("id")
            raw_text = elem.text.strip()

            if not raw_text.endswith("x") or "?" in raw_text:
                continue

            multiplier = raw_text.replace("x", "").strip()
            unique_key = f"{elem_id}-{multiplier}"

            if unique_key != last_logged_id:
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"✅ #{index_counter} | {timestamp} | {elem_id} -> {multiplier}x")

                with open(csv_file, mode="a", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow([index_counter, timestamp, multiplier])

                try:
                    supabase.table("history").insert({
                        "index": index_counter,
                        "timestamp": timestamp,
                        "multiplier": float(multiplier)
                    }).execute()
                except Exception as e:
                    print(f"⚠️ Supabase insert error: {e}")

                last_logged_id = unique_key
                index_counter += 1

        except StaleElementReferenceException:
            continue
        except TimeoutException:
            print("⏳ Timeout waiting for history-item-0...")
        except Exception as e:
            print(f"⚠️ Unexpected error: {e}")

        time.sleep(1)

except KeyboardInterrupt:
    print("🛑 Exiting scraper...")

finally:
    driver.quit()
    print("👋 Browser closed.")
