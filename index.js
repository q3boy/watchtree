if (require.extensions['.coffee']) {
  module.exports = require('./lib/watchtree.coffee');
} else {
  module.exports = require('./out/release/lib/watchtree.js');
}
