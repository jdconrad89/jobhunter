import React from 'react';
import { createRoot } from 'react-dom/client';
import JobPosts from '../components/JobPosts.jsx';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('job-posts-root');
  if (container) {
    const root = createRoot(container);
    root.render(<JobPosts />);
  }
}); 