from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
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
# === Supabase Config ===
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# === Setup Browser ===
options = Options()
options.headless = False

driver = webdriver.Remote(
    command_executor='http://127.0.0.1:4444',
    options=options
)

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

# === CSV Setup ===
csv_file = "luckyjet_dataset.csv"
index_counter = 1
last_logged_id = None

# Initialize CSV
try:
    with open(csv_file, mode="r") as f:
        index_counter += sum(1 for _ in f) - 1
except FileNotFoundError:
    with open(csv_file, mode="w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["index", "timestamp", "multiplier"])

# === Main Loop ===
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

            # Use both ID + multiplier as a dedup key
            unique_key = f"{elem_id}-{multiplier}"

            if unique_key != last_logged_id:
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"✅ #{index_counter} | {timestamp} | {elem_id} -> {multiplier}x")

                # Save to CSV
                with open(csv_file, mode="a", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow([index_counter, timestamp, multiplier])

                # Push to Supabase
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
