(function () {
  const utils = window.JobHunterUtils;
  const {
    firstText, firstHtmlAsText, emptyJob, cleanTitle, cleanText,
    normalizeDescription, isRemote, stripTrackingParams
  } = utils;

  const JOB_ID_PATTERN = /^[a-f0-9-]{36}$/i;

  function parseAshbyUrl(url) {
    try {
      const parsed = new URL(url);

      if (parsed.hostname.endsWith("ashbyhq.com")) {
        const parts = parsed.pathname.split("/").filter(Boolean);
        if (parts.length === 0) return null;

        const board = parts[0];
        const jobId = parts[1] && JOB_ID_PATTERN.test(parts[1]) ? parts[1] : null;
        return { board, jobId };
      }

      const embedded = detectAshbyBoardFromPage();
      if (embedded) {
        return { board: embedded, jobId: null };
      }
    } catch {
      // Ignore invalid URLs.
    }

    return null;
  }

  function detectAshbyBoardFromPage() {
    const html = document.documentElement.innerHTML;
    const patterns = [
      /api\.ashbyhq\.com\/posting-api\/job-board\/([^/"'\s?]+)/i,
      /jobs\.ashbyhq\.com\/([^/"'\s?]+)/i,
      /"organizationSlug"\s*:\s*"([^"]+)"/i
    ];

    for (const pattern of patterns) {
      const match = html.match(pattern);
      if (match?.[1]) return match[1];
    }

    const ashbyLink = document.querySelector('a[href*="jobs.ashbyhq.com/"]');
    if (ashbyLink) {
      const parts = new URL(ashbyLink.href).pathname.split("/").filter(Boolean);
      if (parts[0]) return parts[0];
    }

    return null;
  }

  function companyNameFromPage(board) {
    const title = document.title || "";
    const atMatch = title.match(/@\s*(.+)$/);
    if (atMatch) return cleanText(atMatch[1]);

    const ogSite = utils.metaContent("og:site_name");
    if (ogSite) return ogSite.replace(/\s+(careers|jobs)$/i, "");

    return board
      .split(/[-_]/)
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(" ");
  }

  function formatLocation(data) {
    const parts = [];

    if (data.workplaceType) parts.push(data.workplaceType);
    if (data.location) parts.push(cleanText(data.location));

    const secondary = (data.secondaryLocations || [])
      .map((entry) => cleanText(entry.location))
      .filter(Boolean);

    if (secondary.length > 0) parts.push(secondary.join(" / "));

    return parts.join(" — ");
  }

  function buildDescription(data) {
    const sections = [];

    const body = normalizeDescription(data.descriptionPlain || data.descriptionHtml);
    if (body) sections.push(body);

    const compensation = data.compensation?.compensationTierSummary ||
      data.compensation?.scrapeableCompensationSalarySummary;
    if (compensation) sections.push(cleanText(compensation));

    return sections.join("\n\n");
  }

  function findJobInResponse(jobs, parsed, currentUrl) {
    const normalizedUrl = stripTrackingParams(currentUrl).replace(/\/$/, "");

    return jobs.find((job) => {
      if (parsed.jobId && job.id === parsed.jobId) return true;

      const jobUrl = job.jobUrl?.replace(/\/$/, "");
      if (jobUrl && (jobUrl === normalizedUrl || normalizedUrl.startsWith(jobUrl))) return true;

      if (parsed.jobId && job.jobUrl?.includes(parsed.jobId)) return true;

      return false;
    });
  }

  function mapApiPosting(data, board) {
    const job = emptyJob("ashby-api");

    job.title = cleanText(data.title);
    job.company_name = companyNameFromPage(board);
    job.website = data.jobUrl || stripTrackingParams(window.location.href);
    job.location = formatLocation(data);
    job.description = buildDescription(data);
    job.remote = Boolean(data.isRemote) ||
      data.workplaceType === "Remote" ||
      data.workplaceType === "Hybrid" ||
      isRemote(job.title, job.location, job.description);

    return job;
  }

  async function fetchBoard(board) {
    const response = await fetch(
      `https://api.ashbyhq.com/posting-api/job-board/${encodeURIComponent(board)}?includeCompensation=true`
    );

    if (!response.ok) {
      throw new Error(`Ashby API returned ${response.status}`);
    }

    const data = await response.json();
    return data.jobs || [];
  }

  function extractAshbyFromDom() {
    const job = emptyJob("ashby-dom");
    const parsed = parseAshbyUrl(window.location.href);

    job.title = cleanTitle(firstText([
      "h1.ashby-job-posting-heading",
      "[class*='JobPostingHeader'] h1",
      "main h1",
      "h1"
    ]) || utils.metaContent("og:title"));

    job.company_name = companyNameFromPage(parsed?.board || "");
    job.location = firstText([
      "[class*='JobPostingLocation']",
      "[class*='job-location']",
      "[class*='Location']"
    ]);

    job.description = firstHtmlAsText([
      "[class*='JobPostingDescription']",
      "[class*='job-description']",
      "[class*='Description']",
      "main article",
      "main"
    ]);

    job.remote = isRemote(job.title, job.location, job.description);
    return job;
  }

  async function extractAshby() {
    const parsed = parseAshbyUrl(window.location.href);

    if (parsed?.board) {
      try {
        const jobs = await fetchBoard(parsed.board);
        const match = findJobInResponse(jobs, parsed, window.location.href);

        if (match) {
          const apiJob = mapApiPosting(match, parsed.board);
          const domJob = extractAshbyFromDom();
          const merged = utils.mergeJobs(apiJob, domJob);
          merged.source = "ashby-api + ashby-dom";
          return merged;
        }
      } catch {
        // Fall back to DOM scraping when the API is unavailable.
      }
    }

    const domJob = extractAshbyFromDom();
    domJob.source = "ashby-dom";
    return domJob;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.ashby = extractAshbyFromDom;
  window.JobHunterExtractors.ashbyAsync = extractAshby;
})();
