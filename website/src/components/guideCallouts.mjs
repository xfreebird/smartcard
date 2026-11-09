/** Keep numbered labels outside the screenshot, with stable target coordinates. */
export function layoutGuideCallouts(steps, frame, image, start = 1) {
  const gap = 32;
  const inset = 18;
  const callouts = steps.flatMap((step, index) => {
    if (!Number.isFinite(step.x) || !Number.isFinite(step.y)) return [];
    const side = step.x <= 50 ? 'left' : 'right';
    // End pointers in the gutter: no line, dot or badge may cover app pixels.
    const targetX = side === 'left' ? image.x - 5 : image.x + image.width + 5;
    const targetY = image.y + image.height * step.y / 100;
    return [{number: index + start, side, targetX, targetY,
      x: side === 'left' ? inset : frame.width - inset, y: targetY}];
  });
  for (const side of ['left', 'right']) {
    const labels = callouts.filter(item => item.side === side).sort((a, b) => a.targetY - b.targetY);
    for (let index = 0; index < labels.length; index++) {
      labels[index].y = Math.max(inset, labels[index].targetY,
        index ? labels[index - 1].y + gap : inset);
    }
    for (let index = labels.length - 1; index >= 0; index--) {
      labels[index].y = Math.min(labels[index].y,
        index === labels.length - 1 ? frame.height - inset : labels[index + 1].y - gap);
    }
  }
  return callouts;
}
