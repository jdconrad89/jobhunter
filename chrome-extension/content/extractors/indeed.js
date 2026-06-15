(function () {
  const utils = window.JobHunterUtils;
  const { firstText, firstHtmlAsText, emptyJob, cleanTitle, cleanText, isRemote } = utils;

  function collectText(selectors) {
    const parts = [];
    selectors.forEach((selector) => {
      document.querySelectorAll(selector).forEach((node) => {
        const text = cleanText(node.textContent);
        if (text && !parts.includes(text)) parts.push(text);
      });
    });
    return parts;
  }

  function extractLocation() {
    const direct = firstText([
      "[data-testid='job-location']",
      "[data-testid='inlineHeader-companyLocation']",
      "[data-testid='jobsearch-JobInfoHeader-companyLocation']",
      ".jobsearch-JobInfoHeader-subtitle > div:nth-child(2)"
    ]);
    if (direct) return direct;

    const snippets = collectText([
      "[data-testid='attribute_snippet_testid']",
      "[data-testid='jobsearch-JobMetadataHeader-item']",
      ".jobsearch-JobMetadataHeader-item"
    ]);

    const locationSnippet = snippets.find((text) =>
      /remote|hybrid|on-site|onsite/i.test(text) || /,/.test(text)
    );

    return locationSnippet || snippets[0] || "";
  }

  function extractDescription() {
    const fromSelectors = firstHtmlAsText([
      "#jobDescriptionText",
      ".jobsearch-jobDescriptionText",
      "[id*='jobDescriptionText']",
      "[data-testid='jobsearch-JobComponent-description']",
      ".jobsearch-JobComponent-description"
    ]);

    if (fromSelectors) return fromSelectors;

    return firstHtmlAsText([
      "[data-testid='jobsearch-JobComponent']",
      ".jobsearch-ViewJobLayout--embedded"
    ]);
  }

  function extractIndeed() {
    const job = emptyJob("indeed");

    job.title = cleanTitle(firstText([
      "[data-testid='jobsearch-JobInfoHeader-title'] span",
      "[data-testid='jobsearch-JobInfoHeader-title']",
      ".jobsearch-JobInfoHeader-title span",
      ".jobsearch-JobInfoHeader-title",
      "h1.jobsearch-JobInfoHeader-title",
      "h1"
    ]));

    job.company_name = firstText([
      "[data-company-name='true']",
      "[data-testid='inlineHeader-companyName']",
      "[data-testid='jobsearch-CompanyInfoContainer'] a",
      ".jobsearch-InlineCompanyRating a",
      ".jobsearch-CompanyInfoContainer a"
    ]);

    job.location = extractLocation();
    job.description = extractDescription();

    const metadata = collectText([
      "[data-testid='attribute_snippet_testid']",
      "[data-testid='jobsearch-JobMetadataHeader-item']"
    ]).join(" ");

    job.remote = isRemote(job.title, `${job.location} ${metadata}`, job.description);
    return job;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.indeed = extractIndeed;
})();
