// Minimal synchronous React stand-in for unit tests: hooks, keyed children, refs and effects.
// It renders website components into plain host nodes that tests can inspect and drive,
// without a DOM. Behaviour mirrors React where these components depend on it.
export const Fragment = Symbol.for('esemnbun.test.fragment');

let rendering = null;
let active = null;
let latest = null;
let ids = 0;

export function jsx(type, props, key) {
  return {$$element: true, type, props: props || {}, key: key ?? null};
}
export const jsxs = jsx;

export function createElement(type, config, ...children) {
  const {key = null, ...props} = config || {};
  if (children.length) props.children = children.length === 1 ? children[0] : children;
  return jsx(type, props, key);
}

function slot(create) {
  if (!rendering) throw new Error('Hooks can only be called while a component renders');
  const index = rendering.cursor++;
  if (!(index in rendering.hooks)) rendering.hooks[index] = create();
  return [rendering.hooks[index], rendering];
}

const same = (previous, next) => previous && next && previous.length === next.length &&
  previous.every((value, index) => Object.is(value, next[index]));

export function useState(initial) {
  const [state, owner] = slot(() => ({value: typeof initial === 'function' ? initial() : initial}));
  state.set ||= next => {
    const value = typeof next === 'function' ? next(state.value) : next;
    if (Object.is(value, state.value) || owner.unmounted) return;
    state.value = value;
    owner.root.schedule();
  };
  return [state.value, state.set];
}

export function useRef(current = null) {
  return slot(() => ({current}))[0];
}

export function useId() {
  return slot(() => `:r${++ids}:`)[0];
}

export function useMemo(factory, deps) {
  const [memo] = slot(() => ({}));
  if (!same(memo.deps, deps)) {
    memo.value = factory();
    memo.deps = deps;
  }
  return memo.value;
}

export const useCallback = (callback, deps) => useMemo(() => callback, deps);

export function useEffect(effect, deps) {
  const [state, owner] = slot(() => ({}));
  if (!deps || !same(state.deps, deps)) {
    state.next = effect;
    state.nextDeps = deps;
    owner.pending.push(state);
  }
}
export const useLayoutEffect = useEffect;

/** The root committing now, or the last one rendered, for browser fakes that resolve elements by id. */
export const activeRoot = () => active || latest;

class Root {
  constructor(element, options) {
    Object.assign(this, {element, options, instances: new Map(), elements: new Map(), parents: new Map(),
      effects: [], busy: false, dirty: false, renders: 0, tree: []});
  }

  schedule() {
    this.dirty = true;
    if (!this.busy) this.flush();
  }

  flush() {
    let passes = 0;
    do {
      if (++passes > 100) throw new Error('Component updates did not settle');
      this.dirty = false;
      this.busy = true;
      const previous = active;
      active = latest = this;
      try {
        this.commit();
      } finally {
        this.busy = false;
        active = previous;
      }
    } while (this.dirty);
  }

  commit() {
    const seen = new Set();
    this.effects = [];
    this.tree = this.expand(this.element, 'root', seen);
    this.renders++;
    for (const [id, instance] of this.instances) {
      if (!seen.has(id)) this.release(id, instance);
    }
    this.parents.clear();
    this.link(this.tree, null);
    for (const effect of this.effects) {
      effect.cleanup?.();
      effect.deps = effect.nextDeps;
      const cleanup = effect.next();
      effect.cleanup = typeof cleanup === 'function' ? cleanup : null;
    }
  }

  release(id, instance) {
    instance.unmounted = true;
    for (const hook of instance.hooks) hook?.cleanup?.();
    this.instances.delete(id);
  }

  expand(node, path, seen) {
    if (node === null || node === undefined || typeof node === 'boolean') return [];
    if (['string', 'number', 'bigint'].includes(typeof node)) return [String(node)];
    if (Array.isArray(node)) return node.flatMap((child, index) => this.expand(child, `${path}[${child?.key ?? index}]`, seen));
    if (!node.$$element) throw new TypeError(`Unsupported child at ${path}`);
    const {type, props} = node;
    if (type === Fragment) return this.expand(props.children, path, seen);
    if (typeof type === 'function') {
      const id = `${path}<${type.name || 'Anonymous'}>`;
      seen.add(id);
      let instance = this.instances.get(id);
      if (!instance) this.instances.set(id, instance = {hooks: [], root: this});
      instance.cursor = 0;
      instance.pending = [];
      const previous = rendering;
      rendering = instance;
      let output;
      try {
        output = type(props);
      } finally {
        rendering = previous;
      }
      const children = this.expand(output, id, seen);
      this.effects.push(...instance.pending);
      return children;
    }
    const {children, ...attributes} = props;
    return [{type, props: attributes, key: node.key, path, children: this.expand(children, `${path}/${type}`, seen)}];
  }

  link(nodes, parent) {
    for (const node of nodes) {
      if (typeof node === 'string') continue;
      this.parents.set(node.path, parent);
      const ref = node.props.ref;
      if (ref) {
        const element = this.elementFor(node);
        if (typeof ref === 'function') ref(element);
        else ref.current = element;
      }
      this.link(node.children, node);
    }
  }

  elementFor(node) {
    let element = this.elements.get(node.path);
    if (!element) {
      element = new FakeElement(this, node.path);
      this.elements.set(node.path, element);
      this.options.decorate?.(element, node);
    }
    element.node = node;
    return element;
  }

  hosts(nodes = this.tree) {
    return nodes.flatMap(node => typeof node === 'string' ? [] : [node, ...this.hosts(node.children)]);
  }

  findAll(match) {
    const predicate = typeof match === 'string' ? node => node.type === match : match;
    return this.hosts().filter(predicate);
  }

  find(match) {
    const node = this.findAll(match)[0];
    if (!node) throw new Error('No rendered node matches');
    return node;
  }

  byText(text, type) {
    return this.find(node => (!type || node.type === type) && textOf(node).includes(text));
  }

  byId(id) {
    return this.findAll(node => node.props.id === id)[0];
  }

  text() {
    return this.tree.map(textOf).join('');
  }

  /** Invoke a host event handler the way React would, then settle state updates. */
  fire(node, handler, event = {}) {
    const element = this.elementFor(node);
    const result = node.props[handler]({currentTarget: element, target: element, preventDefault() {
      this.defaultPrevented = true;
    }, ...event});
    if (this.dirty) this.flush();
    return result;
  }

  rerender(element) {
    this.element = element;
    this.flush();
  }

  unmount() {
    for (const [id, instance] of this.instances) this.release(id, instance);
    this.tree = [];
  }
}

export const textOf = node => typeof node === 'string' ? node : node.children.map(textOf).join('');

// Selector subset used by the components: tag/.class/#id compounds with descendant and child combinators.
function compound(node, selector) {
  const classes = String(node.props.className || '').split(/\s+/);
  const tag = selector.match(/^[a-z][\w-]*/i)?.[0];
  return (!tag || node.type === tag) &&
    [...selector.matchAll(/\.([\w-]+)/g)].every(([, name]) => classes.includes(name)) &&
    [...selector.matchAll(/#([\w-]+)/g)].every(([, id]) => node.props.id === id);
}

function complex(root, node, tokens) {
  if (!node || !compound(node, tokens.at(-1))) return false;
  if (tokens.length === 1) return true;
  const child = tokens.at(-2) === '>';
  const rest = tokens.slice(0, child ? -2 : -1);
  for (let parent = root.parents.get(node.path); parent; parent = root.parents.get(parent.path)) {
    if (complex(root, parent, rest)) return true;
    if (child) return false;
  }
  return false;
}

const matches = (root, node, selector) => selector.split(',').some(part =>
  complex(root, node, part.trim().split(/\s*(>)\s*|\s+/).filter(Boolean)));

export class FakeElement {
  constructor(root, path) {
    Object.assign(this, {root, path, listeners: new Map(), calls: [], rect: {top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0}});
    const properties = {};
    this.style = {properties, setProperty: (name, value) => {
      properties[name] = value;
    }};
    const names = new Set();
    this.classList = {names, add: name => names.add(name), remove: name => names.delete(name),
      toggle: (name, force) => (force ?? !names.has(name)) ? names.add(name) : names.delete(name),
      contains: name => names.has(name)};
  }

  get id() {
    return this.node.props.id;
  }

  get parentElement() {
    const parent = this.root.parents.get(this.path);
    return parent ? this.root.elementFor(parent) : null;
  }

  get children() {
    return this.node.children.filter(child => typeof child !== 'string').map(child => this.root.elementFor(child));
  }

  get firstElementChild() {
    return this.children[0] || null;
  }

  getBoundingClientRect() {
    return {...this.rect};
  }

  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set());
    this.listeners.get(type).add(listener);
  }

  removeEventListener(type, listener) {
    this.listeners.get(type)?.delete(listener);
  }

  dispatch(type, event = {}) {
    for (const listener of [...(this.listeners.get(type) || [])]) listener({type, target: this, ...event});
    if (this.root.dirty) this.root.flush();
  }

  contains(other) {
    for (let element = other; element; element = element.parentElement) if (element === this) return true;
    return false;
  }

  matches(selector) {
    return matches(this.root, this.node, selector);
  }

  querySelectorAll(selector) {
    return this.root.hosts(this.node.children).filter(node => matches(this.root, node, selector)).map(node => this.root.elementFor(node));
  }

  querySelector(selector) {
    return this.querySelectorAll(selector)[0] || null;
  }

  animate(keyframes, options) {
    const animation = {keyframes, options, cancelled: false, cancel() {
      this.cancelled = true;
    }};
    this.calls.push(['animate', animation]);
    return animation;
  }

  focus(options) {
    this.calls.push(['focus', options]);
    if (globalThis.document) globalThis.document.activeElement = this;
  }
}
for (const name of ['scrollIntoView', 'showModal', 'close', 'click']) {
  FakeElement.prototype[name] = function (...args) {
    this.calls.push([name, ...args]);
  };
}

export function render(element, options = {}) {
  const root = new Root(element, options);
  root.flush();
  return root;
}

const React = {Fragment, createElement, useState, useRef, useId, useMemo, useCallback, useEffect, useLayoutEffect};
export default React;
