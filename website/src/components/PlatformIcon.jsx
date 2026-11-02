import React from 'react';

// Local vectors keep platform choices clear without loading an icon font.
export default function PlatformIcon({name, className = ''}) {
 const paths = {
  macos: <path d="M16.8 12.8c0-2 1.6-3 1.7-3.1-1-1.4-2.4-1.6-3-1.6-1.3-.1-2.5.8-3.2.8-.7 0-1.8-.8-2.9-.8-1.5 0-2.9.9-3.7 2.2-1.6 2.7-.4 6.8 1.1 9 .7 1.1 1.6 2.2 2.7 2.2 1.1-.1 1.5-.7 2.9-.7s1.8.7 2.9.7c1.2 0 1.9-1.1 2.6-2.1.9-1.3 1.2-2.6 1.3-2.7-.1 0-2.4-.9-2.4-3.9ZM14.7 6.5c.6-.8 1.1-1.9 1-3-.9 0-2 .6-2.7 1.4-.6.7-1.2 1.9-1 3 1 .1 2.1-.5 2.7-1.4Z" fill="currentColor" stroke="none"/>,
  windows: <g fill="currentColor" stroke="none"><path d="M3 4h8v8H3zM13 4h8v8h-8zM3 14h8v8H3zM13 14h8v8h-8z"/></g>,
  linux: <><rect x="3" y="3" width="18" height="13" rx="2"/><path d="M8 21h8m-4-5v5"/></>,
  cli: <><rect x="3" y="4" width="18" height="16" rx="3"/><path d="m7 9 3 3-3 3m6 0h4"/></>,
  ios: <><rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 5h4m-3 14h2"/></>,
  android: <><path d="m7 7-2-3m12 3 2-3M4 13a8 8 0 0 1 16 0v4H4Z"/><path d="M7 20v-3m10 3v-3"/><circle cx="8.5" cy="12" r=".8" fill="currentColor" stroke="none"/><circle cx="15.5" cy="12" r=".8" fill="currentColor" stroke="none"/></>,
  download: <><path d="M12 3v12m-5-5 5 5 5-5M4 16v4a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-4"/></>,
  chevron: <path d="m7 10 5 5 5-5"/>,
  external: <><path d="M14 3h7v7m0-7L10 14M10 4H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h13a2 2 0 0 0 2-2v-5"/></>,
  github: <path d="M9 21v-4c-4 1-4-2-6-2m12 6v-4c0-1 .3-2 1-2 3-.3 5-1.5 5-5a4 4 0 0 0-1-3c.3-1 .3-2-.1-3-1 0-2 .5-3 1a12 12 0 0 0-8 0c-1-.5-2-1-3-1-.4 1-.4 2-.1 3a4 4 0 0 0-1 3c0 3.5 2 4.7 5 5"/>,
 };
 return <svg className={`platform-icon ${className}`} width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] || paths.download}</svg>;
}
