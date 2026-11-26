// Deterministic browser globals for component effects: window, document, observers and frames.
import {activeRoot} from './react.mjs';

class Target {
  listeners = new Map();
  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set());
    this.listeners.get(type).add(listener);
  }
  removeEventListener(type, listener) {
    this.listeners.get(type)?.delete(listener);
  }
  dispatch(type, event = {}) {
    for (const listener of [...(this.listeners.get(type) || [])]) listener({type, ...event});
    const root = activeRoot();
    if (root?.dirty && !root.busy) root.flush();
  }
  count(type) {
    return this.listeners.get(type)?.size || 0;
  }
}

class Observer {
  static instances = [];
  constructor(callback, options) {
    Object.assign(this, {callback, options, observed: new Set(), disconnected: 0});
    this.constructor.instances.push(this);
  }
  observe(target) {
    this.observed.add(target);
  }
  unobserve(target) {
    this.observed.delete(target);
  }
  disconnect() {
    this.disconnected++;
    this.observed.clear();
  }
  trigger(entries = []) {
    this.callback(entries, this);
  }
}

const globalNames = ['window', 'document', 'navigator', 'IntersectionObserver', 'ResizeObserver', 'Element', 'Image',
  'sessionStorage', 'requestAnimationFrame', 'cancelAnimationFrame'];

/** Install fake browser globals; returns the fakes and a restore function. */
export function installBrowser({width = 1440, height = 960, hostname = 'esemnbun.md', hash = '', userAgent = 'Mozilla/5.0 (Macintosh)',
  maxTouchPoints = 0, media = {}, storage = new Map(), images = () => Promise.resolve(), clipboard} = {}) {
  const saved = globalNames.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]);
  const frames = new Map();
  let nextFrame = 0;
  const queries = new Map();
  const window = Object.assign(new Target(), {
    innerWidth: width, innerHeight: height,
    location: {hash, hostname, replaced: [], replace(url) {
      this.replaced.push(url);
    }},
    history: {state: {kept: true}, entries: [], replaceState(state, title, url) {
      this.entries.push(['replace', url]); window.location.hash = url;
    }, pushState(state, title, url) {
      this.entries.push(['push', url]); window.location.hash = url;
    }},
    visualViewport: Object.assign(new Target(), {offsetTop: 0, height}),
    matchMedia(query) {
      if (!queries.has(query)) queries.set(query, Object.assign(new Target(), {media: query, matches: Boolean(media[query])}));
      return queries.get(query);
    },
    requestAnimationFrame(callback) {
      frames.set(++nextFrame, callback);
      return nextFrame;
    },
    cancelAnimationFrame(id) {
      frames.delete(id);
    },
  });
  const created = [];
  const document = Object.assign(new Target(), {
    activeElement: null,
    documentElement: {classList: new Set()},
    getElementById: id => {
      const root = activeRoot();
      const node = root?.byId(id);
      return node ? root.elementFor(node) : null;
    },
    createElement(tag) {
      const element = {tag, clicked: 0, click() {
        this.clicked++;
      }};
      created.push(element);
      return element;
    },
  });
  document.documentElement.classList.toggle = function (name, force) {
    if (force ?? !this.has(name)) this.add(name); else this.delete(name);
  };
  document.documentElement.classList.remove = function (name) {
    this.delete(name);
  };
  class IntersectionObserver extends Observer {
    static instances = [];
  }
  class ResizeObserver extends Observer {
    static instances = [];
  }
  class Image {
    static sources = [];
    set src(value) {
      Image.sources.push(value);
      this.source = value;
    }
    decode() {
      return images(this.source);
    }
  }
  Object.assign(window, {IntersectionObserver, ResizeObserver});
  const values = {
    window, document, IntersectionObserver, ResizeObserver, Image,
    navigator: {userAgent, maxTouchPoints, clipboard},
    Element: Object.assign(function Element() {}, {prototype: {animate() {}}}),
    sessionStorage: {getItem: key => storage.has(key) ? storage.get(key) : null, setItem: (key, value) => storage.set(key, value)},
    requestAnimationFrame: window.requestAnimationFrame, cancelAnimationFrame: window.cancelAnimationFrame,
  };
  for (const [name, value] of Object.entries(values)) {
    Object.defineProperty(globalThis, name, {value, configurable: true, writable: true});
  }
  const installed = {
    window, document, created, frames, IntersectionObserver, ResizeObserver, Image, values,
    media: query => window.matchMedia(query),
    /** Run queued animation frames at the given timestamp. */
    runFrames(time = 16) {
      const pending = [...frames.entries()];
      frames.clear();
      for (const [, callback] of pending) callback(time);
      const root = activeRoot();
      if (root?.dirty && !root.busy) root.flush();
      return pending.length;
    },
    restore() {
      for (const [name, descriptor] of saved) {
        if (descriptor) Object.defineProperty(globalThis, name, descriptor);
        else delete globalThis[name];
      }
    },
  };
  return installed;
}
