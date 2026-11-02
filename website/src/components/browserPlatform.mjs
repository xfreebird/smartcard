export const downloadPlatforms = ['ios', 'android', 'windows', 'macos', 'linux'];

// Keep the platform choice separate from the visual viewport. An iPad that
// requests the desktop site must still receive the App Store path.
export function browserPlatform(userAgent = '', maxTouchPoints = 0) {
  if (/iPad|iPhone|iPod/i.test(userAgent) || (/Macintosh/i.test(userAgent) && maxTouchPoints > 1)) return 'ios';
  if (/Android/i.test(userAgent)) return 'android';
  if (/Windows/i.test(userAgent)) return 'windows';
  if (/Macintosh|Mac OS X/i.test(userAgent)) return 'macos';
  if (/Linux/i.test(userAgent)) return 'linux';
  return 'other';
}
