export function withTimeout(promise, ms, message) {
  return Promise.race([
    promise,
    new Promise((_resolve, reject) => {
      setTimeout(() => reject(new Error(message)), ms);
    })
  ]);
}

export function runtimeMessage(message, timeoutMs = 5000) {
  return withTimeout(
    chrome.runtime.sendMessage(message),
    timeoutMs,
    "Extension background did not respond. Reload the extension on chrome://extensions."
  );
}

export function tabMessage(tabId, message, timeoutMs = 8000) {
  return withTimeout(
    chrome.tabs.sendMessage(tabId, message),
    timeoutMs,
    "Scrape timed out. Refresh the job page, then click Re-scrape page."
  );
}
