const form = document.getElementById("settings-form");
const statusEl = document.getElementById("status");
const tokenInput = document.getElementById("apiToken");
const toggleTokenBtn = document.getElementById("toggle-token");

function showStatus(message) {
  statusEl.textContent = message;
  statusEl.className = "status visible success";
}

async function loadSettings() {
  const { apiBaseUrl, apiToken } = await chrome.storage.sync.get({
    apiBaseUrl: "http://localhost:3000",
    apiToken: ""
  });

  form.apiBaseUrl.value = apiBaseUrl;
  form.apiToken.value = apiToken;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  await chrome.storage.sync.set({
    apiBaseUrl: form.apiBaseUrl.value.trim().replace(/\/$/, ""),
    apiToken: form.apiToken.value.trim()
  });

  showStatus("Settings saved.");
});

toggleTokenBtn.addEventListener("click", () => {
  const isPassword = tokenInput.type === "password";
  tokenInput.type = isPassword ? "text" : "password";
  toggleTokenBtn.textContent = isPassword ? "Hide token" : "Show token";
});

loadSettings();
