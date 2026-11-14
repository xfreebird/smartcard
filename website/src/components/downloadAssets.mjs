// Keep one download per package/architecture, with desktop apps before CLI.
export function isCLI(asset) {
 return asset.platform === 'linux-cli' || asset.name.startsWith('esemnbun-cli-') ||
  (asset.platform === 'macos' && asset.format === 'TAR.GZ');
}
export function platformAssets(assets, platform) {
 const seen = new Set();
 return assets.filter(asset => (asset.platform === 'linux-cli' ? 'linux' : asset.platform) === platform)
  .filter(asset => {
   const key = [isCLI(asset) ? 'cli' : 'app', asset.format, asset.architecture || ''].join(':');
   if (seen.has(key)) return false;
   seen.add(key); return true;
  }).sort((a, b) => Number(isCLI(a)) - Number(isCLI(b)));
}
