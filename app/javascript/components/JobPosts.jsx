import React, { useState, useEffect } from 'react';

const JobPosts = () => {
  const [jobPosts, setJobPosts] = useState([]);
  const [filteredPosts, setFilteredPosts] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState({
    remote: 'all',
    location: 'all',
    company: 'all'
  });

  useEffect(() => {
    fetchJobPosts();
  }, []);

  useEffect(() => {
    filterPosts();
  }, [jobPosts, searchTerm, filters]);

  const fetchJobPosts = async () => {
    try {
      const response = await fetch('/api/job_posts');
      const data = await response.json();
      setJobPosts(data);
      setFilteredPosts(data);
    } catch (error) {
      console.error('Error fetching job posts:', error);
    }
  };

  const filterPosts = () => {
    let filtered = [...jobPosts];

    // Apply search term filter
    if (searchTerm) {
      filtered = filtered.filter(post => 
        post.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        post.company.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        post.description.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply remote filter
    if (filters.remote !== 'all') {
      filtered = filtered.filter(post => 
        filters.remote === 'true' ? post.remote : !post.remote
      );
    }

    // Apply location filter
    if (filters.location !== 'all') {
      filtered = filtered.filter(post => 
        post.location.toLowerCase().includes(filters.location.toLowerCase())
      );
    }

    // Apply company filter
    if (filters.company !== 'all') {
      filtered = filtered.filter(post => 
        post.company.name.toLowerCase().includes(filters.company.toLowerCase())
      );
    }

    setFilteredPosts(filtered);
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
  };

  const handleFilterChange = (e) => {
    setFilters({
      ...filters,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Job Posts</h1>
      
      {/* Search and Filters */}
      <div className="mb-8 space-y-4">
        <div className="flex gap-4">
          <input
            type="text"
            placeholder="Search jobs..."
            value={searchTerm}
            onChange={handleSearchChange}
            className="flex-1 p-2 border rounded"
          />
          <select
            name="remote"
            value={filters.remote}
            onChange={handleFilterChange}
            className="p-2 border rounded"
          >
            <option value="all">All Work Types</option>
            <option value="true">Remote</option>
            <option value="false">On-site</option>
          </select>
          <select
            name="location"
            value={filters.location}
            onChange={handleFilterChange}
            className="p-2 border rounded"
          >
            <option value="all">All Locations</option>
            <option value="san francisco">San Francisco</option>
            <option value="new york">New York</option>
            <option value="london">London</option>
          </select>
        </div>
      </div>

      {/* Job Posts List */}
      <div className="space-y-6">
        {filteredPosts.map(post => (
          <div key={post.id} className="border rounded-lg p-6 hover:shadow-lg transition-shadow">
            <div className="flex justify-between items-start">
              <div>
                <h2 className="text-xl font-semibold mb-2">{post.title}</h2>
                <p className="text-gray-600 mb-2">{post.company.name}</p>
                <p className="text-gray-500 mb-4">{post.location}</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-sm ${
                post.remote ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800'
              }`}>
                {post.remote ? 'Remote' : 'On-site'}
              </span>
            </div>
            <p className="text-gray-700 mb-4">{post.description}</p>
            <div className="flex justify-between items-center">
              <a
                href={post.website}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-800"
              >
                View Job
              </a>
              <span className="text-gray-500">
                Posted {new Date(post.posted_at).toLocaleDateString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default JobPosts; 