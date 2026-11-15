import {useCallback, useEffect, useRef, useState} from 'react';
import {downloadPlatformFromHash, focusedDownloadPlatform} from './downloadNavigation.mjs';

export default function useDownloadNavigation(platforms) {
 const navRef = useRef(null);
 const activeRef = useRef(platforms[0].id);
 const [selectedPlatform, setSelectedPlatform] = useState(activeRef.current);
 const selectPlatform = useCallback(id => {
  activeRef.current = id;
  setSelectedPlatform(id);
 }, []);
 const replaceHash = id => {
  if (window.location.hash !== `#${id}`) window.history.replaceState(window.history.state, '', `#${id}`);
 };

 useEffect(() => {
  const nav = navRef.current;
  const sections = platforms.map(({id}) => document.getElementById(id)).filter(Boolean);
  let frame = 0;
  let navHeight = 0;
  const measureNav = () => {
   const height = nav.getBoundingClientRect().height;
   if (height !== navHeight) {
    navHeight = height;
    nav.parentElement.style.setProperty('--download-platform-nav-height', `${height}px`);
   }
  };
  const update = () => {
   frame = 0;
   measureNav();
   const viewport = window.visualViewport;
   const viewportTop = viewport?.offsetTop || 0;
   const id = focusedDownloadPlatform(sections.map(section => {
    const {top, bottom} = section.getBoundingClientRect();
    return {id: section.id, top, bottom};
   }), {
    top: Math.max(viewportTop, nav.getBoundingClientRect().bottom),
    bottom: viewportTop + (viewport?.height || window.innerHeight),
    currentId: activeRef.current,
   });
   if (id !== activeRef.current) {
    selectPlatform(id);
    replaceHash(id); // Scrolling must not add entries or trigger anchor scrolling.
   }
  };
  const schedule = () => {
   if (!frame) frame = window.requestAnimationFrame(update);
  };
  const selectFromHash = () => {
   const id = downloadPlatformFromHash(window.location.hash, platforms.map(platform => platform.id));
   if (!id) return;
   selectPlatform(id);
   replaceHash(id);
   measureNav();
   document.getElementById(id)?.scrollIntoView({block: 'start', behavior: 'instant'});
  };
  measureNav();
  selectFromHash();
  schedule();
  const resize = new ResizeObserver(schedule);
  resize.observe(nav);
  sections.forEach(section => resize.observe(section));
  window.addEventListener('scroll', schedule, {passive: true});
  window.addEventListener('resize', schedule);
  window.addEventListener('hashchange', selectFromHash);
  window.addEventListener('pageshow', schedule);
  window.visualViewport?.addEventListener('resize', schedule);
  window.visualViewport?.addEventListener('scroll', schedule);
  return () => {
   window.cancelAnimationFrame(frame);
   resize.disconnect();
   window.removeEventListener('scroll', schedule);
   window.removeEventListener('resize', schedule);
   window.removeEventListener('hashchange', selectFromHash);
   window.removeEventListener('pageshow', schedule);
   window.visualViewport?.removeEventListener('resize', schedule);
   window.visualViewport?.removeEventListener('scroll', schedule);
  };
 }, [platforms, selectPlatform]);

 const selectCard = id => {
  selectPlatform(id);
  replaceHash(id);
 };
 const navigate = (event, id) => {
  if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  event.preventDefault();
  selectPlatform(id);
  if (window.location.hash !== `#${id}`) window.history.pushState(window.history.state, '', `#${id}`);
  // An immediate anchor jump keeps the selected item and its content together,
  // including reduced-motion users and platforms several screens away.
  const section = document.getElementById(id);
  section?.focus({preventScroll: true});
  section?.scrollIntoView({block: 'start', behavior: 'instant'});
 };
 return {navRef, selectedPlatform, selectCard, navigate};
}
