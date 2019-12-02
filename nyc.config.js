'use strict'

module.exports = {
  noCompact: true,
  checkCoverage: true,
  extension: [
    '.mjs',
  ],
  reporter: [
    'lcov',
    'html',
    'text-summary',
  ],
  excludeNodeModules: true,
  exclude: [
    'coverage',
    '.nyc_output',
    '.*',
  ],
}
