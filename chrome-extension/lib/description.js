const HTML_TAG_PATTERN = /<(?:p|div|br|ul|ol|li|h[1-6]|span|strong|em|a)\b/i;
const ENCODED_HTML_PATTERN = /&lt;(?:p|div|br|ul|ol|li|h[1-6]|span|strong|em|a)\b/i;
const ENTITY_PATTERN = /&(?:lt|gt|quot|nbsp|#39|#x[0-9a-f]+|#\d+);/i;

function decodeHtmlEntities(text, maxPasses = 4) {
  let current = String(text);

  for (let i = 0; i < maxPasses; i++) {
    const element = document.createElement("textarea");
    element.innerHTML = current;
    const decoded = element.value;
    if (decoded === current) break;
    current = decoded;
  }

  return current;
}

function prepareHtmlSource(html) {
  let source = String(html).trim();

  if (ENTITY_PATTERN.test(source)) {
    source = decodeHtmlEntities(source);
  }

  return source;
}

export function looksLikeHtml(text) {
  const value = text || "";
  return HTML_TAG_PATTERN.test(value) || ENCODED_HTML_PATTERN.test(value);
}

export function htmlToPlain(html) {
  if (!html) return "";

  const source = prepareHtmlSource(html);
  const root = document.createElement("div");
  root.innerHTML = source;

  const blocks = [];

  function cleanInline(text) {
    return text.replace(/\u00a0/g, " ").replace(/\s+/g, " ").trim();
  }

  function appendBlock(text) {
    const value = cleanInline(text);
    if (!value) return;
    if (blocks.length > 0 && blocks[blocks.length - 1] !== "") blocks.push("");
    blocks.push(value);
  }

  function appendLine(text) {
    const value = cleanInline(text);
    if (!value) return;
    blocks.push(value);
  }

  function walk(node) {
    node.childNodes.forEach((child) => {
      if (child.nodeType === Node.TEXT_NODE) {
        appendLine(child.textContent);
        return;
      }

      if (child.nodeType !== Node.ELEMENT_NODE) return;

      const tag = child.tagName.toLowerCase();

      if (tag === "br") {
        blocks.push("");
        return;
      }

      if (/^h[1-6]$/.test(tag)) {
        appendBlock(child.textContent);
        return;
      }

      if (tag === "p" || tag === "div" || tag === "section" || tag === "article") {
        appendBlock(child.textContent);
        return;
      }

      if (tag === "li") {
        appendLine(`• ${child.textContent}`);
        return;
      }

      if (tag === "ul" || tag === "ol") {
        if (blocks.length > 0 && blocks[blocks.length - 1] !== "") blocks.push("");
        walk(child);
        blocks.push("");
        return;
      }

      walk(child);
    });
  }

  walk(root);

  const rendered = blocks
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+\n/g, "\n")
    .trim();

  if (rendered) return rendered;

  return cleanInline(root.textContent || source.replace(/<[^>]+>/g, " "));
}

function plainDescription(text) {
  let value = String(text);

  if (ENTITY_PATTERN.test(value)) {
    value = decodeHtmlEntities(value);
  }

  return value
    .replace(/\u00a0/g, " ")
    .replace(/\r\n/g, "\n")
    .replace(/[^\S\n]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function normalizeDescription(text) {
  if (!text) return "";
  const trimmed = String(text).trim();

  if (looksLikeHtml(trimmed) || ENTITY_PATTERN.test(trimmed)) {
    return htmlToPlain(trimmed);
  }

  return plainDescription(trimmed);
}
