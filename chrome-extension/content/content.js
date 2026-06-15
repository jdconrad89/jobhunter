async function scrapeJob() {
  const extractors = window.JobHunterExtractors || {};
  const utils = window.JobHunterUtils;

  if (!utils) {
    throw new Error("Extension scripts are not loaded on this page. Refresh the page and try again.");
  }

  const host = window.location.hostname;
  const jobs = [];
  const sources = [];

  const hasGreenhouseEmbed = Boolean(
    document.querySelector('script[src*="greenhouse.io"], a[href*="greenhouse.io"], link[href*="greenhouse.io"]') ||
    new URL(window.location.href).searchParams.get("gh_jid")
  );

  const hasAshbyEmbed = Boolean(
    document.querySelector('a[href*="ashbyhq.com"], script[src*="ashbyhq.com"]') ||
    document.documentElement.innerHTML.includes("api.ashbyhq.com/posting-api/job-board/")
  );

  const siteMap = [
    {
      name: "greenhouse",
      match: (h) => h.includes("greenhouse.io") || hasGreenhouseEmbed,
      fn: extractors.greenhouse,
      asyncFn: extractors.greenhouseAsync
    },
    {
      name: "ashby",
      match: (h) => h.includes("ashbyhq.com") || hasAshbyEmbed,
      fn: extractors.ashby,
      asyncFn: extractors.ashbyAsync
    },
    { name: "lever", match: (h) => h.endsWith("lever.co"), fn: extractors.lever, asyncFn: extractors.leverAsync },
    { name: "linkedin", match: (h) => h.includes("linkedin.com"), fn: extractors.linkedin, asyncFn: null },
    { name: "indeed", match: (h) => h.includes("indeed.com"), fn: extractors.indeed, asyncFn: null }
  ];

  const site = siteMap.find((entry) => entry.match(host) && (entry.asyncFn || typeof entry.fn === "function"));

  if (site) {
    if (site.asyncFn) {
      jobs.push(await site.asyncFn());
    } else {
      jobs.push(site.fn());
    }
    sources.push(site.name);
  }

  if (typeof extractors.jsonLd === "function") {
    const jsonLdJob = extractors.jsonLd();
    if (jsonLdJob) {
      jobs.push(jsonLdJob);
      sources.push("json-ld");
    }
  }

  if (typeof extractors.generic === "function") {
    jobs.push(extractors.generic());
    sources.push("generic");
  }

  const result = utils.mergeJobs(...jobs);
  result.description = utils.normalizeDescription(result.description);
  result.source = sources.join(" + ");
  return result;
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type === "SCRAPE_JOB") {
    scrapeJob()
      .then((job) => sendResponse({ ok: true, job }))
      .catch((error) => sendResponse({ ok: false, error: error.message }));

    return true;
  }
});
