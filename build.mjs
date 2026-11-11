import { mkdir, copyFile, cp } from 'node:fs/promises';
await mkdir('dist/realtime', {recursive: true});
for (const path of ['index.html','realtime/index.html','realtime/config.js']) {
  await copyFile(path, 'dist/' + path);
}
await cp('legacy', 'dist/legacy', {recursive: true});
await copyFile('node_modules/livekit-client/dist/livekit-client.umd.js', 'dist/livekit.js');
