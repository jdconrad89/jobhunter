(function () {
  const utils = window.JobHunterUtils;
  const { firstText, firstHtmlAsText, emptyJob, cleanTitle, cleanText, parseCompanyFromTitle, isRemote } = utils;

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
    const bullets = collectText([
      ".job-details-jobs-unified-top-card__bullet",
      ".jobs-unified-top-card__bullet",
      ".job-details-jobs-unified-top-card__job-insight span",
      ".description__job-criteria-item span"
    ]);

    if (bullets.length > 0) {
      const locationBullet = bullets.find((text) =>
        /remote|hybrid|on-site|onsite/i.test(text) ||
        /,/.test(text) ||
        /\b[A-Z]{2}\b/.test(text)
      );
      return locationBullet || bullets[0];
    }

    const tertiary = firstText([
      ".job-details-jobs-unified-top-card__tertiary-description-container",
      ".jobs-unified-top-card__subtitle-primary-grouping",
      ".job-details-jobs-unified-top-card__primary-description-container"
    ]);

    if (tertiary.includes("·")) {
      return cleanText(tertiary.split("·")[0]);
    }

    return tertiary;
  }

  function extractDescription() {
    const fromSelectors = firstHtmlAsText([
      ".jobs-description__content",
      ".jobs-description-content__text",
      ".jobs-box__html-content",
      "#job-details",
      "article.jobs-description__container",
      ".jobs-description"
    ]);

    if (fromSelectors) return fromSelectors;

    const sections = collectText([
      ".jobs-description__content div",
      ".jobs-description-content__text div",
      "#job-details section"
    ]).filter((text) => text.length >= 40);

    return sections.join("\n\n");
  }

  function extractLinkedIn() {
    const job = emptyJob("linkedin");

    job.title = cleanTitle(firstText([
      ".job-details-jobs-unified-top-card__job-title h1",
      ".jobs-unified-top-card__job-title h1",
      ".job-details-jobs-unified-top-card__job-title",
      "h1.t-24",
      "h1.t-32",
      "h1.top-card-layout__title",
      "main h1",
      "h1"
    ]));

    job.company_name = firstText([
      ".job-details-jobs-unified-top-card__company-name a",
      ".job-details-jobs-unified-top-card__company-name",
      ".jobs-unified-top-card__company-name a",
      ".jobs-unified-top-card__company-name",
      "a[data-tracking-control-name='public_jobs_topcard-org-name']",
      ".topcard__org-name-link"
    ]);

    if (!job.company_name) {
      job.company_name = parseCompanyFromTitle(document.title);
    }

    job.location = extractLocation();
    job.description = extractDescription();

    const insights = collectText([
      ".job-details-jobs-unified-top-card__job-insight",
      ".description__job-criteria-text",
      ".description__job-criteria-item"
    ]).join(" ");

    job.remote = isRemote(job.title, `${job.location} ${insights}`, job.description);
    return job;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.linkedin = extractLinkedIn;
})();
