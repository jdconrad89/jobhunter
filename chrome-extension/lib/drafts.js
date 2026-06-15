const DRAFT_PREFIX = "draft:";

function draftKey(url) {
  try {
    const parsed = new URL(url);
    parsed.hash = "";
    [ "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gh_src" ].forEach((key) => {
      parsed.searchParams.delete(key);
    });
    return `${DRAFT_PREFIX}${parsed.toString()}`;
  } catch {
    return `${DRAFT_PREFIX}${url}`;
  }
}

export async function loadDraft(url) {
  const key = draftKey(url);
  const result = await chrome.storage.local.get(key);
  return result[key] || null;
}

export async function saveDraft(url, values) {
  const key = draftKey(url);
  await chrome.storage.local.set({
    [key]: {
      url,
      values,
      updatedAt: Date.now()
    }
  });
}

export async function clearDraft(url) {
  const key = draftKey(url);
  await chrome.storage.local.remove(key);
}

export function mergeScrapedIntoDraft(scraped, draft, { overwrite = false } = {}) {
  const result = { ...draft };

  for (const [field, value] of Object.entries(scraped)) {
    if (field === "source") continue;
    if (field === "remote") {
      if (overwrite || !result.remote) result.remote = Boolean(value);
      continue;
    }

    const existing = (result[field] || "").trim();
    const incoming = (value || "").trim();
    if (!incoming) continue;
    if (overwrite || !existing) result[field] = incoming;
  }

  return result;
}
