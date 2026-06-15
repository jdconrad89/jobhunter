# JobHunter Chrome Extension

Import job postings from any web page into your local JobHunter Rails app.

## Setup

1. Start JobHunter locally (`bin/rails server`).
2. Log in and open **API Token** in the nav.
3. Click **Generate Token** and copy the token.
4. In Chrome, open `chrome://extensions`.
5. Enable **Developer mode**.
6. Click **Load unpacked** and select this `chrome-extension/` folder.
7. Open the extension **Options** page and paste:
   - **Server URL**: `http://localhost:3000` (or your port)
   - **API token**: token from JobHunter

## Usage

1. Open a job posting in your browser.
2. Click the JobHunter extension icon — this opens the **side panel** (not a popup).
3. Review and edit the scraped fields. Your draft is **auto-saved** as you type.
4. Click **Save to JobHunter**.

The side panel stays open while you browse the job page, so you can copy details from the page without losing your work. If you switch tabs, the panel loads the saved draft for that URL.

### Side panel tips

- **Re-scrape page** — pull fresh data from the page into any empty fields (won't overwrite what you've already typed).
- **Clear draft** — reset the form for the current page.
- If scraping fails, refresh the job page once after installing or updating the extension.

## How scraping works

The extension layers several extractors and merges the best result:

| Layer | What it does |
|-------|----------------|
| **Site-specific** | Greenhouse (API + DOM), Ashby (API + DOM), Lever (API + DOM), LinkedIn, Indeed |
| **JSON-LD** | `JobPosting` schema used by many ATS sites |
| **Generic** | `h1`, Open Graph tags, job description containers, largest content block |

Remote is inferred from keywords in the title, location, and description.

On **Lever** (`jobs.lever.co/company/job-id`), **Greenhouse** (`job-boards.greenhouse.io/company/jobs/id`, or pages with `?gh_jid=`), and **Ashby** (`jobs.ashbyhq.com/company/job-id`), the extension uses each platform's public API for full job data, with DOM scraping as a fallback.

**LinkedIn** and **Indeed** rely on improved DOM selectors plus JSON-LD when available.

## Development notes

- API endpoint: `POST /api/job_posts`
- Auth header: `Authorization: Bearer <token>`
- Reload the extension on `chrome://extensions` after code changes
- Add new site extractors under `content/extractors/` and register them in `content/content.js`
