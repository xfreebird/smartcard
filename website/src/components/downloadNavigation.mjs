// Use the reading area below sticky navigation, rather than a percentage of a
// card's height: a long Linux card can fill the screen but have a tiny ratio.
export function focusedDownloadPlatform(sections, {top, bottom, currentId}) {
 if (bottom <= top) return currentId;
 const visible = sections.filter(section => section.bottom > top && section.top < bottom);
 if (!visible.length) return currentId;
 const focus = top + (bottom - top) * 0.35;
 const distance = section => Math.max(section.top - focus, focus - section.bottom, 0);
 const nearest = Math.min(...visible.map(distance));
 const candidates = visible.filter(section => distance(section) <= nearest + 1);
 // Desktop cards share rows. Preserve the chosen column while both are in view.
 return (candidates.find(section => section.id === currentId) || candidates[0]).id;
}

export function downloadPlatformFromHash(hash, platformIds) {
 const value = hash.replace(/^#/, '');
 const id = value === 'linux-cli' ? 'linux' : value === 'cli' ? 'macos' : value;
 return platformIds.includes(id) ? id : null;
}
