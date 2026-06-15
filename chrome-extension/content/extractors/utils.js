(function () {
  const REMOTE_KEYWORDS = /\b(remote|work from home|wfh|distributed|anywhere|hybrid)\b/i;

  function cleanText(value) {
    return (value || "").replace(/\s+/g, " ").trim();
  }

  function stripTrackingParams(url) {
    try {
      const parsed = new URL(url);
      [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "gh_src", "gh_jid", "source", "ref", "referrer"
      ].forEach((key) => parsed.searchParams.delete(key));
      return parsed.toString();
    } catch {
      return url;
    }
  }

  function metaContent(name) {
    const element = document.querySelector(`meta[name="${name}"], meta[property="${name}"]`);
    return cleanText(element?.getAttribute("content"));
  }

  function firstText(selectors) {
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      const text = cleanText(element?.textContent);
      if (text) return text;
    }
    return "";
  }

  function firstHtmlAsText(selectors) {
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      if (!element) continue;
      const text = cleanText(element.innerText || element.textContent);
      if (text.length >= 40) return text;
    }
    return "";
  }

  function cleanTitle(rawTitle) {
    const title = cleanText(rawTitle);
    if (!title) return "";

    const separators = [" | ", " - ", " — ", " · ", " : "];
    for (const separator of separators) {
      if (!title.includes(separator)) continue;
      const parts = title.split(separator).map((part) => cleanText(part)).filter(Boolean);
      if (parts.length < 2) continue;

      const jobLike = parts.find((part) => /engineer|developer|manager|designer|analyst|director|lead|architect|specialist|coordinator|administrator|intern/i.test(part));
      if (jobLike && jobLike.length < 100) return jobLike;

      const shortest = parts.reduce((best, part) => (part.length < best.length ? part : best), parts[0]);
      if (shortest.length < 80) return shortest;
    }

    const atMatch = title.match(/^(.+?)\s+at\s+(.+)$/i);
    if (atMatch) return cleanText(atMatch[1]);

    return title;
  }

  function parseCompanyFromTitle(rawTitle) {
    const title = cleanText(rawTitle);
    const atMatch = title.match(/\bat\s+(.+)$/i);
    return atMatch ? cleanText(atMatch[1]) : "";
  }

  function isRemote(title, location, description) {
    const combined = `${title} ${location} ${description}`.toLowerCase();
    return REMOTE_KEYWORDS.test(combined);
  }

  function mergeJobs(...jobs) {
    const merged = {
      title: "",
      company_name: "",
      website: "",
      location: "",
      remote: false,
      description: "",
      source: ""
    };

    for (const job of jobs) {
      if (!job) continue;
      if (!merged.title && job.title) merged.title = job.title;
      if (!merged.company_name && job.company_name) merged.company_name = job.company_name;
      if (!merged.website && job.website) merged.website = job.website;
      if (!merged.location && job.location) merged.location = job.location;
      if (!merged.description && job.description) merged.description = normalizeDescription(job.description);
      if (job.remote) merged.remote = true;
      if (!merged.source && job.source) merged.source = job.source;
    }

    if (!merged.website) {
      merged.website = stripTrackingParams(window.location.href);
    }

    if (!merged.remote) {
      merged.remote = isRemote(merged.title, merged.location, merged.description);
    }

    return merged;
  }

  function emptyJob(source) {
    return {
      title: "",
      company_name: "",
      website: stripTrackingParams(window.location.href),
      location: "",
      remote: false,
      description: "",
      source
    };
  }

  function htmlToPlain(html) {
    const formatter = window.JobHunterDescriptionFormat;
    if (formatter) return formatter.htmlToPlain(html);
    return cleanText(html);
  }

  function normalizeDescription(text) {
    const formatter = window.JobHunterDescriptionFormat;
    if (formatter) return formatter.normalizeDescription(text);
    return cleanText(text);
  }

  window.JobHunterUtils = {
    cleanText,
    stripTrackingParams,
    metaContent,
    firstText,
    firstHtmlAsText,
    cleanTitle,
    parseCompanyFromTitle,
    REMOTE_KEYWORDS,
    isRemote,
    mergeJobs,
    emptyJob,
    htmlToPlain,
    normalizeDescription
  };
})();
