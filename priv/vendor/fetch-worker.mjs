// Worker script - reads URL from stdin, fetches, writes base64 to stdout
import process from "node:process";
import { Buffer } from "node:buffer";

let data = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', async () => {
  try {
    const response = await fetch(data.trim());
    if (!response.ok) {
      process.stdout.write(JSON.stringify({ error: `HTTP ${response.status}` }));
      return;
    }
    const buffer = await response.arrayBuffer();
    process.stdout.write(JSON.stringify({ data: Buffer.from(buffer).toString('base64') }));
  } catch (e) {
    process.stdout.write(JSON.stringify({ error: e.message }));
  }
});
