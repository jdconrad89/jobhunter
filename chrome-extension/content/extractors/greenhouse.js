(function () {
  const utils = window.JobHunterUtils;
  const { firstText, firstHtmlAsText, emptyJob, cleanTitle, cleanText, normalizeDescription, isRemote } = utils;

  function parseGreenhouseUrl(url) {
    try {
      const parsed = new URL(url);

      if (parsed.hostname.includes("greenhouse.io")) {
        const match = parsed.pathname.match(/\/([^/]+)\/jobs\/(\d+)/i);
        if (match) return { board: match[1], jobId: match[2] };
      }

      const ghJid = parsed.searchParams.get("gh_jid");
      if (ghJid) {
        const board = detectBoardFromPage();
        if (board) return { board, jobId: ghJid };
      }
    } catch {
      // Ignore invalid URLs.
    }

    return null;
  }

  function detectBoardFromPage() {
    const html = document.documentElement.innerHTML;
    const patterns = [
      /boards-api\.greenhouse\.io\/v1\/boards\/([^/"'\s?]+)/i,
      /job-boards\.greenhouse\.io\/([^/"'\s?]+)\/jobs/i,
      /boards\.greenhouse\.io\/([^/"'\s?]+)\/jobs/i,
      /"boardToken"\s*:\s*"([^"]+)"/i
    ];

    for (const pattern of patterns) {
      const match = html.match(pattern);
      if (match?.[1] && match[1] !== "internal") return match[1];
    }

    return null;
  }

  function workplaceTypeFromMetadata(metadata) {
    if (!Array.isArray(metadata)) return "";
    const entry = metadata.find((item) => /workplace/i.test(item?.name || ""));
    return cleanText(entry?.value);
  }

  function mapApiPosting(data) {
    const job = emptyJob("greenhouse-api");
    const workplace = workplaceTypeFromMetadata(data.metadata);

    job.title = cleanText(data.title);
    job.company_name = cleanText(data.company_name);
    job.website = data.absolute_url || utils.stripTrackingParams(window.location.href);
    job.location = cleanText(data.location?.name);
    if (workplace) {
      job.location = [workplace, job.location].filter(Boolean).join(" — ");
    }
    job.description = normalizeDescription(data.content);
    job.remote = /remote|hybrid|work from home|telecommute/i.test(`${job.location} ${workplace}`);
    return job;
  }

  async function fetchFromApi(board, jobId) {
    const response = await fetch(
      `https://boards-api.greenhouse.io/v1/boards/${encodeURIComponent(board)}/jobs/${encodeURIComponent(jobId)}?content=true`
    );

    if (!response.ok) {
      throw new Error(`Greenhouse API returned ${response.status}`);
    }

    return response.json();
  }

  function extractGreenhouseFromDom() {
    const job = emptyJob("greenhouse-dom");
    const parsed = parseGreenhouseUrl(window.location.href);

    job.title = cleanTitle(firstText([
      ".job__title",
      ".section-header--large",
      "h1.app-title",
      "h1[data-source='job-title']",
      "#header .app-title",
      "h1"
    ]));

    const logo = document.querySelector(".logo img[alt], .image-container img[alt]");
    job.company_name = cleanText(logo?.getAttribute("alt")) || firstText([
      ".company-name",
      ".main-header-text a",
      "meta[property='og:site_name']"
    ]);

    job.company_name = job.company_name
      .replace(/\s+careers$/i, "")
      .replace(/\s+jobs$/i, "")
      .replace(/^logo\s+/i, "");

    if (!job.company_name && parsed?.board) {
      job.company_name = parsed.board
        .split(/[-_]/)
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(" ");
    }

    job.location = firstText([
      ".job__location",
      ".location",
      ".job__tags .job__location",
      "[class*='job-location']"
    ]);

    job.description = firstHtmlAsText([
      ".job__description",
      "#content",
      ".content",
      "[data-qa='job-description']",
      ".job-post-content"
    ]);

    job.remote = isRemote(job.title, job.location, job.description);
    return job;
  }

  async function extractGreenhouse() {
    const parsed = parseGreenhouseUrl(window.location.href);

    if (parsed?.board && parsed?.jobId) {
      try {
        const data = await fetchFromApi(parsed.board, parsed.jobId);
        const apiJob = mapApiPosting(data);
        const domJob = extractGreenhouseFromDom();
        const merged = utils.mergeJobs(apiJob, domJob);
        merged.source = "greenhouse-api + greenhouse-dom";
        return merged;
      } catch {
        // Fall back to DOM scraping when the API is unavailable.
      }
    }

    const domJob = extractGreenhouseFromDom();
    domJob.source = "greenhouse-dom";
    return domJob;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.greenhouse = extractGreenhouseFromDom;
  window.JobHunterExtractors.greenhouseAsync = extractGreenhouse;
})();
