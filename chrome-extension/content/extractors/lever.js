(function () {
  const utils = window.JobHunterUtils;
  const { firstText, emptyJob, cleanTitle, htmlToPlain, cleanText, normalizeDescription } = utils;

  const POSTING_ID_PATTERN = /^[a-f0-9-]{36}$/i;

  function parseLeverPostingUrl(url) {
    try {
      const parsed = new URL(url);
      if (!parsed.hostname.endsWith("lever.co")) return null;

      const parts = parsed.pathname.split("/").filter(Boolean);
      if (parts.length >= 2 && POSTING_ID_PATTERN.test(parts[1])) {
        return { company: parts[0], postingId: parts[1] };
      }
    } catch {
      // Ignore invalid URLs.
    }

    return null;
  }

  function companyNameFromPage(companySlug) {
    const pageTitle = document.title || "";
    const titleParts = pageTitle.split(/\s[-–|]\s+/);
    if (titleParts.length >= 2) {
      return cleanText(titleParts[titleParts.length - 1]);
    }

    const header = firstText([
      ".main-header-text a",
      ".main-header-logo img[alt]",
      "meta[property='og:site_name']"
    ]);
    if (header) return header.replace(/\s+jobs$/i, "").replace(/\s+careers$/i, "");

    return companySlug
      .split(/[-_]/)
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(" ");
  }

  function formatSalaryRange(salaryRange, salaryDescriptionPlain) {
    if (!salaryRange) return salaryDescriptionPlain || "";

    const min = salaryRange.min?.toLocaleString();
    const max = salaryRange.max?.toLocaleString();
    const currency = salaryRange.currency || "USD";
    const interval = (salaryRange.interval || "").replace(/-/g, " ");

    let range = "";
    if (min && max) range = `${currency} ${min} - ${max}`;
    else if (min) range = `${currency} ${min}+`;

    if (interval) range = range ? `${range} (${interval})` : interval;

    const extra = salaryDescriptionPlain ? cleanText(salaryDescriptionPlain) : "";
    return [range, extra].filter(Boolean).join(" — ");
  }

  function buildDescriptionFromApi(data) {
    const sections = [];

    const body = normalizeDescription(data.descriptionPlain || data.description);
    if (body) sections.push(body);

    if (Array.isArray(data.lists)) {
      data.lists.forEach((list) => {
        const heading = cleanText(list.text);
        const items = htmlToPlain(list.content);
        if (heading && items) sections.push(`${heading}\n${items}`);
        else if (items) sections.push(items);
      });
    }

    const salary = formatSalaryRange(data.salaryRange, data.salaryDescriptionPlain);
    if (salary) sections.push(salary);

    const closing = normalizeDescription(data.additionalPlain || data.additional);
    if (closing) sections.push(closing);

    return sections.join("\n\n");
  }

  function mapApiPosting(data, companySlug) {
    const job = emptyJob("lever-api");
    job.title = cleanText(data.text);
    job.company_name = companyNameFromPage(companySlug);
    job.website = data.hostedUrl || utils.stripTrackingParams(window.location.href);
    job.location = cleanText(data.categories?.location) ||
      (data.categories?.allLocations || []).map(cleanText).filter(Boolean).join(" / ");
    job.remote = data.workplaceType === "remote" ||
      /remote|hybrid|work from home/i.test(`${job.location} ${data.workplaceType || ""}`);
    job.description = buildDescriptionFromApi(data);
    return job;
  }

  async function fetchFromApi(company, postingId) {
    const response = await fetch(
      `https://api.lever.co/v0/postings/${encodeURIComponent(company)}/${encodeURIComponent(postingId)}`
    );

    if (!response.ok) {
      throw new Error(`Lever API returned ${response.status}`);
    }

    return response.json();
  }

  function extractLocationFromDom() {
    const location = firstText([
      ".posting-category.location",
      ".sort-by-location",
      ".posting-categories .location",
      "[data-qa='job-location']"
    ]);

    if (location) return location;

    const categories = document.querySelectorAll(".posting-categories > div, .posting-category");
    const texts = Array.from(categories).map((node) => cleanText(node.textContent)).filter(Boolean);

    return texts.find((text) => /remote|hybrid|on-site|office|[A-Za-z]+,\s*[A-Z]{2}/i.test(text)) || texts[0] || "";
  }

  function extractDescriptionFromDom() {
    const sections = [];

    document.querySelectorAll([
      "[data-qa='job-description']",
      "[data-qa='posting-requirements']",
      "[data-qa='salary-range']",
      "[data-qa='closing-description']",
      ".posting-requirements",
      ".content .section.page-centered"
    ].join(", ")).forEach((node) => {
      const text = cleanText(node.innerText || node.textContent);
      if (text.length >= 20 && !sections.includes(text)) {
        sections.push(text);
      }
    });

    if (sections.length > 0) return sections.join("\n\n");

    return utils.firstHtmlAsText([
      ".content .section",
      ".content",
      ".section-wrapper.page",
      ".posting-page"
    ]);
  }

  function extractLeverFromDom() {
    const job = emptyJob("lever-dom");
    const parsed = parseLeverPostingUrl(window.location.href);

    job.title = cleanTitle(firstText([
      ".posting-headline h2",
      "h2.posting-headline",
      ".posting-headline",
      "h1",
      "h2"
    ]));

    job.company_name = companyNameFromPage(parsed?.company || "");
    job.location = extractLocationFromDom();

    const workplaceType = firstText([
      ".posting-category.workplaceTypes",
      ".posting-categories .workplaceTypes"
    ]);
    if (workplaceType) {
      job.location = [workplaceType, job.location].filter(Boolean).join(" — ");
    }

    job.description = extractDescriptionFromDom();
    job.remote = utils.isRemote(job.title, job.location, job.description);

    return job;
  }

  async function extractLever() {
    const parsed = parseLeverPostingUrl(window.location.href);

    if (parsed) {
      try {
        const data = await fetchFromApi(parsed.company, parsed.postingId);
        const apiJob = mapApiPosting(data, parsed.company);
        const domJob = extractLeverFromDom();
        const merged = utils.mergeJobs(apiJob, domJob);
        merged.source = "lever-api + lever-dom";
        return merged;
      } catch {
        // Fall back to DOM scraping when the API is unavailable.
      }
    }

    const domJob = extractLeverFromDom();
    domJob.source = "lever-dom";
    return domJob;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.lever = extractLeverFromDom;
  window.JobHunterExtractors.leverAsync = extractLever;
})();
