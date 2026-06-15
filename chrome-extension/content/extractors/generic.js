(function () {
  const utils = window.JobHunterUtils;
  const {
    cleanText, metaContent, cleanTitle, parseCompanyFromTitle,
    firstText, firstHtmlAsText, emptyJob, isRemote
  } = utils;

  const NOISE_SELECTORS = [
    "nav", "header", "footer", "aside", "script", "style", "noscript",
    "[role='navigation']", "[role='banner']", "[role='contentinfo']",
    ".cookie", ".modal", "#onetrust-consent-sdk"
  ].join(", ");

  function guessCompanyName(rawTitle, description) {
    const siteName = metaContent("og:site_name");
    if (siteName && !/linkedin|indeed|glassdoor|ziprecruiter|monster/i.test(siteName)) {
      return cleanText(siteName.replace(/\s+(careers|jobs)$/i, ""));
    }

    const fromTitle = parseCompanyFromTitle(rawTitle);
    if (fromTitle) return fromTitle;

    const employer = firstText([
      "[itemprop='hiringOrganization']",
      "[itemprop='name']",
      "[class*='company-name']",
      "[class*='CompanyName']",
      "[data-company]"
    ]);
    if (employer) return employer;

    const hiringMatch = description.match(/\b(?:at|join)\s+([A-Z][A-Za-z0-9&.,' -]{2,60})/);
    return hiringMatch ? cleanText(hiringMatch[1]) : "";
  }

  function guessLocation() {
    const fromSelectors = firstText([
      "[data-automation='job-location']",
      "[data-testid='job-location']",
      "[class*='job-location']",
      "[class*='JobLocation']",
      "[itemprop='jobLocation']",
      ".job-location",
      ".posting-categories .location"
    ]);
    if (fromSelectors) return fromSelectors;

    const bodyText = document.body?.innerText || "";
    const locationMatch = bodyText.match(/\b(?:Location|Office|Workplace type):\s*([^\n]{3,100})/i);
    return locationMatch ? cleanText(locationMatch[1]) : "";
  }

  function largestTextBlock() {
    const structured = firstHtmlAsText([
      "[class*='job-description']",
      "[class*='JobDescription']",
      "[id*='job-description']",
      "[data-qa='job-description']",
      "main article",
      "main",
      "article",
      "[role='main']"
    ]);
    if (structured) return structured;

    const clone = document.body?.cloneNode(true);
    if (!clone) return "";

    clone.querySelectorAll(NOISE_SELECTORS).forEach((node) => node.remove());

    let best = "";
    const nodes = clone.querySelectorAll("section, article, div");
    const limit = Math.min(nodes.length, 200);

    for (let i = 0; i < limit; i++) {
      const text = cleanText(nodes[i].innerText);
      if (text.length > best.length && text.length < 25000) {
        best = text;
      }
    }

    return best;
  }

  function extractGenericJob() {
    const rawTitle = firstText(["h1"]) || metaContent("og:title") || document.title;
    const title = cleanTitle(rawTitle);
    const ogDescription = metaContent("og:description");
    const description = largestTextBlock() || (ogDescription.length > 80 ? ogDescription : "");
    const location = guessLocation();
    const companyName = guessCompanyName(rawTitle, description);

    const job = emptyJob("generic");
    job.title = title;
    job.company_name = companyName;
    job.location = location;
    job.description = description;
    job.remote = isRemote(title, location, description);

    return job;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.generic = extractGenericJob;
})();
