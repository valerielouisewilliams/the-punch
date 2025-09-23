// this file starts the server
const app = require('./src/app');

// get port from environment variables or use 3000 as default
const PORT = process.env.PORT || 3000;

// start the server
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🔍 Test it: http://localhost:${PORT}/health`);
});

// handle graceful shutdown (when you stop the server)
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down server...');
  server.close(() => {
    console.log('✅ Server stopped gracefully');
    process.exit(0);
  });
});