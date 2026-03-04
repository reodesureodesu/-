from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path("artifacts")
OUT.mkdir(parents=True, exist_ok=True)

TARGET = "http://127.0.0.1:4173"

SCENARIOS = [
    {"name": "web", "viewport": {"width": 1366, "height": 768}},
    {"name": "ios", "viewport": {"width": 390, "height": 844}},
    {"name": "android", "viewport": {"width": 412, "height": 915}},
]


def run_demo(page):
    page.goto(TARGET, wait_until="networkidle")
    page.wait_for_timeout(300)

    page.click('[data-add="heading"]')
    page.click('[data-add="button"]')
    page.click("#alignCenterBtn")
    page.click("#alignMiddleBtn")

    page.click("#placeModeBtn")
    box = page.locator("#phone").bounding_box()
    if box:
        page.select_option("#placeType", "card")
        page.mouse.click(box["x"] + box["width"] * 0.52, box["y"] + box["height"] * 0.72)
    page.click("#placeModeBtn")

    page.click("#previewBtn")
    page.wait_for_timeout(700)
    page.click("#closePreviewBtn")

    page.click("#toggleGridBtn")
    page.click("#toggleSnapBtn")
    page.wait_for_timeout(900)


with sync_playwright() as p:
    browser = p.firefox.launch(headless=True)

    for s in SCENARIOS:
        context = browser.new_context(
            viewport=s["viewport"],
            record_video_dir=str(OUT),
            record_video_size=s["viewport"],
        )
        page = context.new_page()
        run_demo(page)
        context.close()

        vids = sorted(OUT.glob("*.webm"), key=lambda x: x.stat().st_mtime)
        if vids:
            vids[-1].rename(OUT / f"tapapp-demo-{s['name']}.webm")

    browser.close()
