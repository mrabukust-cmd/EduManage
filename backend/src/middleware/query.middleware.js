/**
 * Middleware & helper utilities for search filtering, pagination, and sorting.
 */

function parseQueryParams(req, res, next) {
  const page = parseInt(req.query.page, 10) || null;
  const limit = parseInt(req.query.limit, 10) || null;
  const search = req.query.search ? req.query.search.trim() : null;
  const sortBy = req.query.sortBy || null;
  const sortOrder = (req.query.sortOrder || 'asc').toLowerCase() === 'desc' ? -1 : 1;

  req.queryOptions = {
    page,
    limit,
    search,
    sortBy,
    sortOrder,
  };
  next();
}

function applyFilterAndPagination(items, query = {}, searchFields = []) {
  let filtered = [...items];

  // Search filter across specified fields
  if (query.search && searchFields.length > 0) {
    const q = query.search.trim().toLowerCase();
    filtered = filtered.filter((item) =>
      searchFields.some((field) => {
        const val = item[field];
        return val != null && String(val).toLowerCase().includes(q);
      })
    );
  }

  // Sorting
  if (query.sortBy) {
    const field = query.sortBy;
    const order = (query.sortOrder || 'asc').toLowerCase() === 'desc' ? -1 : 1;
    filtered.sort((a, b) => {
      const valA = a[field] ?? '';
      const valB = b[field] ?? '';
      if (typeof valA === 'string' && typeof valB === 'string') {
        return order * valA.localeCompare(valB);
      }
      return order * (valA > valB ? 1 : valA < valB ? -1 : 0);
    });
  }

  const total = filtered.length;
  const page = parseInt(query.page, 10) || null;
  const limit = parseInt(query.limit, 10) || null;

  if (page && limit) {
    const startIndex = (page - 1) * limit;
    const paginatedItems = filtered.slice(startIndex, startIndex + limit);
    return {
      items: paginatedItems,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 1,
      },
    };
  }

  return {
    items: filtered,
    pagination: {
      total,
      page: 1,
      limit: total,
      totalPages: 1,
    },
  };
}

module.exports = {
  parseQueryParams,
  applyFilterAndPagination,
};
