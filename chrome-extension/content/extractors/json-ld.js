(function () {
  const { cleanText, mergeJobs, emptyJob, normalizeDescription } = window.JobHunterUtils;

  function collectNodes(data, results = []) {
    if (!data) return results;

    if (Array.isArray(data)) {
      data.forEach((item) => collectNodes(item, results));
      return results;
    }

    if (typeof data !== "object") return results;

    const type = data["@type"];
    const types = Array.isArray(type) ? type : [type];
    if (types.some((value) => /JobPosting/i.test(String(value)))) {
      results.push(data);
    }

    if (data["@graph"]) collectNodes(data["@graph"], results);

    Object.values(data).forEach((value) => {
      if (value && typeof value === "object") collectNodes(value, results);
    });

    return results;
  }

  function organizationName(organization) {
    if (!organization) return "";
    if (typeof organization === "string") return cleanText(organization);
    return cleanText(organization.name);
  }

  function locationText(jobLocation) {
    if (!jobLocation) return "";

    const locations = Array.isArray(jobLocation) ? jobLocation : [jobLocation];
    const parts = locations.map((entry) => {
      if (typeof entry === "string") return cleanText(entry);
      const address = entry.address || entry;
      if (typeof address === "string") return cleanText(address);
      const pieces = [address.addressLocality, address.addressRegion, address.addressCountry]
        .map(cleanText)
        .filter(Boolean);
      return pieces.join(", ");
    }).filter(Boolean);

    return parts.join(" / ");
  }

  function descriptionText(value) {
    if (!value || typeof value !== "string") return "";
    return normalizeDescription(value);
  }

  function fromPosting(posting) {
    const job = emptyJob("json-ld");
    job.title = cleanText(posting.title);
    job.company_name = organizationName(posting.hiringOrganization || posting.employer);
    job.description = descriptionText(posting.description);
    job.location = locationText(posting.jobLocation);
    job.website = cleanText(posting.url || posting.sameAs) || job.website;

    const remote = posting.jobLocationType === "TELECOMMUTE" || posting.applicantLocationRequirements;
    if (remote) job.remote = true;

    const employment = posting.employmentType;
    if (employment && /remote|telecommute/i.test(String(employment))) {
      job.remote = true;
    }

    return job;
  }

  function extractFromJsonLd() {
    const postings = [];

    document.querySelectorAll('script[type="application/ld+json"]').forEach((script) => {
      try {
        const data = JSON.parse(script.textContent);
        collectNodes(data, postings);
      } catch {
        // Ignore invalid JSON-LD blocks.
      }
    });

    if (postings.length === 0) return null;

    const jobs = postings.map(fromPosting).filter((job) => job.title || job.description);
    return jobs.length > 0 ? mergeJobs(...jobs) : null;
  }

  window.JobHunterExtractors = window.JobHunterExtractors || {};
  window.JobHunterExtractors.jsonLd = extractFromJsonLd;
})();
