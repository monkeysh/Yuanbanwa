'use strict';

module.exports = {
  apps: [{
    name: 'speak-soe',
    cwd: '/www/wwwroot/speak-soe',
    script: './server.js',
    exec_mode: 'fork',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '192M',
    restart_delay: 2000,
    kill_timeout: 9000,
    listen_timeout: 5000,
    time: true,
    env: {
      NODE_ENV: 'production'
    }
  }]
};
