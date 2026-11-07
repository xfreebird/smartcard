import {useEffect, useRef} from 'react';

// Progressive enhancement: server-rendered content is always visible. Only an
// element entering the viewport gets a short, one-time animation.
export default function useScrollReveal() {
 const root = useRef(null);
 useEffect(() => {
  const container = root.current;
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  if (!container || !window.IntersectionObserver || !Element.prototype.animate) return;
  const animations = new Map();
  const seen = new WeakSet();
  const targets = container.querySelectorAll(
   '.features > h2, .feature-intro, .feature-grid article, .trust-section > *, .final-cta > *'
  );
  const observer = new IntersectionObserver(entries => {
   for (const {target, isIntersecting} of entries) {
    if (!isIntersecting) continue;
    observer.unobserve(target);
    if (seen.has(target)) continue;
    seen.add(target);
    if (motion.matches || target.contains(document.activeElement)) continue;
    const index = target.matches('.feature-grid article')
     ? [...target.parentElement.children].indexOf(target) : 0;
    const animation = target.animate([
     {opacity: .25, transform: 'translateY(18px)'},
     {opacity: 1, transform: 'translateY(0)'}
    ], {duration: 620, delay: index * 70, easing: 'cubic-bezier(.22, 1, .36, 1)', fill: 'backwards'});
    animations.set(target, animation);
    animation.onfinish = () => animations.delete(target);
   }
  }, {threshold: .08});
  const cancelAnimations = () => {
   for (const animation of animations.values()) animation.cancel();
   animations.clear();
  };
  const configure = () => {
   observer.disconnect();
   cancelAnimations();
   if (!motion.matches) for (const target of targets) {
    if (!seen.has(target)) observer.observe(target);
   }
  };
  // Keyboard navigation must never wait for an entrance animation.
  const focus = event => {
   for (const [target, animation] of animations) {
    if (target.contains(event.target)) {
     animation.cancel();
     animations.delete(target);
    }
   }
  };
  configure();
  motion.addEventListener('change', configure);
  container.addEventListener('focusin', focus);
  return () => {
   observer.disconnect();
   cancelAnimations();
   motion.removeEventListener('change', configure);
   container.removeEventListener('focusin', focus);
  };
 }, []);
 return root;
}
