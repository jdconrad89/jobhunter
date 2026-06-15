const DEFAULT_BASE_URL = "http://localhost:3000";

chrome.runtime.onInstalled.addListener(() => {
  chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });
});

async function getSettings() {
  const { apiBaseUrl, apiToken } = await chrome.storage.sync.get({
    apiBaseUrl: DEFAULT_BASE_URL,
    apiToken: ""
  });

  return {
    apiBaseUrl: (apiBaseUrl || DEFAULT_BASE_URL).replace(/\/$/, ""),
    apiToken: apiToken || ""
  };
}

async function createJobPost(jobPost) {
  const { apiBaseUrl, apiToken } = await getSettings();

  if (!apiToken) {
    throw new Error("API token not configured. Open extension options and add your token.");
  }

  const response = await fetch(`${apiBaseUrl}/api/job_posts`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiToken}`
    },
    body: JSON.stringify({ job_post: jobPost })
  });

  const body = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message = body.errors?.join(", ") || body.error || `Request failed (${response.status})`;
    throw new Error(message);
  }

  return body;
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type === "CREATE_JOB_POST") {
    createJobPost(message.jobPost)
      .then((result) => sendResponse({ ok: true, result }))
      .catch((error) => sendResponse({ ok: false, error: error.message }));

    return true;
  }

  if (message.type === "GET_SETTINGS") {
    getSettings()
      .then((settings) => sendResponse({ ok: true, settings }))
      .catch((error) => sendResponse({ ok: false, error: error.message }));

    return true;
  }
});
