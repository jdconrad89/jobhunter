import { loadDraft, saveDraft, clearDraft, mergeScrapedIntoDraft } from "../lib/drafts.js";
import { runtimeMessage, tabMessage } from "../lib/messaging.js";
import { normalizeDescription } from "../lib/description.js";

const form = document.getElementById("job-form");
const loading = document.getElementById("loading");
const statusEl = document.getElementById("status");
const submitBtn = document.getElementById("submit-btn");
const sourceLabel = document.getElementById("source-label");

let activeTab = null;
let saveTimer = null;
let ready = false;
let loadGeneration = 0;

function showStatus(message, type) {
  statusEl.textContent = message;
  statusEl.className = `status visible ${type}`;
}

function clearStatus() {
  statusEl.textContent = "";
  statusEl.className = "status";
}

function showForm() {
  loading.hidden = true;
  form.hidden = false;
}

function setFormValues(job) {
  form.title.value = job.title || "";
  form.company_name.value = job.company_name || "";
  form.website.value = job.website || "";
  form.location.value = job.location || "";
  form.remote.checked = Boolean(job.remote);
  form.description.value = normalizeDescription(job.description || "");
  sourceLabel.textContent = job.source ? `Source: ${job.source}` : "";
}

function readFormValues() {
  const values = {
    title: form.title.value.trim(),
    company_name: form.company_name.value.trim(),
    website: form.website.value.trim(),
    location: form.location.value.trim(),
    remote: form.remote.checked,
    description: normalizeDescription(form.description.value)
  };

  const source = sourceLabel.textContent.replace(/^Source:\s*/, "").trim();
  if (source) values.source = source;

  return values;
}

function scheduleSave() {
  if (!activeTab?.url) return;
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    saveDraft(activeTab.url, readFormValues());
  }, 250);
}

async function getActiveJobTab() {
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tab?.id) throw new Error("No active tab found.");

  if (!tab.url || tab.url.startsWith("chrome://") || tab.url.startsWith("chrome-extension://")) {
    throw new Error("Open a job posting page in this window, then open the side panel again.");
  }

  return tab;
}

async function scrapeTab(tab) {
  let response;
  try {
    response = await tabMessage(tab.id, { type: "SCRAPE_JOB" });
  } catch (error) {
    throw new Error(error.message || "Refresh the job page, then click Re-scrape page.");
  }

  if (!response?.ok) throw new Error(response?.error || "Could not scrape this page.");
  return response.job;
}

async function ensureConfigured() {
  const response = await runtimeMessage({ type: "GET_SETTINGS" });
  if (!response?.ok) throw new Error(response?.error || "Could not load settings.");

  if (!response.settings.apiToken) {
    throw new Error("Add your API token in extension settings before importing.");
  }
}

function blankValues(tabUrl) {
  return {
    title: "",
    company_name: "",
    website: tabUrl,
    location: "",
    remote: false,
    description: "",
    source: ""
  };
}

async function loadFormState({ rescrape = false, overwriteOnRescrape = false } = {}) {
  const generation = ++loadGeneration;
  activeTab = await getActiveJobTab();

  const draft = await loadDraft(activeTab.url);
  let values = draft?.values ? { ...draft.values } : blankValues(activeTab.url);
  if (!values.website) values.website = activeTab.url;

  setFormValues(values);
  showForm();

  try {
    const scraped = await scrapeTab(activeTab);
    if (generation !== loadGeneration) return;

    const existing = readFormValues();
    if (rescrape) {
      values = mergeScrapedIntoDraft(scraped, existing, { overwrite: overwriteOnRescrape });
      values.source = scraped.source;
    } else if (draft?.values) {
      values = mergeScrapedIntoDraft(scraped, draft.values, { overwrite: false });
      values.source = scraped.source || draft.values.source;
    } else {
      values = mergeScrapedIntoDraft(scraped, {}, { overwrite: true });
      values.source = scraped.source;
    }

    if (!values.website) values.website = activeTab.url;

    setFormValues(values);
    await saveDraft(activeTab.url, values);
  } catch (error) {
    if (generation !== loadGeneration) return;
    showStatus(`${error.message} You can still fill in the form manually.`, "error");
  }
}

document.getElementById("open-options").addEventListener("click", (event) => {
  event.preventDefault();
  chrome.runtime.openOptionsPage();
});

document.getElementById("rescrape-btn").addEventListener("click", async () => {
  clearStatus();
  showStatus("Re-scraping page…", "info");

  try {
    await loadFormState({ rescrape: true, overwriteOnRescrape: false });
    showStatus("Re-scrape complete. Filled any empty fields from the page.", "success");
  } catch (error) {
    showStatus(error.message, "error");
  }
});

document.getElementById("clear-draft-btn").addEventListener("click", async () => {
  if (!activeTab?.url) return;
  await clearDraft(activeTab.url);
  setFormValues(blankValues(activeTab.url));
  showStatus("Draft cleared.", "info");
});

form.addEventListener("input", scheduleSave);
form.addEventListener("change", scheduleSave);

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

  let response;
  try {
    response = await runtimeMessage({ type: "CREATE_JOB_POST", jobPost }, 15000);
  } catch (error) {
    submitBtn.disabled = false;
    showStatus(error.message, "error");
    return;
  }

  submitBtn.disabled = false;

  if (!response?.ok) {
    showStatus(response?.error || "Failed to save job post.", "error");
    return;
  }

  if (activeTab?.url) await clearDraft(activeTab.url);

  const url = response.result?.url;
  showStatus("Saved! Opening job post in JobHunter…", "success");

  if (url) chrome.tabs.create({ url });
});

async function reloadForActiveTab() {
  try {
    await loadFormState();
  } catch (error) {
    showForm();
    showStatus(error.message, "error");
  }
}

chrome.tabs.onActivated.addListener(() => {
  if (!ready) return;
  reloadForActiveTab();
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (!ready || changeInfo.status !== "complete") return;
  chrome.tabs.query({ active: true, lastFocusedWindow: true }, ([tab]) => {
    if (tab?.id === tabId) reloadForActiveTab();
  });
});

async function init() {
  try {
    await ensureConfigured();
    ready = true;
    await reloadForActiveTab();
  } catch (error) {
    showForm();
    showStatus(error.message, "error");
  }
}

init();
