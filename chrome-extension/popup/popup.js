const form = document.getElementById("job-form");
const loading = document.getElementById("loading");
const statusEl = document.getElementById("status");
const submitBtn = document.getElementById("submit-btn");

function showStatus(message, type) {
  statusEl.textContent = message;
  statusEl.className = `status visible ${type}`;
}

function clearStatus() {
  statusEl.textContent = "";
  statusEl.className = "status";
}

function setFormValues(job) {
  form.title.value = job.title || "";
  form.company_name.value = job.company_name || "";
  form.website.value = job.website || "";
  form.location.value = job.location || "";
  form.remote.checked = Boolean(job.remote);
  form.description.value = job.description || "";
}

function readFormValues() {
  return {
    title: form.title.value.trim(),
    company_name: form.company_name.value.trim(),
    website: form.website.value.trim(),
    location: form.location.value.trim(),
    remote: form.remote.checked,
    description: form.description.value.trim()
  };
}

async function scrapeActiveTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab?.id) throw new Error("No active tab found.");

  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("Open a job posting page first, then click the extension again.");
  }

  let response;
  try {
    response = await chrome.tabs.sendMessage(tab.id, { type: "SCRAPE_JOB" });
  } catch {
    throw new Error("Refresh this page, then try again. The extension could not read the tab.");
  }

  if (!response?.ok) throw new Error(response?.error || "Could not scrape this page.");

  return response.job;
}

async function ensureConfigured() {
  const response = await chrome.runtime.sendMessage({ type: "GET_SETTINGS" });
  if (!response?.ok) throw new Error(response?.error || "Could not load settings.");

  if (!response.settings.apiToken) {
    throw new Error("Add your API token in extension settings before importing.");
  }
}

document.getElementById("open-options").addEventListener("click", (event) => {
  event.preventDefault();
  chrome.runtime.openOptionsPage();
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  clearStatus();

  const jobPost = readFormValues();
  if (!jobPost.title || !jobPost.company_name || !jobPost.website) {
    showStatus("Title, company, and job URL are required.", "error");
    return;
  }

  submitBtn.disabled = true;
  showStatus("Saving to JobHunter…", "info");

  const response = await chrome.runtime.sendMessage({
    type: "CREATE_JOB_POST",
    jobPost
  });

  submitBtn.disabled = false;

  if (!response?.ok) {
    showStatus(response?.error || "Failed to save job post.", "error");
    return;
  }

  const url = response.result?.url;
  showStatus("Saved! Opening job post in JobHunter…", "success");

  if (url) {
    chrome.tabs.create({ url });
  }
});

async function init() {
  try {
    await ensureConfigured();
    const job = await scrapeActiveTab();
    setFormValues(job);
    loading.hidden = true;
    form.hidden = false;
  } catch (error) {
    loading.hidden = true;
    showStatus(error.message, "error");
  }
}

init();
