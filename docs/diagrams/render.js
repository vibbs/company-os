#!/usr/bin/env node
// docs/diagrams/render.js
// Renders the Company OS SVG diagram set into .company-os/docs/diagrams/.
//
// Usage:
//   node docs/diagrams/render.js           # write all SVGs
//   node docs/diagrams/render.js --check   # exit 1 if any SVG on disk is stale
//
// Zero dependencies (Node 18+). Output is deterministic: running it twice
// produces byte-identical files. Counts (skills, agents, tools, artifact types)
// and each agent's skills are read from the repo at render time, so the
// diagrams cannot drift from os/ and tools/.

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT_DIR = path.join(ROOT, '.company-os', 'docs', 'diagrams');

// ═══════════════════════════════════════════════════════════════
// 1. Repo facts (read at render time)
// ═══════════════════════════════════════════════════════════════

function readRepoFacts() {
  const skillsDir = path.join(ROOT, 'os', 'skills');
  const skills = fs.readdirSync(skillsDir)
    .filter((d) => fs.existsSync(path.join(skillsDir, d, 'SKILL.md')))
    .sort();

  const agentsDir = path.join(ROOT, 'os', 'agents');
  const agents = {};
  for (const f of fs.readdirSync(agentsDir).filter((f) => f.endsWith('.md')).sort()) {
    const fm = parseFrontmatter(fs.readFileSync(path.join(agentsDir, f), 'utf8'));
    agents[fm.name] = fm;
  }

  // Exclude tools/build/ and tools/lib/ by repo-relative path, so a clone that
  // sits under any folder named build or lib still counts correctly.
  const toolsDir = path.join(ROOT, 'tools');
  const toolScripts = listFiles(toolsDir)
    .filter((p) => {
      const top = path.relative(toolsDir, p).split(path.sep)[0];
      return p.endsWith('.sh') && top !== 'build' && top !== 'lib';
    });
  const buildScripts = listFiles(path.join(ROOT, 'tools', 'build')).filter((p) => p.endsWith('.sh'));

  const validate = fs.readFileSync(path.join(ROOT, 'tools', 'artifact', 'validate.sh'), 'utf8');
  const typesLine = validate.match(/VALID_TYPES=\(([^)]*)\)/);
  const artifactTypes = typesLine ? typesLine[1].match(/"([^"]+)"/g).map((s) => s.slice(1, -1)) : [];

  return {
    skills,
    agents,
    toolCount: toolScripts.length,
    buildCount: buildScripts.length,
    artifactTypes,
  };
}

function listFiles(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...listFiles(p));
    else out.push(p);
  }
  return out.sort();
}

// Minimal YAML frontmatter reader: scalars and "- item" lists only.
function parseFrontmatter(src) {
  const m = src.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const out = {};
  let listKey = null;
  for (const line of m[1].split('\n')) {
    const item = line.match(/^\s+-\s+(.+)$/);
    if (item && listKey) { out[listKey].push(item[1].trim()); continue; }
    const kv = line.match(/^([A-Za-z_-]+):\s*(.*)$/);
    if (!kv) continue;
    if (kv[2] === '') { listKey = kv[1]; out[listKey] = []; } else { listKey = null; out[kv[1]] = kv[2].trim(); }
  }
  return out;
}

// ═══════════════════════════════════════════════════════════════
// 2. Theme (the one place colors, type, and spacing are defined)
// ═══════════════════════════════════════════════════════════════

const THEME = {
  font: "-apple-system, 'Segoe UI', Inter, Helvetica, Arial, sans-serif",
  mono: "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
  grid: 8,
  radius: 10,
  width: 960,
  margin: 40,
  light: {
    bg: '#f6f8fa', surface: '#ffffff', sunken: '#f6f8fa', border: '#d1d9e0', 'border-soft': '#e4e9ee',
    text: '#1f2328', 'text-2': '#4b5562', 'text-3': '#606a76', line: '#8c959f',
    shadow: '#1f2328', 'shadow-o': '0.07', solid: '#24292f', 'on-solid': '#ffffff',
  },
  dark: {
    bg: '#0d1117', surface: '#151b23', sunken: '#10151c', border: '#3d444d', 'border-soft': '#2a3038',
    text: '#e6edf3', 'text-2': '#b1bac4', 'text-3': '#9198a1', line: '#7d8590',
    shadow: '#000000', 'shadow-o': '0.35', solid: '#e6edf3', 'on-solid': '#0d1117',
  },
  // One accent per layer / agent family: [light ink, light tint, dark ink, dark tint]
  families: {
    orch:    ['#4f46e5', '#eef0ff', '#a5b4fc', 'rgba(129,140,248,0.16)'],
    product: ['#7c3aed', '#f4effe', '#c4b5fd', 'rgba(167,139,250,0.16)'],
    eng:     ['#0f766e', '#e6f5f3', '#5eead4', 'rgba(45,212,191,0.14)'],
    qa:      ['#0369a1', '#e8f4fb', '#7dd3fc', 'rgba(56,189,248,0.14)'],
    growth:  ['#be185d', '#fdf0f6', '#f9a8d4', 'rgba(244,114,182,0.14)'],
    ops:     ['#b42318', '#fdf1f0', '#fca5a5', 'rgba(248,113,113,0.14)'],
    gate:    ['#b45309', '#fef6e7', '#fbbf24', 'rgba(251,191,36,0.14)'],
    neutral: ['#4b5562', '#f1f3f5', '#b1bac4', 'rgba(177,186,196,0.12)'],
  },
};

// Text roles: size, weight, width factor (conservative em-per-char), mono?
const ROLES = {
  title: { size: 22, weight: 600, k: 0.58 },
  sub:   { size: 14, weight: 400, k: 0.55 },
  h:     { size: 14, weight: 600, k: 0.58 },
  hs:    { size: 13, weight: 600, k: 0.57 },
  body:  { size: 13, weight: 400, k: 0.56 },
  meta:  { size: 12, weight: 400, k: 0.56 },
  badge: { size: 12, weight: 500, k: 0.58 },
  label: { size: 12, weight: 600, k: 0.74, upper: true },
  code:  { size: 12, weight: 400, k: 0.62, mono: true },
  codes: { size: 11, weight: 400, k: 0.62, mono: true },
  codeh: { size: 13, weight: 600, k: 0.64, mono: true },
};

function textWidth(str, role) {
  const r = ROLES[role];
  return Math.ceil(str.length * r.size * r.k);
}

function css(id) {
  const vars = (o) => Object.entries(o).map(([k, v]) => `--${k}:${v}`).join(';');
  const fam = (dark) => Object.entries(THEME.families)
    .map(([k, c]) => `#${id} .f-${k}{--a:${dark ? c[2] : c[0]};--a-soft:${dark ? c[3] : c[1]}}`).join('');
  const roles = Object.entries(ROLES).map(([k, r]) =>
    `#${id} .r-${k}{font-size:${r.size}px;font-weight:${r.weight}${r.mono ? ';font-family:var(--mono)' : ''}${r.upper ? ';letter-spacing:0.04em' : ''}}`).join('');
  const darkBlock = `#${id}{${vars(THEME.dark)}}${fam(true)}`;
  return [
    `#${id}{${vars(THEME.light)};--mono:${THEME.mono}}`,
    fam(false),
    `@media (prefers-color-scheme: dark){${darkBlock}}`,
    `#${id} text{font-family:${THEME.font};fill:var(--text)}`,
    roles,
    `#${id} .r-sub,#${id} .r-body{fill:var(--text-2)}`,
    `#${id} .r-meta{fill:var(--text-3)}`,
    `#${id} .r-label,#${id} .c-a{fill:var(--a)}`,
    `#${id} .c-2{fill:var(--text-2)}#${id} .c-3{fill:var(--text-3)}#${id} .c-on{fill:var(--on-solid)}`,
    `#${id} .panel{fill:var(--bg);stroke:var(--border)}`,
    `#${id} .card{fill:var(--surface);stroke:var(--border)}`,
    `#${id} .sunken{fill:var(--sunken);stroke:var(--border-soft)}`,
    `#${id} .tint{fill:var(--a-soft);stroke:var(--a)}`,
    `#${id} .tint-soft{fill:var(--a-soft);stroke:none}`,
    `#${id} .bar{fill:var(--a)}`,
    `#${id} .chip{fill:var(--sunken);stroke:var(--border)}`,
    `#${id} .solid{fill:var(--solid);stroke:var(--solid)}`,
    `#${id} .fold{fill:var(--border-soft);stroke:var(--border)}`,
    `#${id} .rule{stroke:var(--border-soft);fill:none}`,
    `#${id} .edge{fill:none;stroke:var(--line);stroke-width:1.25}`,
    `#${id} .ah{fill:var(--line)}`,
    `#${id} .dashed{stroke-dasharray:5 4}`,
    `#${id} .dotted{stroke-dasharray:1.5 3;stroke-linecap:round}`,
    `#${id} .lbg{fill:var(--bg)}#${id} .lbg-card{fill:var(--surface)}`,
    `#${id} .shadow{flood-color:var(--shadow);flood-opacity:var(--shadow-o)}`,
    `#${id} .tick{fill:none;stroke:var(--a);stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round}`,
  ].join('\n');
}

// ═══════════════════════════════════════════════════════════════
// 3. Drawing primitives
// ═══════════════════════════════════════════════════════════════

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const n = (v) => (Math.round(v * 10) / 10).toString();

class Diagram {
  constructor({ name, height, title, subtitle, desc, width = THEME.width }) {
    this.name = name;
    this.id = `cos-${name}`;
    this.W = width;
    this.H = height;
    this.title = title;
    this.subtitle = subtitle;
    this.desc = desc;
    this.parts = [];
    this.header();
  }

  add(s) { this.parts.push(s); return this; }

  // Text with a hard overflow guard: throws when the string cannot fit maxW.
  text(x, y, str, { role = 'body', anchor = 'start', cls = '', maxW, transform } = {}) {
    const r = ROLES[role];
    const s = r.upper ? str.toUpperCase() : str;
    if (maxW !== undefined && textWidth(s, role) > maxW) {
      throw new Error(`[${this.name}] text overflow (${textWidth(s, role)} > ${maxW}px): "${s}"`);
    }
    const a = anchor === 'start' ? '' : ` text-anchor="${anchor}"`;
    const t = transform ? ` transform="${transform}"` : '';
    return this.add(`<text x="${n(x)}" y="${n(y)}" class="r-${role}${cls ? ' ' + cls : ''}"${a}${t}>${esc(s)}</text>`);
  }

  // Greedy word wrap; returns lines. Throws if a single word cannot fit.
  wrap(str, role, maxW) {
    const words = str.split(' ');
    const lines = [];
    let cur = '';
    for (const w of words) {
      const next = cur ? `${cur} ${w}` : w;
      if (textWidth(next, role) <= maxW) { cur = next; continue; }
      if (!cur) throw new Error(`[${this.name}] word too long for ${maxW}px: "${w}"`);
      lines.push(cur);
      cur = w;
    }
    if (cur) lines.push(cur);
    return lines;
  }

  // Draws wrapped text; returns the y after the last line.
  para(x, y, str, { role = 'body', maxW, lh = 18, cls = '' } = {}) {
    const lines = this.wrap(str, role, maxW);
    lines.forEach((l, i) => this.text(x, y + i * lh, l, { role, maxW, cls }));
    return y + (lines.length - 1) * lh;
  }

  rect(x, y, w, h, { cls = 'card', rx = THEME.radius, dash = '', shadow = false, fam = '' } = {}) {
    const f = shadow ? ` filter="url(#${this.id}-sh)"` : '';
    const d = dash ? ` ${dash}` : '';
    const g = fam ? ` f-${fam}` : '';
    return this.add(`<rect x="${n(x)}" y="${n(y)}" width="${n(w)}" height="${n(h)}" rx="${rx}" class="${cls}${d}${g}"${f}/>`);
  }

  // Card: rounded surface, 1px border, soft shadow, optional accent bar.
  card(x, y, w, h, { fam, dash = '', accent = true } = {}) {
    this.rect(x, y, w, h, { shadow: true, dash });
    if (fam && accent) this.add(`<rect x="${n(x + 8)}" y="${n(y + 12)}" width="3" height="${n(h - 24)}" rx="1.5" class="bar f-${fam}"/>`);
    return this;
  }

  // Artifact card: document shape with a folded top-right corner.
  docCard(x, y, w, h, { fam, dash = '' } = {}) {
    const r = THEME.radius;
    const c = 14;
    const d = `M${n(x + r)},${n(y)} H${n(x + w - c)} L${n(x + w)},${n(y + c)} V${n(y + h - r)} A${r},${r} 0 0 1 ${n(x + w - r)},${n(y + h)} H${n(x + r)} A${r},${r} 0 0 1 ${n(x)},${n(y + h - r)} V${n(y + r)} A${r},${r} 0 0 1 ${n(x + r)},${n(y)} Z`;
    this.add(`<path d="${d}" class="card${dash ? ' ' + dash : ''}" filter="url(#${this.id}-sh)"/>`);
    this.add(`<path d="M${n(x + w - c)},${n(y)} V${n(y + c - 3)} Q${n(x + w - c)},${n(y + c)} ${n(x + w - c + 3)},${n(y + c)} H${n(x + w)} Z" class="fold"/>`);
    if (fam) this.add(`<rect x="${n(x + 8)}" y="${n(y + 12)}" width="3" height="${n(h - 24)}" rx="1.5" class="bar f-${fam}"/>`);
    return this;
  }

  // Pill/badge with text; returns its width.
  pill(x, y, str, { role = 'badge', fam, dash = '', h = 24, padX = 10, solid = false } = {}) {
    const w = textWidth(str, role) + padX * 2;
    const cls = solid ? 'solid' : fam ? 'tint' : 'chip';
    this.rect(x, y, w, h, { cls, rx: h / 2, dash, fam });
    const tcls = solid ? 'c-on' : fam ? 'c-a' : '';
    this.add(`<g${fam ? ` class="f-${fam}"` : ''}>`);
    this.text(x + w / 2, y + h / 2 + ROLES[role].size * 0.35, str, { role, anchor: 'middle', cls: tcls });
    this.add('</g>');
    return w;
  }

  pillWidth(str, role = 'badge', padX = 10) { return textWidth(str, role) + padX * 2; }

  // Lays out pills left-to-right, wrapping at maxW. Returns rows used.
  pillFlow(x, y, items, maxW, { gap = 8, rowH = 32, role = 'badge', fam } = {}) {
    let cx = x;
    let row = 0;
    for (const it of items) {
      const label = typeof it === 'string' ? it : it.label;
      const w = this.pillWidth(label, role);
      if (w > maxW) throw new Error(`[${this.name}] pill wider than row: "${label}"`);
      if (cx + w > x + maxW) { row += 1; cx = x; }
      this.pill(cx, y + row * rowH, label, { role, fam: it.fam || fam, dash: it.dash || '' });
      cx += w + gap;
    }
    return row + 1;
  }

  // Gate: amber diamond (check-gate.sh).
  diamond(cx, cy, s = 22) {
    const h = s / 2;
    this.add(`<polygon points="${n(cx)},${n(cy - h)} ${n(cx + h)},${n(cy)} ${n(cx)},${n(cy + h)} ${n(cx - h)},${n(cy)}" class="tint f-gate" stroke-width="1.25"/>`);
    return this;
  }

  // Human approval: hexagon with a check mark.
  hexagon(cx, cy, r = 13) {
    const pts = [];
    for (let i = 0; i < 6; i += 1) {
      const a = (Math.PI / 3) * i;
      pts.push(`${n(cx + r * Math.cos(a))},${n(cy + r * Math.sin(a))}`);
    }
    this.add(`<g class="f-orch"><polygon points="${pts.join(' ')}" class="tint" stroke-width="1.25"/>`);
    this.add(`<path d="M${n(cx - 4.5)},${n(cy + 0.5)} L${n(cx - 1.2)},${n(cy + 3.8)} L${n(cx + 5)},${n(cy - 3.5)}" class="tick"/></g>`);
    return this;
  }

  // Orthogonal edge through points with rounded corners and an arrowhead.
  edge(points, { style = '', head = true, tail = false, r = 6 } = {}) {
    let d = `M${n(points[0][0])},${n(points[0][1])}`;
    for (let i = 1; i < points.length; i += 1) {
      const [x, y] = points[i];
      if (i < points.length - 1) {
        const [px, py] = points[i - 1];
        const [nx, ny] = points[i + 1];
        const l1 = Math.hypot(x - px, y - py);
        const l2 = Math.hypot(nx - x, ny - y);
        const rr = Math.min(r, l1 / 2, l2 / 2);
        const ax = x - ((x - px) / l1) * rr;
        const ay = y - ((y - py) / l1) * rr;
        const bx = x + ((nx - x) / l2) * rr;
        const by = y + ((ny - y) / l2) * rr;
        d += ` L${n(ax)},${n(ay)} Q${n(x)},${n(y)} ${n(bx)},${n(by)}`;
      } else {
        d += ` L${n(x)},${n(y)}`;
      }
    }
    const me = head ? ` marker-end="url(#${this.id}-ah)"` : '';
    const ms = tail ? ` marker-start="url(#${this.id}-ah)"` : '';
    return this.add(`<path d="${d}" class="edge${style ? ' ' + style : ''}"${me}${ms}/>`);
  }

  // Label sitting on top of an edge, with a background knockout.
  edgeLabel(cx, cy, str, { bg = 'lbg', role = 'meta' } = {}) {
    const w = textWidth(str, role) + 10;
    this.add(`<rect x="${n(cx - w / 2)}" y="${n(cy - 10)}" width="${n(w)}" height="18" rx="4" class="${bg}"/>`);
    return this.text(cx, cy + 3.5, str, { role, anchor: 'middle' });
  }

  // Section label (uppercase, accent colored).
  label(x, y, str, fam = 'neutral', maxW) {
    this.add(`<g class="f-${fam}">`);
    this.text(x, y, str, { role: 'label', maxW });
    return this.add('</g>');
  }

  // Legend row. items: [{kind, label}]
  legend(x, y, items, maxW) {
    let cx = x;
    let cy = y;
    for (const it of items) {
      const tw = textWidth(it.label, 'meta');
      const w = 34 + tw + 24;
      if (cx + w > x + maxW) { cx = x; cy += 26; }
      const mid = cy;
      switch (it.kind) {
        case 'arrow': this.edge([[cx, mid], [cx + 26, mid]]); break;
        case 'dashed': this.edge([[cx, mid], [cx + 26, mid]], { style: 'dashed' }); break;
        case 'dotted': this.edge([[cx, mid], [cx + 26, mid]], { style: 'dotted' }); break;
        case 'both': this.edge([[cx + 1, mid], [cx + 25, mid]], { tail: true }); break;
        case 'diamond': this.diamond(cx + 13, mid, 18); break;
        case 'hexagon': this.hexagon(cx + 13, mid, 10); break;
        case 'step': this.rect(cx + 2, mid - 8, 22, 16, { cls: 'card', rx: 4 }); break;
        case 'optional': this.rect(cx + 2, mid - 8, 22, 16, { cls: 'card', rx: 4, dash: 'dashed' }); break;
        case 'doc':
          this.add(`<path d="M${n(cx + 6)},${n(mid - 9)} H${n(cx + 16)} L${n(cx + 21)},${n(mid - 4)} V${n(mid + 9)} H${n(cx + 6)} Z" class="card"/>`);
          break;
        case 'pill': this.rect(cx + 1, mid - 8, 24, 16, { cls: 'chip', rx: 8 }); break;
        case 'pill-dashed': this.rect(cx + 1, mid - 8, 24, 16, { cls: 'chip', rx: 8, dash: 'dashed' }); break;
        case 'solid': this.rect(cx + 1, mid - 8, 24, 16, { cls: 'solid', rx: 8 }); break;
        case 'tint': this.rect(cx + 1, mid - 8, 24, 16, { cls: 'tint', rx: 8, fam: it.fam || 'neutral', dash: 'dashed' }); break;
        default: throw new Error(`unknown legend kind ${it.kind}`);
      }
      this.text(cx + 34, mid + 4, it.label, { role: 'meta' });
      cx += w;
    }
    return cy;
  }

  header() {
    const m = THEME.margin;
    this.text(m, 52, this.title, { role: 'title', maxW: this.W - 2 * m });
    this.text(m, 78, this.subtitle, { role: 'sub', maxW: this.W - 2 * m });
  }

  toString() {
    const { W, H, id } = this;
    const footer = `<text x="${W - THEME.margin}" y="${H - 18}" class="r-meta" text-anchor="end">Company OS · generated by docs/diagrams/render.js</text>`;
    return [
      `<svg xmlns="http://www.w3.org/2000/svg" id="${id}" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="${id}-title ${id}-desc">`,
      `<title id="${id}-title">${esc(this.title)}</title>`,
      `<desc id="${id}-desc">${esc(this.desc)}</desc>`,
      `<style>\n${css(id)}\n</style>`,
      '<defs>',
      `<filter id="${id}-sh" x="-5%" y="-5%" width="110%" height="130%"><feDropShadow dx="0" dy="1" stdDeviation="1.5" class="shadow"/></filter>`,
      `<marker id="${id}-ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" markerUnits="userSpaceOnUse" orient="auto-start-reverse"><path d="M1,1.5 L9,5 L1,8.5 Z" class="ah"/></marker>`,
      '</defs>',
      `<rect x="0.5" y="0.5" width="${W - 1}" height="${H - 1}" rx="16" class="panel"/>`,
      ...this.parts,
      footer,
      '</svg>',
      '',
    ].join('\n');
  }
}

module.exports = { Diagram, THEME, ROLES, textWidth, readRepoFacts };

// ═══════════════════════════════════════════════════════════════
// 4. Diagrams
// ═══════════════════════════════════════════════════════════════

const DIAGRAMS = [];
const diagram = (fn) => DIAGRAMS.push(fn);

// ── 1. System overview ─────────────────────────────────────────
diagram((F) => {
  const agentCount = Object.keys(F.agents).length;
  const d = new Diagram({
    name: 'system-overview',
    height: 872,
    title: 'How Company OS fits into your repo',
    subtitle: 'Three layers do the work. Artifacts are how they hand work to each other.',
    desc: `Company OS overlays your repo. You run a command; ${agentCount} agents decide what happens, ${F.skills.length} skills say how to think and what to produce, and ${F.toolCount} tool scripts execute fixed actions. All layers read and write artifacts: Markdown files with YAML frontmatter and lineage links. Skills and agents are authored in os/ and built into runtime adapters.`,
  });

  // Inputs strip
  const iy = 112;
  d.card(40, iy, 880, 64);
  const seg = [
    ['You', 'run /ship, /gtm-sprint, /setup'],
    ['company.config.yaml', 'tech stack, stage, conventions'],
    ['standards/', 'reference docs agents read'],
  ];
  seg.forEach(([h, b], i) => {
    const x = 40 + i * (880 / 3);
    if (i > 0) d.add(`<line x1="${n(x)}" y1="${iy + 14}" x2="${n(x)}" y2="${iy + 50}" class="rule"/>`);
    d.text(x + 24, iy + 27, h, { role: i === 0 ? 'h' : 'codeh', maxW: 250 });
    d.text(x + 24, iy + 47, b, { role: 'body', maxW: 250 });
  });

  // Layer bands
  const bx = 96;
  const bw = 536;
  const bands = [
    { y: 216, fam: 'orch', label: 'Agents · authority', count: `${agentCount} agents`,
      desc: 'Choose what happens next: route, decide, delegate.',
      chips: ['Orchestrator', '5 domain agents', '3 engineering sub-agents'], role: 'badge' },
    { y: 376, fam: 'eng', label: 'Skills · procedure', count: `${F.skills.length} skills`,
      desc: 'Advise and produce artifacts: procedures, templates, checklists.',
      chips: ['prd-writer', 'architecture-draft', 'threat-modeling', `+${F.skills.length - 3} more`], role: 'badge' },
    { y: 536, fam: 'neutral', label: 'Tools · execution', count: `${F.toolCount} tool scripts`,
      desc: 'Run fixed, deterministic actions. Tools never contain reasoning.',
      chips: ['validate.sh', 'check-gate.sh', 'run-tests.sh', `+${F.toolCount - 3} more`], role: 'code' },
  ];
  const bh = 112;
  for (const b of bands) {
    d.card(bx, b.y, bw, bh, { fam: b.fam });
    d.label(bx + 24, b.y + 28, b.label, b.fam, 300);
    const cw = d.pillWidth(b.count);
    d.pill(bx + bw - 20 - cw, b.y + 12, b.count, { fam: b.fam });
    d.text(bx + 24, b.y + 52, b.desc, { role: 'body', maxW: bw - 48 });
    if (d.pillFlow(bx + 24, b.y + 70, b.chips, bw - 48, { role: b.role }) > 1) throw new Error(`[system-overview] chips wrap in ${b.label}`);
  }

  // Inputs -> agents
  d.edge([[bx + bw / 2, iy + 64], [bx + bw / 2, 216]]);
  d.edgeLabel(bx + bw / 2, 196, 'objective');
  // Agents -> skills, skills -> tools
  const cx = bx + bw / 2;
  d.edge([[cx, 216 + bh], [cx, 376]]);
  d.edgeLabel(cx, 352, 'use for how to think');
  d.edge([[cx, 376 + bh], [cx, 536]], { style: 'dashed' });
  d.edgeLabel(cx, 512, 'recommend, never run');
  // Agents -> tools (gutter)
  d.edge([[bx, 272], [64, 272], [64, 592], [bx, 592]]);
  d.add(`<rect x="56" y="370" width="16" height="124" class="lbg"/>`);
  d.text(68, 432, 'use for how to act', { role: 'meta', anchor: 'middle', transform: 'rotate(-90 68 432)' });

  // Artifacts column
  const ax = 664;
  const aw = 256;
  const ay = 216;
  const ah = 432;
  d.card(ax, ay, aw, ah, { fam: 'gate' });
  d.label(ax + 24, ay + 28, 'Artifacts · handshake', 'gate', aw - 40);
  d.text(ax + 24, ay + 54, 'artifacts/', { role: 'codeh', maxW: aw - 48 });
  let py = d.para(ax + 24, ay + 76, 'Markdown files with YAML frontmatter and lineage links between them.', { maxW: aw - 48 });
  const docs = ['PRD', 'RFC', 'Security review', 'Test plan', 'QA report', 'Launch brief', `+${F.artifactTypes.length - 6} more types`];
  py += 20;
  docs.forEach((t, i) => {
    const y = py + i * 32;
    const last = i === docs.length - 1;
    if (!last) {
      d.add(`<path d="M${ax + 26},${y} H${ax + 36} L${ax + 41},${y + 5} V${y + 18} H${ax + 26} Z" class="card"/>`);
    }
    d.text(ax + (last ? 26 : 52), y + 14, t, { role: last ? 'meta' : 'body', maxW: aw - 76 });
  });
  const sy = ay + ah - 44;
  d.add(`<line x1="${ax + 20}" y1="${sy - 16}" x2="${ax + aw - 20}" y2="${sy - 16}" class="rule"/>`);
  let sx = ax + 24;
  ['draft', 'review', 'approved'].forEach((s, i) => {
    if (i > 0) { d.edge([[sx - 2, sy + 12], [sx + 12, sy + 12]]); sx += 16; }
    sx += d.pill(sx, sy, s, { role: 'meta', padX: 6 }) + 2;
  });
  if (sx > ax + aw - 16) throw new Error('[system-overview] status pills overflow the artifacts card');
  // Bands <-> artifacts
  for (const b of bands) d.edge([[bx + bw + 2, b.y + bh / 2], [ax - 2, b.y + bh / 2]], { tail: true });

  // Authoring strip
  const sy2 = 680;
  d.card(40, sy2, 880, 96);
  d.label(64, sy2 + 28, 'Where it is authored', 'neutral', 300);
  const boxes = [
    { t: 'os/', m: 'edit here' },
    { t: 'tools/build/build.sh', m: 'regenerates adapters' },
  ];
  let bxx = 64;
  const by = sy2 + 42;
  boxes.forEach((b, i) => {
    const w = Math.max(textWidth(b.t, 'codeh'), textWidth(b.m, 'meta')) + 28;
    d.rect(bxx, by, w, 40, { cls: 'sunken', rx: 8 });
    d.text(bxx + 14, by + 17, b.t, { role: 'codeh' });
    d.text(bxx + 14, by + 33, b.m, { role: 'meta' });
    bxx += w;
    d.edge([[bxx + 2, by + 20], [bxx + 30, by + 20]]);
    bxx += 32;
    void i;
  });
  const outs = ['.claude/', 'AGENTS.md', 'GEMINI.md', '.cursor/', '.codex/'];
  let ox = bxx;
  for (const o of outs) ox += d.pill(ox, by + 8, o, { role: 'code' }) + 8;
  d.text(bxx, by - 10, 'generated runtime adapters (committed)', { role: 'meta', maxW: 896 - bxx });

  d.legend(40, 812, [
    { kind: 'arrow', label: 'uses' },
    { kind: 'dashed', label: 'recommends only' },
    { kind: 'both', label: 'reads and writes' },
  ], 600);
  return d;
});

// ── 2. Agent org chart ─────────────────────────────────────────
diagram((F) => {
  const A = F.agents;
  const rows = [
    { key: 'orchestrator', name: 'Orchestrator', fam: 'orch', role: 'Routes work, enforces gates, and approves releases.' },
    { key: 'product', name: 'Product', fam: 'product', role: 'Discovery, PRDs, and prioritization.' },
    { key: 'engineering', name: 'Engineering (Staff)', fam: 'eng', role: 'Architecture, task breakdown, code review.' },
    { key: 'engineering-backend', name: 'Backend', fam: 'eng', role: 'APIs, data models, background jobs.', sub: true },
    { key: 'engineering-frontend', name: 'Frontend', fam: 'eng', role: 'UI, user docs, instrumentation.', sub: true },
    { key: 'engineering-devops', name: 'DevOps', fam: 'eng', role: 'Deploys, observability, flags.', sub: true },
    { key: 'qa-release', name: 'QA & Release', fam: 'qa', role: 'Test plans, quality gates, release readiness.' },
    { key: 'growth', name: 'Growth', fam: 'growth', role: 'Positioning, launch, acquisition.' },
    { key: 'ops-risk', name: 'Ops & Risk', fam: 'ops', role: 'Security, privacy, compliance, cost.' },
  ];
  // Which skills appear under more than one agent
  const owners = {};
  for (const r of rows) for (const s of A[r.key].skills) owners[s] = (owners[s] || 0) + 1;

  const d = new Diagram({
    name: 'agent-org',
    height: 100, // set below
    title: 'Who does what: the agent organization',
    subtitle: `${rows.length} agents. The Orchestrator routes work; each agent owns a set of skills.`,
    desc: `Org chart of ${rows.length} agents. Orchestrator at the top; Product, Engineering, QA & Release, Growth, and Ops & Risk below it; Engineering delegates to Backend, Frontend, and DevOps sub-agents through the Task tool. Each agent lists its model, whether it has project memory, and its skills. ` +
      rows.map((r) => `${r.name}: ${A[r.key].skills.join(', ')}.`).join(' '),
  });

  const spineX = 56;
  const subSpineX = 96;
  let y = 112;
  const geo = {};
  for (const r of rows) {
    const a = A[r.key];
    const x = r.sub ? 112 : 72;
    const w = 920 - x;
    const leftW = r.sub ? 216 : 256;
    const pillX = x + leftW;
    const pillW = w - leftW - 20;
    // Measure pill rows (dry run)
    let cx = 0;
    let pr = 1;
    for (const s of a.skills) {
      const pw = d.pillWidth(s, 'code');
      if (cx + pw > pillW) { pr += 1; cx = 0; }
      cx += pw + 8;
    }
    const roleLines = d.wrap(r.role, 'body', leftW - 40);
    const leftH = 30 + roleLines.length * 18 + 34;
    const h = Math.max(leftH + 8, 24 + pr * 32);
    geo[r.key] = { x, y, w, h };
    d.card(x, y, w, h, { fam: r.fam });
    d.text(x + 24, y + 28, r.name, { role: 'h', maxW: leftW - 40 });
    roleLines.forEach((l, i) => d.text(x + 24, y + 48 + i * 18, l, { role: 'body' }));
    let bx = x + 24;
    const by = y + 48 + roleLines.length * 18 - 4;
    bx += d.pill(bx, by, a.model, { role: 'meta', padX: 8, h: 22 }) + 6;
    if (a.memory) bx += d.pill(bx, by, 'memory', { role: 'meta', padX: 8, h: 22 }) + 6;
    d.pill(bx, by, `${a.skills.length} skills`, { role: 'meta', padX: 8, h: 22, fam: r.fam });
    d.add(`<line x1="${pillX - 16}" y1="${y + 14}" x2="${pillX - 16}" y2="${y + h - 14}" class="rule"/>`);
    d.pillFlow(pillX, y + (h - (pr * 32 - 8)) / 2, a.skills.map((s) => ({ label: s, dash: owners[s] > 1 ? 'dashed' : '' })), pillW, { role: 'code' });
    y += h + 16;
  }
  // Main spine: Orchestrator to each domain agent
  const o = geo.orchestrator;
  const domain = rows.filter((r) => !r.sub && r.key !== 'orchestrator');
  const lastTop = geo[domain[domain.length - 1].key];
  d.edge([[o.x, o.y + o.h / 2], [spineX, o.y + o.h / 2], [spineX, lastTop.y + lastTop.h / 2], [72, lastTop.y + lastTop.h / 2]]);
  for (const r of domain.slice(0, -1)) {
    const g = geo[r.key];
    d.edge([[spineX, g.y + g.h / 2], [72, g.y + g.h / 2]]);
  }
  // Sub spine: Engineering to sub-agents (dashed = Task tool delegation)
  const e = geo.engineering;
  const subs = rows.filter((r) => r.sub);
  const lastSub = geo[subs[subs.length - 1].key];
  d.edge([[subSpineX, e.y + e.h], [subSpineX, lastSub.y + lastSub.h / 2], [112, lastSub.y + lastSub.h / 2]], { style: 'dashed' });
  for (const r of subs.slice(0, -1)) {
    const g = geo[r.key];
    d.edge([[subSpineX, g.y + g.h / 2], [112, g.y + g.h / 2]], { style: 'dashed' });
  }

  const ly = y + 8;
  d.legend(40, ly, [
    { kind: 'arrow', label: 'reports to the Orchestrator' },
    { kind: 'dashed', label: 'delegated via the Task tool' },
    { kind: 'pill', label: 'skill' },
    { kind: 'pill-dashed', label: 'skill shared with another agent' },
  ], 880);
  d.text(40, ly + 32, 'opus / sonnet = the model the agent runs on. memory = keeps project memory across sessions.', { role: 'meta', maxW: 880 });
  d.text(40, ly + 50, 'Backend and DevOps work in parallel; Frontend waits for the API contract.', { role: 'meta', maxW: 880 });
  d.H = ly + 90;
  return d;
});

// ── 3. Ship flow ───────────────────────────────────────────────
diagram(() => {
  const d = new Diagram({
    name: 'ship-flow',
    height: 1272,
    title: 'The /ship pipeline',
    subtitle: 'One command takes a feature from idea to release. It pauses at every gate for your approval.',
    desc: 'Plan: load config, inventory artifacts, discovery check for new features, classify, plan stages, you approve the plan. Build (step 5): PRD by Product, gate prd-to-rfc, you approve; RFC and API contract by Engineering, gate rfc-to-impl, you approve; implement by Engineering and sub-agents, gate impl-to-qa, you approve. In parallel: launch brief by Growth, threat model by Ops & Risk, test plan by QA. Verify: user docs and tours, seed and verify, QA report, optional dogfood, optional experiment review. Release: release gate with tests, lint, scan, pre-deploy and version bump, gate release, you approve; release summary; optional AI cost logging; what next. At every gate: delegate, validate and link, promote to review, check-gate, you review, then approve or iterate.',
  });

  const X0 = 68; // nodes start here; x = 52 carries the arrows between bands
  const XE = 904;
  const band = (y, h, num, title, meta) => {
    d.rect(40, y, 880, h, { cls: 'sunken', rx: 12 });
    d.rect(X0, y + 14, 22, 22, { cls: 'solid', rx: 11 });
    d.text(X0 + 11, y + 29.5, String(num), { role: 'badge', anchor: 'middle', cls: 'c-on' });
    d.text(X0 + 32, y + 30, title, { role: 'h', maxW: 400 });
    d.text(XE, y + 30, meta, { role: 'meta', anchor: 'end', maxW: 420 });
  };
  // Arrow from a point down into the next band, entering its first node from the left.
  const handoff = (fromX, fromY, gapY, toY) => {
    d.edge([[fromX, fromY], [fromX, gapY], [52, gapY], [52, toY], [X0 - 2, toY]]);
  };
  // A step / artifact node
  const node = (x, y, w, h, { step, title, meta, code, fam, doc, dash }) => {
    if (doc) d.docCard(x, y, w, h, { fam, dash }); else d.card(x, y, w, h, { fam, dash });
    let ty = y + 24;
    if (step) { d.add(`<g class="f-${fam || 'neutral'}">`); d.text(x + 20, ty, step, { role: 'label', maxW: w - 36 }); d.add('</g>'); ty += 20; }
    d.text(x + 20, ty, title, { role: 'hs', maxW: w - 36 });
    if (meta) { ty += 18; d.text(x + 20, ty, meta, { role: 'meta', maxW: w - 30 }); }
    if (code) { ty += 18; d.text(x + 20, ty, code, { role: 'code', maxW: w - 30 }); }
  };
  // Gate group: arrow, diamond (gate check), arrow, hexagon (you approve). 90px wide.
  const gate = (x, cy, name) => {
    d.edge([[x, cy], [x + 24, cy]]);
    d.diamond(x + 36, cy, 22);
    d.edge([[x + 47, cy], [x + 64, cy]]);
    d.hexagon(x + 78, cy, 12);
    d.text(x + 46, cy - 22, name, { role: 'code', anchor: 'middle', maxW: 100 });
    return x + 90;
  };

  // Band 1: Plan
  const b1 = 112;
  band(b1, 148, 1, 'Plan', 'Orchestrator');
  const p = [
    { step: 'Step 1', title: 'Load config', meta: 'stack and stage' },
    { step: 'Step 2', title: 'Inventory', meta: 'what exists' },
    { step: 'Step 2.5', title: 'Discovery', meta: 'new ideas only', dash: 'dashed' },
    { step: 'Step 3', title: 'Classify', meta: 'pick the route' },
    { step: 'Step 4', title: 'Plan stages', meta: 'who does what' },
  ];
  const pw = 132;
  const pg = 22;
  const py = b1 + 56;
  p.forEach((s, i) => {
    const x = X0 + i * (pw + pg);
    node(x, py, pw, 76, { ...s, fam: 'orch' });
    if (i > 0) d.edge([[x - pg, py + 38], [x - 2, py + 38]]);
  });
  const p4end = X0 + 5 * pw + 4 * pg;
  d.edge([[p4end, py + 38], [p4end + 34, py + 38]]);
  const planHexX = p4end + 48;
  d.hexagon(planHexX, py + 38, 12);
  d.text(planHexX, py + 14, 'you approve', { role: 'meta', anchor: 'middle', maxW: 100 });

  // Band 2: Build
  const b2 = 300;
  band(b2, 304, 2, 'Build · Step 5, one stage at a time', 'artifact folders live under artifacts/');
  const my = b2 + 68;
  const mh = 92;
  const aw = 164;
  const cy = my + mh / 2;
  let x = X0;
  node(x, my, aw, mh, { step: 'Product', title: 'PRD', meta: 'what and why', code: 'prds/', fam: 'product', doc: true });
  const prdX = x;
  x = gate(x + aw, cy, 'prd-to-rfc') + 22;
  d.edge([[x - 22, cy], [x - 2, cy]]);
  node(x, my, aw, mh, { step: 'Engineering', title: 'RFC', meta: 'plus API contract', code: 'rfcs/', fam: 'eng', doc: true });
  const rfcX = x;
  x = gate(x + aw, cy, 'rfc-to-impl') + 22;
  d.edge([[x - 22, cy], [x - 2, cy]]);
  node(x, my, aw, mh, { step: 'Engineering', title: 'Implement', meta: 'with sub-agents', code: 'tools/ci/*.sh', fam: 'eng' });
  const implX = x;
  const g3 = x + aw;
  gate(g3, cy, 'impl-to-qa');
  // Parallel row
  const ry = my + mh + 48;
  const rh = 76;
  node(prdX, ry, aw, rh, { step: 'Growth', title: 'Launch brief', code: 'launch-briefs/', fam: 'growth', doc: true });
  node(rfcX, ry, aw, rh, { step: 'Ops & Risk', title: 'Threat model', code: 'security-reviews/', fam: 'ops', doc: true });
  node(implX, ry, aw, rh, { step: 'QA & Release', title: 'Test plan', code: 'test-plans/', fam: 'qa', doc: true });
  d.edge([[prdX + aw / 2, my + mh], [prdX + aw / 2, ry]], { style: 'dashed' });
  d.edge([[rfcX + aw / 2, my + mh], [rfcX + aw / 2, ry]], { style: 'dashed' });
  d.edge([[implX + aw, ry + rh / 2], [g3 + 36, ry + rh / 2], [g3 + 36, cy + 12]], { style: 'dashed' });
  d.edgeLabel(prdX + aw / 2, my + mh + 24, 'in parallel', { bg: 'lbg' });
  d.edgeLabel(rfcX + aw / 2, my + mh + 24, 'in parallel', { bg: 'lbg' });

  // Band 1 -> Band 2 (from plan approval into the PRD)
  handoff(planHexX, py + 50, b2 - 20, cy);

  // Band 3: Verify
  const b3 = 644;
  band(b3, 148, 3, 'Verify', 'after impl-to-qa passes');
  const v = [
    { step: 'Step 5.7', title: 'Docs and tours', meta: 'Frontend', fam: 'eng' },
    { step: 'Step 5.8', title: 'Seed and verify', meta: 'you test the app', fam: 'eng' },
    { step: 'QA & Release', title: 'QA report', meta: 'qa-reports/', fam: 'qa', doc: true },
    { step: 'Step 5.9', title: 'Dogfood', meta: 'optional', fam: 'qa', dash: 'dashed' },
    { step: 'Step 5.95', title: 'Experiments', meta: 'review, advisory', fam: 'orch', dash: 'dashed' },
  ];
  const vw = 152;
  const vg = 19;
  const vy = b3 + 56;
  v.forEach((s, i) => {
    const vx = X0 + i * (vw + vg);
    node(vx, vy, vw, 76, s);
    if (i > 0) d.edge([[vx - vg, vy + 38], [vx - 2, vy + 38]], { style: s.dash || '' });
  });
  // Band 2 -> Band 3 (from impl-to-qa approval)
  handoff(g3 + 78, cy + 12, b3 - 20, vy + 38);

  // Band 4: Release
  const b4 = 832;
  band(b4, 148, 4, 'Release', 'Orchestrator · QA & Release');
  const ry4 = b4 + 56;
  const rcy = ry4 + 38;
  node(X0, ry4, 216, 76, { step: 'Step 6', title: 'Release gate', meta: 'tests, scan, version bumped', fam: 'qa' });
  let rx = gate(X0 + 216, rcy, 'release') + 22;
  d.edge([[rx - 22, rcy], [rx - 2, rcy]]);
  node(rx, ry4, 160, 76, { step: 'Step 7', title: 'Release summary', fam: 'orch' });
  rx += 160 + 22;
  d.edge([[rx - 22, rcy], [rx - 2, rcy]], { style: 'dotted' });
  node(rx, ry4, 160, 76, { step: 'Step 7.5', title: 'Log AI cost', meta: 'advisory', fam: 'orch', dash: 'dotted' });
  rx += 160 + 22;
  d.edge([[rx - 22, rcy], [rx - 2, rcy]]);
  if (XE - rx < 140) throw new Error('[ship-flow] release row too wide');
  node(rx, ry4, XE - rx, 76, { step: 'Step 8', title: "What's next", meta: 'suggestions only', fam: 'orch' });
  // Band 3 -> Band 4
  const lastV = X0 + 4 * (vw + vg);
  handoff(lastV + vw / 2, vy + 76, b4 - 20, rcy);

  // Inset: what happens at every gate
  const iy = 1012;
  d.card(40, iy, 880, 184);
  d.label(64, iy + 30, 'What happens at every gate (Step 5)', 'gate', 400);
  const loop = [
    { t: 'Delegate', m: 'to the right agent' },
    { t: 'Validate, link', m: 'validate.sh' },
    { t: 'To review', m: 'promote.sh' },
    { t: 'Check the gate', m: 'check-gate.sh' },
    { t: 'You review', m: 'approve or reject' },
  ];
  const lw = 152;
  const lg = 20;
  const ly = iy + 50;
  loop.forEach((s, i) => {
    const lx = 64 + i * (lw + lg);
    d.rect(lx, ly, lw, 52, { cls: 'sunken', rx: 8 });
    d.text(lx + 14, ly + 22, `${String.fromCharCode(97 + i)}. ${s.t}`, { role: 'hs', maxW: lw - 24 });
    d.text(lx + 14, ly + 40, s.m, { role: i >= 1 && i <= 3 ? 'code' : 'meta', maxW: lw - 24 });
    if (i > 0) d.edge([[lx - lg, ly + 26], [lx - 2, ly + 26]]);
    if (i === 3) d.diamond(lx + lw - 16, ly + 14, 14);
    if (i === 4) d.hexagon(lx + lw - 16, ly + 14, 9);
  });
  const last = 64 + 4 * (lw + lg);
  d.edge([[last + lw / 2, ly + 52], [last + lw / 2, ly + 80], [64 + lw / 2, ly + 80], [64 + lw / 2, ly + 54]], { style: 'dashed' });
  d.edgeLabel((64 + last + lw) / 2, ly + 80, 'If you request changes, the agent iterates with your feedback', { bg: 'lbg-card' });
  d.text(64, ly + 116, 'If you approve, promote.sh marks the artifact approved and the next step starts.', { role: 'body', maxW: 840 });

  d.legend(40, 1224, [
    { kind: 'step', label: 'step' },
    { kind: 'doc', label: 'artifact produced' },
    { kind: 'diamond', label: 'gate check' },
    { kind: 'hexagon', label: 'you approve' },
    { kind: 'optional', label: 'optional or advisory' },
    { kind: 'dashed', label: 'parallel work' },
  ], 880);
  return d;
});

// ── 4. Stage-aware gates ───────────────────────────────────────
diagram(() => {
  const d = new Diagram({
    name: 'stage-gates',
    height: 728,
    title: 'Which gates block, by company stage',
    subtitle: 'check-gate.sh reads company.stage. Early stages warn; later stages block.',
    desc: 'Matrix of four gates by four stages. idea: all gates advisory. mvp: prd-to-rfc and rfc-to-impl enforced, impl-to-qa and release advisory. growth and scale: all enforced. The AI safety check inside the release gate follows the same pattern as release. Advisory prints warnings and exits 0. Enforced prints failures and exits 1. No stage set means growth; an unknown stage is enforced.',
  });
  const stages = [
    { s: 'idea', m: 'everything warns' },
    { s: 'mvp', m: 'core gates block' },
    { s: 'growth', m: 'all gates block' },
    { s: 'scale', m: 'all gates block' },
  ];
  const E = 'Enforced';
  const A = 'Advisory';
  const gates = [
    { g: 'prd-to-rfc', c: 'PRD is approved and has acceptance criteria.', v: [A, E, E, E] },
    { g: 'rfc-to-impl', c: 'RFC is approved and its parent PRD is approved.', v: [A, E, E, E] },
    { g: 'impl-to-qa', c: 'RFC is approved and a test plan exists. Seed data catalog is a hint only.', v: [A, A, E, E] },
    { g: 'release', c: 'PRD, RFC and QA report approved; security review exists; app version is valid semver and was bumped.', v: [A, A, E, E] },
    { g: 'AI safety (bar 10)', c: 'Part of release. Only when ai.llm_provider is set and the RFC covers AI.', v: [A, A, E, E], sub: true },
  ];
  const tx = 40;
  const ty = 112;
  const gw = 392;
  const sw = 122;
  const hh = 60;
  const rh = 72;
  const th = hh + gates.length * rh;
  d.card(tx, ty, 880, th);
  d.add(`<rect x="${tx + 0.5}" y="${ty + 0.5}" width="879" height="${hh}" rx="10" class="sunken"/>`);
  d.add(`<rect x="${tx + 0.5}" y="${ty + hh - 10}" width="879" height="10" class="sunken" style="stroke:none"/>`);
  d.text(tx + 24, ty + 26, 'Gate', { role: 'hs' });
  d.text(tx + 24, ty + 44, 'what it checks', { role: 'meta' });
  stages.forEach((s, i) => {
    const cx = tx + gw + i * sw + sw / 2;
    d.text(cx, ty + 26, s.s, { role: 'codeh', anchor: 'middle', maxW: sw - 8 });
    d.text(cx, ty + 44, s.m, { role: 'meta', anchor: 'middle', maxW: sw - 8 });
  });
  d.add(`<line x1="${tx}" y1="${ty + hh}" x2="${tx + 880}" y2="${ty + hh}" class="rule"/>`);
  gates.forEach((g, r) => {
    const y = ty + hh + r * rh;
    if (r > 0) d.add(`<line x1="${tx + 16}" y1="${y}" x2="${tx + 864}" y2="${y}" class="rule"/>`);
    const gx = tx + (g.sub ? 40 : 24);
    if (g.sub) d.text(tx + 24, y + 26, '↳', { role: 'meta' });
    d.text(gx, y + 26, g.g, { role: 'codeh', maxW: gw - 48 });
    const lines = d.wrap(g.c, 'meta', gw - (g.sub ? 64 : 48));
    lines.forEach((l, i) => d.text(gx, y + 44 + i * 16, l, { role: 'meta' }));
    g.v.forEach((v, i) => {
      const cx = tx + gw + i * sw + sw / 2;
      const w = d.pillWidth(v, 'badge', 12);
      if (v === E) d.pill(cx - w / 2, y + rh / 2 - 12, v, { solid: true, padX: 12 });
      else d.pill(cx - w / 2, y + rh / 2 - 12, v, { fam: 'gate', dash: 'dashed', padX: 12 });
    });
  });
  for (let i = 0; i < 4; i += 1) {
    const lx = tx + gw + i * sw;
    d.add(`<line x1="${lx}" y1="${ty + 12}" x2="${lx}" y2="${ty + th - 12}" class="rule"/>`);
  }

  // Behavior cards
  const by = ty + th + 32;
  const cards = [
    { pill: [A, false], t: 'Advisory', lines: ['Failures print as warnings.', 'Exit code 0. Work continues.'], code: 'GATE ADVISORY ... not blocking' },
    { pill: [E, true], t: 'Enforced', lines: ['Failures print with details.', 'Exit code 1. Fix and re-run.'], code: 'GATE FAILED' },
    { t: 'Set your stage', lines: ['In company.config.yaml.', 'Not set: treated as growth.', 'Unknown value: enforced.'], code: 'company.stage: mvp' },
  ];
  const cw = 280;
  cards.forEach((c, i) => {
    const cx = 40 + i * (cw + 20);
    d.card(cx, by, cw, 136);
    let yy = by + 30;
    if (c.pill) {
      const [label, solid] = c.pill;
      if (solid) d.pill(cx + 20, by + 14, label, { solid: true, padX: 12 });
      else d.pill(cx + 20, by + 14, label, { fam: 'gate', dash: 'dashed', padX: 12 });
      yy = by + 62;
    } else {
      d.text(cx + 20, yy, c.t, { role: 'hs', maxW: cw - 40 });
      yy += 24;
    }
    c.lines.forEach((l) => { d.text(cx + 20, yy, l, { role: 'body', maxW: cw - 40 }); yy += 18; });
    d.text(cx + 20, by + 120, c.code, { role: 'code', maxW: cw - 40 });
  });
  d.text(40, by + 164, 'Source: tools/artifact/check-gate.sh. Run it yourself: ./tools/artifact/check-gate.sh <gate> <artifact>', { role: 'meta', maxW: 880 });
  d.H = by + 164 + 56;
  return d;
});

// ── 5. Artifact lineage ────────────────────────────────────────
diagram((F) => {
  const d = new Diagram({
    name: 'artifact-lineage',
    height: 1024,
    title: 'Artifacts: lineage, status, and enforcement',
    subtitle: `${F.artifactTypes.length} artifact types share one frontmatter format. Four tools keep them honest.`,
    desc: `Every artifact moves draft, review, approved, and can be archived from any state; promote.sh enforces the order. Lineage example: ICP is parent of PRD; PRD is parent of RFC and launch brief; RFC is parent of security review, test plan, test data, and QA report; QA report depends on test plan. Frontmatter requires id, type, title, status, created, author; optional parent, children, depends_on, blocks. Enforcement chain: validate.sh, link.sh, promote.sh, check-gate.sh. Claude Code hooks: session-start.sh, pre-promote-validate.sh, post-write-artifact-check.sh. Types: ${F.artifactTypes.join(', ')}.`,
  });

  // A. Status lifecycle
  const ay = 112;
  d.card(40, ay, 880, 112);
  d.label(64, ay + 30, 'Status lifecycle', 'gate', 300);
  const states = [
    { s: 'draft', x: 64 },
    { s: 'review', x: 264 },
    { s: 'approved', x: 464 },
  ];
  const sy = ay + 52;
  let prevEnd = 0;
  states.forEach((st, i) => {
    const w = d.pillWidth(st.s, 'codeh', 18);
    d.rect(st.x, sy, w, 32, { cls: i === 2 ? 'solid' : 'chip', rx: 16 });
    d.text(st.x + w / 2, sy + 21, st.s, { role: 'codeh', anchor: 'middle', cls: i === 2 ? 'c-on' : '' });
    if (i > 0) {
      d.edge([[prevEnd + 2, sy + 16], [st.x - 2, sy + 16]]);
      d.edgeLabel((prevEnd + st.x) / 2, sy - 2, i === 1 ? 'promote.sh' : 'you approve', { bg: 'lbg-card' });
    }
    prevEnd = st.x + w;
  });
  const arX = 712;
  const arW = d.pillWidth('archived', 'codeh', 18);
  d.rect(arX, sy, arW, 32, { cls: 'chip', rx: 16, dash: 'dashed' });
  d.text(arX + arW / 2, sy + 21, 'archived', { role: 'codeh', anchor: 'middle' });
  d.edge([[prevEnd + 2, sy + 16], [arX - 2, sy + 16]], { style: 'dashed' });
  d.edgeLabel((prevEnd + arX) / 2, sy - 2, 'from any state', { bg: 'lbg-card' });
  d.text(64, ay + 104, 'promote.sh refuses to skip a step and runs validate.sh before every promotion.', { role: 'meta', maxW: 820 });

  // B. Lineage graph
  const gy = 256;
  const gh = 380;
  d.card(40, gy, 568, gh);
  d.label(64, gy + 30, 'Lineage: parent to child', 'gate', 300);
  const nh = 48;
  const nodeA = (x, y, w, t, type, fam) => {
    d.docCard(x, y, w, nh, { fam });
    d.text(x + 20, y + 21, t, { role: 'hs', maxW: w - 36 });
    d.text(x + 20, y + 38, type, { role: 'code', maxW: w - 28 });
  };
  const tw = 144;
  const r1 = gy + 52;
  nodeA(64, r1, tw, 'ICP', 'icp', 'growth');
  nodeA(232, r1, tw, 'PRD', 'prd', 'product');
  nodeA(400, r1, tw, 'RFC', 'rfc', 'eng');
  d.edge([[64 + tw + 2, r1 + nh / 2], [230, r1 + nh / 2]]);
  d.edge([[232 + tw + 2, r1 + nh / 2], [398, r1 + nh / 2]]);
  nodeA(232, r1 + 88, tw, 'Launch brief', 'launch-brief', 'growth');
  d.edge([[304, r1 + nh + 2], [304, r1 + 86]]);
  const kids = [
    ['Security review', 'security-review', 'ops'],
    ['Test plan', 'test-plan', 'qa'],
    ['QA report', 'qa-report', 'qa'],
    ['Test data', 'test-data', 'eng'],
  ];
  const kx = 432;
  const kw = 148;
  const busX = 416;
  const kStep = 62;
  const k0 = r1 + 76;
  kids.forEach((k, i) => {
    const ky = k0 + i * kStep;
    nodeA(kx, ky, kw, k[0], k[1], k[2]);
    d.edge([[busX, ky + nh / 2], [kx - 2, ky + nh / 2]]);
  });
  d.add(`<path d="M${busX},${r1 + nh + 2} V${k0 + 3 * kStep + nh / 2}" class="edge"/>`);
  // QA report depends_on Test plan (dashed, on the right side)
  const tpY = k0 + kStep + nh / 2;
  const qaY = k0 + 2 * kStep + nh / 2;
  d.edge([[kx + kw + 2, qaY], [kx + kw + 12, qaY], [kx + kw + 12, tpY], [kx + kw + 2, tpY]], { style: 'dashed', r: 4 });
  if (k0 + 3 * kStep + nh > gy + gh - 16) throw new Error('[artifact-lineage] child stack overflows its card');
  d.text(64, gy + 244, 'Other types link the same way:', { role: 'meta', maxW: 336 });
  const others = F.artifactTypes.filter((t) => !['prd', 'rfc', 'icp', 'launch-brief', 'security-review', 'test-plan', 'qa-report', 'test-data'].includes(t));
  const rowsUsed = d.pillFlow(64, gy + 256, others, 336, { role: 'code', rowH: 32 });
  if (gy + 256 + rowsUsed * 32 > gy + gh - 8) throw new Error('[artifact-lineage] type chips overflow their card');

  // Frontmatter card
  const fx = 632;
  const fw = 288;
  d.card(fx, gy, fw, gh);
  d.label(fx + 24, gy + 30, 'Frontmatter', 'gate', 200);
  const fm = [
    '---',
    'id: PRD-042',
    'type: prd',
    'title: Faster checkout',
    'status: review',
    'created: 2026-10-13',
    'author: product',
    'parent: ICP-001',
    'children: [RFC-042]',
    'depends_on: []',
    'blocks: []',
    '---',
  ];
  const lh = 24;
  const cy0 = gy + 60;
  const codeW = Math.max(...fm.map((l) => textWidth(l, 'code')));
  d.rect(fx + 16, cy0 - 16, fw - 32, fm.length * lh + 16, { cls: 'sunken', rx: 8 });
  fm.forEach((l, i) => d.text(fx + 30, cy0 + 8 + i * lh, l, { role: 'code' }));
  const bx = fx + 30 + codeW + 14;
  const bracket = (from, to, label) => {
    const y1 = cy0 + from * lh - 6;
    const y2 = cy0 + to * lh + 12;
    d.add(`<path d="M${bx},${y1} h4 V${y2} h-4" class="edge"/>`);
    d.text(bx + 10, (y1 + y2) / 2 + 4, label, { role: 'meta', maxW: fx + fw - 12 - (bx + 10) });
  };
  bracket(1, 6, 'required');
  bracket(7, 10, 'optional');

  // C. Enforcement chain
  const cy = 668;
  d.label(40, cy + 4, 'Enforcement chain (run in this order)', 'neutral', 600);
  const chain = [
    ['validate.sh', 'Checks frontmatter and that every referenced artifact exists.'],
    ['link.sh', 'Writes parent and child links into both files.'],
    ['promote.sh', 'Moves status forward one step at a time.'],
    ['check-gate.sh', 'Checks a stage gate. Strictness depends on company.stage.'],
  ];
  const cw = 202;
  const cg = 24;
  chain.forEach(([t, b], i) => {
    const x = 40 + i * (cw + cg);
    d.card(x, cy + 20, cw, 108, { fam: 'neutral' });
    d.text(x + 24, cy + 48, t, { role: 'codeh', maxW: cw - 40 });
    d.para(x + 24, cy + 72, b, { role: 'body', maxW: cw - 40 });
    if (i > 0) d.edge([[x - cg, cy + 74], [x - 2, cy + 74]]);
  });

  // Hooks
  const hy = 828;
  d.label(40, hy + 4, 'Claude Code hooks (run automatically)', 'neutral', 600);
  const hooks = [
    ['SessionStart', 'session-start.sh', 'Loads company, stage, branch, lessons.'],
    ['PreToolUse', 'pre-promote-validate.sh', 'Blocks promoting an invalid artifact.'],
    ['PostToolUse', 'post-write-artifact-check.sh', 'Warns when an artifact lacks frontmatter.'],
  ];
  const hw = 288;
  hooks.forEach(([ev, f, b], i) => {
    const x = 40 + i * (hw + 8);
    d.card(x, hy + 20, hw, 116);
    d.pill(x + 20, hy + 36, ev, { role: 'meta', padX: 8, h: 22 });
    d.text(x + 20, hy + 80, f, { role: 'code', maxW: hw - 40 });
    d.para(x + 20, hy + 100, b, { role: 'body', maxW: hw - 40 });
  });

  d.legend(40, 988, [
    { kind: 'doc', label: 'artifact' },
    { kind: 'arrow', label: 'parent to child' },
    { kind: 'dashed', label: 'depends_on' },
  ], 600);
  return d;
});

// ── 6. Multi-runtime build ─────────────────────────────────────
diagram((F) => {
  const d = new Diagram({
    name: 'multi-runtime-build',
    height: 848,
    title: 'One source, every runtime',
    subtitle: 'Edit os/. Run tools/build/build.sh. Each runtime gets its own generated adapter.',
    desc: `Source files in os/ (${F.skills.length} skills, ${Object.keys(F.agents).length} agents) and CLAUDE.md feed tools/build/build.sh, which runs five builders: build-claude.sh writes .claude/skills and .claude/agents for Claude Code; build-agents-md.sh writes AGENTS.md for Codex, Aider and other AGENTS.md readers; build-gemini.sh writes GEMINI.md for Gemini CLI; build-cursor.sh writes .cursor/rules and .cursorrules for Cursor; build-codex.sh writes .codex/config.md for Codex CLI. build.sh --check validates without writing. .claude/hooks, settings.json and agent-memory are hand-maintained, not generated.`,
  });
  // Build card
  const bx = 312;
  const bw = 272;
  d.card(bx, 120, bw, 72, { fam: 'orch' });
  d.text(bx + 24, 146, 'tools/build/build.sh', { role: 'codeh', maxW: bw - 40 });
  d.text(bx + 24, 166, '--runtime=<name>  ·  --check', { role: 'code', maxW: bw - 40 });

  // Rows
  const rows = [
    ['build-claude.sh', '.claude/skills/ + agents/', 'Claude Code'],
    ['build-agents-md.sh', 'AGENTS.md', 'Codex, Aider, any AGENTS.md reader'],
    ['build-gemini.sh', 'GEMINI.md', 'Gemini CLI'],
    ['build-cursor.sh', '.cursor/rules/ + .cursorrules', 'Cursor'],
    ['build-codex.sh', '.codex/config.md', 'Codex CLI'],
  ];
  const r0 = 248;
  const rh = 80;
  const ox = 624;
  const ow = 296;
  d.label(ox, r0 - 20, 'Generated · do not edit', 'neutral', ow);
  d.label(40, r0 - 20, 'Source · edit here', 'orch', 232);
  rows.forEach(([b, out, rt], i) => {
    const y = r0 + i * rh;
    d.rect(bx + 32, y + 12, bw - 32, 40, { cls: 'sunken', rx: 8 });
    d.text(bx + 48, y + 37, b, { role: 'code', maxW: bw - 64 });
    d.edge([[bx + 16, y + 32], [bx + 30, y + 32]], { head: false });
    d.edge([[bx + bw + 2, y + 32], [ox - 2, y + 32]]);
    d.card(ox, y, ow, 64, { dash: '' });
    d.text(ox + 20, y + 26, out, { role: 'codeh', maxW: ow - 40 });
    d.text(ox + 20, y + 46, rt, { role: 'body', maxW: ow - 40 });
  });
  // Bus from build.sh to builders
  const lastY = r0 + 4 * rh + 32;
  d.add(`<path d="M${bx + 16},192 V${lastY}" class="edge"/>`);
  rows.forEach((_, i) => d.add(`<path d="M${bx + 16},${r0 + i * rh + 32} h14" class="edge" marker-end="url(#${d.id}-ah)"/>`));

  // Source card
  const sy = r0;
  const sh = 4 * rh + 64;
  d.card(40, sy, 232, sh, { fam: 'orch' });
  const src = [
    ['os/skills/', `${F.skills.length} skills`],
    ['os/agents/', `${Object.keys(F.agents).length} agents`],
    ['CLAUDE.md', 'project rules'],
  ];
  src.forEach(([p, m], i) => {
    const y = sy + 20 + i * 56;
    d.rect(64, y, 184, 44, { cls: 'sunken', rx: 8 });
    d.text(80, y + 19, p, { role: 'codeh', maxW: 152 });
    d.text(80, y + 36, m, { role: 'meta', maxW: 152 });
  });
  d.para(64, sy + 208, 'Both os/ and the generated files are committed, so a fresh clone works without a build.', { role: 'body', maxW: 184 });
  d.add(`<line x1="64" y1="${sy + sh - 72}" x2="248" y2="${sy + sh - 72}" class="rule"/>`);
  d.text(64, sy + sh - 46, 'After editing, run:', { role: 'meta', maxW: 192 });
  d.text(64, sy + sh - 24, 'bash tools/build/build.sh', { role: 'code', maxW: 192 });
  // Source -> build.sh (leaves the card on the right, clear of the column label)
  d.edge([[274, sy + 40], [292, sy + 40], [292, 156], [bx - 2, 156]]);

  // Bottom strip
  const by = r0 + 5 * rh + 24;
  const cards = [
    ['Check before you commit', 'bash tools/build/build.sh --check', 'Runs validate-skill.sh and validate-agent.sh without writing files.'],
    ['Add a runtime later', 'tools/registry/install-runtime.sh', 'list-runtimes.sh shows what is detected and installed.'],
    ['Hand-maintained (not generated)', '.claude/hooks/ + settings.json', 'Plus .claude/agent-memory/. Claude Code only.'],
  ];
  const cw = 288;
  cards.forEach(([t, c, b], i) => {
    const x = 40 + i * (cw + 8);
    d.card(x, by, cw, 120);
    d.text(x + 20, by + 28, t, { role: 'hs', maxW: cw - 40 });
    d.text(x + 20, by + 50, c, { role: 'code', maxW: cw - 32 });
    d.para(x + 20, by + 76, b, { role: 'body', maxW: cw - 40 });
  });
  return d;
});

// ── 7. Install and upgrade ─────────────────────────────────────
diagram(() => {
  const d = new Diagram({
    name: 'install-upgrade',
    height: 100,
    title: 'Install once, upgrade safely',
    subtitle: 'One command installs Company OS. Upgrades merge file by file and never touch your own work.',
    desc: 'Install: run the installer with curl; it auto-detects Claude Code, Cursor, Codex, Gemini CLI and Aider or takes --runtime; installs os/ and AGENTS.md always plus one adapter per runtime; never overwrites company.config.yaml, artifacts, tasks, cogs or agent memory; then run /setup and start with /ship, /gtm-sprint or /rapid-prototype. Upgrade: /upgrade-company-os check, preview (dry run), apply (backs up first on major versions), smart merge using manifest hashes (untouched files update, edited files are kept, files changed on both sides become conflicts), migrations and health check, rollback from a backup.',
  });
  const col = (x, colW, title, fam, steps) => {
    d.label(x, 120, title, fam, colW - 32);
    let y = 136;
    const tops = [];
    steps.forEach((s, i) => {
      const cx = x + 14;
      const cardX = x + 44;
      const cardW = colW - 44;
      const inner = cardW - 40;
      // measure
      const bodyLines = s.body ? d.wrap(s.body, 'body', inner) : [];
      let h = 24 + 18;
      const codeLines = [].concat(s.code || []);
      h += codeLines.length * 22;
      h += bodyLines.length * 18;
      if (s.outcomes) h += s.outcomes.length * 30 + 4;
      h += 8;
      d.card(cardX, y, cardW, h);
      tops.push([cx, y + 22]);
      let ty = y + 28;
      d.text(cardX + 20, ty, s.title, { role: 'hs', maxW: inner });
      codeLines.forEach((c) => { ty += 22; d.text(cardX + 20, ty, c, { role: s.smallCode ? 'codes' : 'code', maxW: inner }); });
      bodyLines.forEach((l) => { ty += 18; d.text(cardX + 20, ty, l, { role: 'body' }); });
      if (s.outcomes) {
        ty += 10;
        // Fixed-width left column so every arrow lines up.
        const lw = Math.max(...s.outcomes.map(([a]) => d.pillWidth(a, 'meta', 8)));
        s.outcomes.forEach(([a, b, fam]) => {
          d.text(cardX + 20, ty + 15, a, { role: 'body', maxW: lw });
          d.edge([[cardX + 28 + lw, ty + 11], [cardX + 56 + lw, ty + 11]]);
          d.pill(cardX + 60 + lw, ty, b, { role: 'meta', padX: 8, h: 22, fam });
          ty += 30;
        });
      }
      y += h + 14;
    });
    // Stepper rail + numbers
    d.add(`<line x1="${x + 14}" y1="${tops[0][1]}" x2="${x + 14}" y2="${tops[tops.length - 1][1]}" class="rule" style="stroke:var(--border)"/>`);
    tops.forEach(([cx, cy], i) => {
      d.add(`<g class="f-${fam}"><circle cx="${cx}" cy="${cy}" r="12" class="tint" stroke-width="1.25"/></g>`);
      d.add(`<g class="f-${fam}">`);
      d.text(cx, cy + 4, String(i + 1), { role: 'badge', anchor: 'middle', cls: 'c-a' });
      d.add('</g>');
    });
    return y;
  };
  const y1 = col(40, 568, 'Install (first time)', 'orch', [
    { title: 'Run the installer', smallCode: true, code: ['curl -fsSL \\', '  https://raw.githubusercontent.com/vibbs/company-os/main/install.sh \\', '  | bash -s -- --runtime=claude'], body: 'From your project root. Works in a new or an existing repo. Swap claude for cursor, codex, gemini, aider, all or core.' },
    { title: 'Pick runtimes', code: '--runtime=claude,cursor', body: 'Combine runtimes with commas. Without the flag, the installer auto-detects Claude Code, Cursor, Codex, Gemini CLI and Aider.' },
    { title: 'Install files', body: 'os/ and AGENTS.md always. Adds .claude/, .cursor/, GEMINI.md or .codex/ for each runtime.' },
    { title: 'Keep your work', body: 'Never overwritten: company.config.yaml, artifacts/, tasks/, cogs/, .claude/agent-memory/.' },
    { title: 'Configure', code: '/setup', body: 'Fills in company.config.yaml, sets permissions, creates folders.' },
    { title: 'Start building', code: '/ship  ·  /gtm-sprint  ·  /rapid-prototype' },
  ]);
  const y2 = col(624, 312, 'Upgrade (later)', 'eng', [
    { title: 'Check', code: '/upgrade-company-os check', body: 'Or install.sh --check. Shows if a newer version exists.' },
    { title: 'Preview', code: '/upgrade-company-os preview', body: 'Runs install.sh --dry-run --force. Writes nothing.' },
    { title: 'Apply', code: '/upgrade-company-os apply', body: 'Backs up first on major versions (or with --backup) to .company-os/backup/.' },
    { title: 'Smart merge, file by file', body: 'Uses hashes in .company-os/manifest:',
      outcomes: [['untouched file', 'updated', 'eng'], ['you edited it', 'kept as is', 'orch'], ['both changed', 'conflict', 'gate']] },
    { title: 'Migrate and verify', body: 'Runs .company-os/migrations/, stamps the version, then health-check.sh.' },
    { title: 'Roll back if needed', code: '/upgrade-company-os rollback', body: 'Restores os/, .claude/, tools/ and CLAUDE.md from a backup, then run build.sh to refresh the other adapters.' },
  ]);
  d.H = Math.max(y1, y2) + 48;
  return d;
});

// ── 8. Workflow paths ──────────────────────────────────────────
diagram(() => {
  const d = new Diagram({
    name: 'workflow-paths',
    height: 860,
    title: 'Where to start',
    subtitle: 'Three entry points, from cheapest to most complete. Then the feedback loop keeps you shipping.',
    desc: 'Entry points: /gtm-sprint validates demand in 7, 14 or 21 days with no code; /rapid-prototype proves the tech in 4 hours, 1 day or 3 days and skips RFC, security review and QA; /ship builds and launches with every gate. Not sure: describe the goal and the workflow-router skill picks one of 10 paths. Feedback loop: customer-conversations, feedback-synthesizer (scores candidates: over 15 go to /ship, 8 to 15 to the discovery-validation skill, under 8 monitor), sprint-prioritizer, prd-writer, /ship, users of the shipped product, back to customer-conversations.',
  });
  const entries = [
    { fam: 'growth', cmd: '/gtm-sprint', what: 'Validate demand', time: '7, 14 or 21 days · no code',
      when: 'You are not sure anyone will pay.', out: 'ICP, interviews, pain matrix, LOIs, launch assets.', next: 'Move on when demand is proven.' },
    { fam: 'eng', cmd: '/rapid-prototype', what: 'Prove the tech', time: '4 hours, 1 day or 3 days',
      when: 'You need a demo or proof of concept.', out: 'Mini-PRD (3 criteria max), working demo. Skips RFC, security, QA.', next: 'Move on when the idea works.' },
    { fam: 'orch', cmd: '/ship', what: 'Build and launch', time: 'full pipeline, every gate',
      when: 'You know what to build.', out: 'PRD, RFC, code, test plan, QA report, launch brief.', next: 'Done when release passes.' },
  ];
  const ew = 264;
  const eg = 44;
  const ey = 120;
  // Height fits the tallest card's wrapped text.
  const tall = Math.max(...entries.map((e) => d.wrap(e.when, 'body', ew - 48).length + d.wrap(e.out, 'body', ew - 48).length));
  const eh = 138 + 28 + 20 + (tall - 1) * 18 + 40;
  entries.forEach((e, i) => {
    const x = 40 + i * (ew + eg);
    d.card(x, ey, ew, eh, { fam: e.fam });
    d.label(x + 24, ey + 30, e.what, e.fam, ew - 48);
    d.text(x + 24, ey + 58, e.cmd, { role: 'codeh', maxW: ew - 48 });
    d.text(x + 24, ey + 78, e.time, { role: 'meta', maxW: ew - 48 });
    d.add(`<line x1="${x + 24}" y1="${ey + 94}" x2="${x + ew - 20}" y2="${ey + 94}" class="rule"/>`);
    d.text(x + 24, ey + 118, 'Start here if', { role: 'hs', maxW: ew - 48 });
    let yy = d.para(x + 24, ey + 138, e.when, { maxW: ew - 48 });
    d.text(x + 24, yy + 28, 'You get', { role: 'hs', maxW: ew - 48 });
    yy = d.para(x + 24, yy + 48, e.out, { maxW: ew - 48 });
    d.add(`<line x1="${x + 24}" y1="${ey + eh - 40}" x2="${x + ew - 20}" y2="${ey + eh - 40}" class="rule"/>`);
    d.text(x + 24, ey + eh - 16, e.next, { role: 'meta', maxW: ew - 48 });
    if (i > 0) d.edge([[x - eg + 4, ey + 62], [x - 4, ey + 62]]);
  });

  // Router callout
  const ry = ey + eh + 24;
  d.rect(40, ry, 880, 48, { cls: 'sunken', rx: 10 });
  d.text(64, ry + 29, 'Not sure? Describe the goal. The workflow-router skill picks one of 10 paths, such as bug fix or GTM.', { role: 'body', maxW: 840 });

  // Feedback loop
  const ly = ry + 88;
  d.label(40, ly, 'After launch: the inbound feedback loop', 'product', 600);
  const nw = 264;
  const nh = 104;
  const gx = eg;
  const top = ly + 20;
  const bot = top + nh + 56;
  const nodes = [
    { x: 40, y: top, t: 'customer-conversations', b: 'Prep calls and log debriefs. 7 types, including mom-test.', fam: 'product' },
    { x: 40 + nw + gx, y: top, t: 'feedback-synthesizer', b: 'Themes, pain matrix, and a score per PRD candidate.', fam: 'product' },
    { x: 40 + 2 * (nw + gx), y: top, t: 'sprint-prioritizer', b: 'Ranks candidates by impact, effort, and risk.', fam: 'product' },
    { x: 40 + 2 * (nw + gx), y: bot, t: 'prd-writer', b: 'Turns the top candidate into a PRD.', fam: 'product' },
    { x: 40 + nw + gx, y: bot, t: '/ship', b: 'Build, verify, and release with gates.', fam: 'orch' },
    { x: 40, y: bot, t: 'Your users', b: 'Use the shipped product and talk to you again.', fam: 'neutral', plain: true },
  ];
  nodes.forEach((nd) => {
    d.card(nd.x, nd.y, nw, nh, { fam: nd.fam });
    d.text(nd.x + 24, nd.y + 30, nd.t, { role: nd.plain ? 'h' : 'codeh', maxW: nw - 44 });
    d.para(nd.x + 24, nd.y + 54, nd.b, { maxW: nw - 44 });
  });
  const mid = nh / 2;
  d.edge([[40 + nw + 2, top + mid], [40 + nw + gx - 2, top + mid]]);
  d.edge([[40 + 2 * nw + gx + 2, top + mid], [40 + 2 * (nw + gx) - 2, top + mid]]);
  const rx = 40 + 2 * (nw + gx) + nw / 2;
  d.edge([[rx, top + nh + 2], [rx, bot - 2]]);
  d.edge([[40 + 2 * (nw + gx) - 2, bot + mid], [40 + 2 * nw + gx + 2, bot + mid]]);
  d.edge([[40 + nw + gx - 2, bot + mid], [40 + nw + 2, bot + mid]]);
  d.edge([[40 + nw / 2, bot - 2], [40 + nw / 2, top + nh + 2]]);
  // Score note under the synthesizer
  const sx = 40 + nw + gx + nw / 2;
  const note = 'Score: over 15 → /ship · 8 to 15 → discovery-validation · under 8 → monitor';
  const noteW = textWidth(note, 'meta') + 28;
  const nY = top + nh + 14;
  d.add(`<path d="M${sx},${top + nh} V${nY}" class="edge dotted"/>`);
  d.rect(sx - noteW / 2, nY, noteW, 28, { cls: 'sunken', rx: 6 });
  d.text(sx, nY + 18, note, { role: 'meta', anchor: 'middle', maxW: 2 * (rx - nw / 2 - sx) + nw - 40 });
  d.text(40, bot + nh + 36, 'Other signals: churn risk goes to support-operations, ICP shifts to icp-positioning. See standards/ops/inbound-loop-sop.md', { role: 'meta', maxW: 880 });
  d.H = bot + nh + 80;
  return d;
});

// ═══════════════════════════════════════════════════════════════
// 5. Main
// ═══════════════════════════════════════════════════════════════

function renderAll() {
  const facts = readRepoFacts();
  return DIAGRAMS.map((fn) => {
    const d = fn(facts);
    return { file: `${d.name}.svg`, svg: d.toString() };
  });
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.includes('-h') || args.includes('--help')) {
    console.log('Usage:\n  node docs/diagrams/render.js           # write all SVGs to .company-os/docs/diagrams/\n  node docs/diagrams/render.js --check   # exit 1 if any SVG on disk is stale');
    process.exit(0);
  }
  const unknown = args.filter((a) => a !== '--check');
  if (unknown.length) {
    console.error(`Unknown option: ${unknown.join(' ')} (see --help)`);
    process.exit(1);
  }
  const check = args.includes('--check');
  const out = renderAll();
  let stale = 0;
  if (!check) fs.mkdirSync(OUT_DIR, { recursive: true });
  for (const { file, svg } of out) {
    const p = path.join(OUT_DIR, file);
    if (check) {
      const cur = fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '';
      if (cur !== svg) { stale += 1; console.error(`stale: .company-os/docs/diagrams/${file}`); }
    } else {
      fs.writeFileSync(p, svg, 'utf8');
      console.log(`wrote .company-os/docs/diagrams/${file}`);
    }
  }
  if (check) {
    if (stale) { console.error(`${stale} diagram(s) out of date. Run: node docs/diagrams/render.js`); process.exit(1); }
    console.log(`All ${out.length} diagrams are up to date.`);
  }
}
