import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';

function element() {
  const node = { children: [] };
  const builder = new Proxy(node, { get(target, name) {
    if (name === '_node') return target;
    if (name === 'id') return id => { target.id = id; return builder; };
    if (name === 'child') return child => { target.children.push(child); return builder; };
    if (name === 'children') return children => { target.children.push(...children); return builder; };
    if (name === 'when') return (condition, callback) => { if (condition) callback(builder); return builder; };
    if (name === 'on_click') return callback => { target.click = callback; return builder; };
    return () => builder;
  } });
  return builder;
}
function find(item, id) {
  if (!item || typeof item !== 'object') return null;
  const node = item._node;
  if (node.id === id) return node;
  for (const child of node.children) { const result = find(child, id); if (result) return result; }
  return null;
}
const root = new URL('../', import.meta.url);
for (const [name, module, className, button] of [['herdr-compact', 'review-tabs', 'Tabs', 'panel-jira'], ['t3-threads', 't3-threads', 'Threads', 'show-jira']]) {
  const tree = JSON.parse(await readFile(new URL(`layouts/${name}.json`, root), 'utf8'));
  const lookup = (node, id) => node.id === id ? node : (node.children || []).map(child => lookup(child, id)).find(Boolean);
  const panel = lookup(tree, 'panel'), body = lookup(tree, 'panel-body');
  const events = [];
  const source = await readFile(new URL(`mods/${module}/main.js`, root), 'utf8');
  const Renderer = runInNewContext(source.replace(/^import .*;\n/gm, '').replace(`export default class ${className}`, `class ${className}`) + `\n${className};`, {
    View: class {}, div: element, h_flex: element, v_flex: element, svg: element, image: element,
    theme: () => ({}), layout: () => tree, shared: () => ['files', 'changes'], props: () => ({ part: 'head' }),
    localStorage: { getItem: () => null, setItem() {} },
    spaces: () => [], panes: () => [], focused: () => null, window: () => ({ platform: 'linux', buttons: false }),
    run: (name, args) => events.push({ name, args }), Date,
  });
  const renderer = new Renderer();
  renderer.init();
  renderer.groups = () => [];
  const click = () => {
    const control = find(renderer.render(), button);
    assert.ok(control, `${name}: Jira stays available alongside existing Files/Changes preferences`);
    control.click({}, { stop_propagation() {} });
  };
  click();
  assert.deepEqual(JSON.parse(JSON.stringify(events)), [
    { name: 'layout.select', args: { stack: 'panel-body', child: 'jira' } },
    { name: 'layout.show', args: { id: 'panel' } },
  ]);
  events.length = 0;
  panel.hidden = false;
  body.active = 'jira';
  click();
  assert.deepEqual(JSON.parse(JSON.stringify(events)), [{ name: 'layout.hide', args: { id: 'panel' } }]);
  await readFile(new URL('mods/jira-tickets/ticket.svg', root));
}
console.log('PASS: both layout Jira buttons select/show the right sidebar, hide it on a second click, and remain available with existing panel preferences');
