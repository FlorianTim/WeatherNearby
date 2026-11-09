import { createApp } from './app.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const app = createApp();

app.listen(config.PORT, () => {
  // Log only non-sensitive startup info: no tokens, secrets, or user data.
  console.log(`Backend listening on http://localhost:${config.PORT}`);
});
