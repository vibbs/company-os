#!/usr/bin/env node
// docs/diagrams/generate.js
// Generates Company OS architecture diagrams as .excalidraw files
// Usage: node docs/diagrams/generate.js
// No dependencies required beyond Node.js 18+

const { writeFileSync } = require('fs');
const { join } = require('path');

// ═══════════════════════════════════════════════════════════════
// Section 1: ID Factory (deterministic for clean git diffs)
// ═══════════════════════════════════════════════════════════════

let _idCounter = 0;
function uid(prefix = 'el') {
  return `${prefix}_${String(++_idCounter).padStart(5, '0')}`;
}
function resetIds() { _idCounter = 0; }

// Deterministic seed generator
let _seedCounter = 1000000;
function seed() { return ++_seedCounter; }

// ═══════════════════════════════════════════════════════════════
// Section 2: Color Palette
// ═══════════════════════════════════════════════════════════════

const C = {
  orchestrator: { bg: '#e8f4fd', stroke: '#1971c2' },
  product:      { bg: '#f3f0ff', stroke: '#6741d9' },
  engineering:  { bg: '#e6fcf5', stroke: '#087f5b' },
  backend:      { bg: '#d3f9d8', stroke: '#2b8a3e' },
  frontend:     { bg: '#fff0f6', stroke: '#a61e4d' },
  devops:       { bg: '#fff9db', stroke: '#e67700' },
  qa:           { bg: '#fff4e6', stroke: '#d9480f' },
  growth:       { bg: '#f8f0fc', stroke: '#862e9c' },
  ops:          { bg: '#fff5f5', stroke: '#c92a2a' },
  gate:         { bg: '#fff3bf', stroke: '#e67700' },
  muted:        { bg: '#f1f3f5', stroke: '#adb5bd' },
  zone_agents:  { bg: '#f0f7ff', stroke: '#d0ebff' },
  zone_skills:  { bg: '#f0fdf4', stroke: '#c3fae8' },
  zone_tools:   { bg: '#fffbf0', stroke: '#ffe8cc' },
  text:    '#1e1e1e',
  textSub: '#495057',
  textMuted: '#868e96',
  arrow:   '#495057',
  arrowDel: '#1971c2',
};

// ═══════════════════════════════════════════════════════════════
// Section 3: Element Factories
// ═══════════════════════════════════════════════════════════════

function baseProps(overrides) {
  return {
    angle: 0,
    strokeColor: '#1e1e1e',
    backgroundColor: 'transparent',
    fillStyle: 'solid',
    strokeWidth: 2,
    strokeStyle: 'solid',
    roughness: 0,
    opacity: 100,
    groupIds: [],
    frameId: null,
    roundness: null,
    seed: seed(),
    version: 1,
    versionNonce: seed(),
    isDeleted: false,
    boundElements: [],
    updated: 1709424000000,
    link: null,
    locked: false,
    ...overrides,
  };
}

function rect({ id, x, y, w, h, bg, stroke, rounded = true, opacity, strokeStyle, strokeWidth, groupIds, frameId }) {
  return {
    ...baseProps({
      strokeColor: stroke || '#1e1e1e',
      backgroundColor: bg || 'transparent',
      roundness: rounded ? { type: 3 } : null,
      opacity: opacity != null ? opacity : 100,
      strokeStyle: strokeStyle || 'solid',
      strokeWidth: strokeWidth != null ? strokeWidth : 2,
      groupIds: groupIds || [],
      frameId: frameId || null,
    }),
    id: id || uid('rect'),
    type: 'rectangle',
    x, y,
    width: w,
    height: h,
  };
}

function diamond({ id, x, y, w, h, bg, stroke, groupIds }) {
  return {
    ...baseProps({
      strokeColor: stroke || '#e67700',
      backgroundColor: bg || '#fff3bf',
      roundness: { type: 2 },
      groupIds: groupIds || [],
    }),
    id: id || uid('dia'),
    type: 'diamond',
    x, y,
    width: w,
    height: h,
  };
}

function ellipse({ id, x, y, w, h, bg, stroke, groupIds }) {
  return {
    ...baseProps({
      strokeColor: stroke || '#1e1e1e',
      backgroundColor: bg || 'transparent',
      roundness: { type: 2 },
      groupIds: groupIds || [],
    }),
    id: id || uid('ell'),
    type: 'ellipse',
    x, y,
    width: w,
    height: h,
  };
}

function textEl({ id, x, y, w, h, content, fontSize = 16, color, align = 'center', vAlign = 'middle', containerId, fontFamily = 2, groupIds, frameId }) {
  const estimatedW = w || estimateTextWidth(content, fontSize);
  const lines = content.split('\n');
  const estimatedH = h || lines.length * fontSize * 1.25;
  return {
    ...baseProps({
      strokeColor: color || C.text,
      groupIds: groupIds || [],
      frameId: frameId || null,
    }),
    id: id || uid('txt'),
    type: 'text',
    x, y,
    width: estimatedW,
    height: estimatedH,
    text: content,
    fontSize,
    fontFamily,
    textAlign: align,
    verticalAlign: vAlign,
    containerId: containerId || null,
    originalText: content,
    autoResize: true,
    lineHeight: 1.25,
    boundElements: null,
  };
}

function arrow({ id, x, y, points, fromId, toId, color, strokeStyle, strokeWidth, endArrowhead = 'arrow', startArrowhead = null, groupIds }) {
  const a = {
    ...baseProps({
      strokeColor: color || C.arrow,
      strokeStyle: strokeStyle || 'solid',
      strokeWidth: strokeWidth != null ? strokeWidth : 2,
      roundness: { type: 2 },
      groupIds: groupIds || [],
    }),
    id: id || uid('arr'),
    type: 'arrow',
    x, y,
    width: Math.abs(points[points.length - 1][0]),
    height: Math.abs(points[points.length - 1][1]),
    points,
    lastCommittedPoint: null,
    startBinding: fromId ? { elementId: fromId, focus: 0, gap: 6, fixedPoint: null } : null,
    endBinding: toId ? { elementId: toId, focus: 0, gap: 6, fixedPoint: null } : null,
    startArrowhead,
    endArrowhead,
  };
  return a;
}

// ═══════════════════════════════════════════════════════════════
// Section 4: Layout Helpers
// ═══════════════════════════════════════════════════════════════

function estimateTextWidth(text, fontSize) {
  const lines = text.split('\n');
  const longest = lines.reduce((a, b) => a.length > b.length ? a : b, '');
  return Math.ceil(longest.length * fontSize * 0.55);
}

/** Create a labeled box (rect + bound text label). Returns [rectEl, textEl]. */
function labeledBox({ id, x, y, w, h, bg, stroke, label, fontSize = 16, textColor, rounded = true, opacity, groupIds }) {
  const rId = id || uid('box');
  const tId = uid('lbl');
  const r = rect({ id: rId, x, y, w, h, bg, stroke, rounded, opacity, groupIds });
  const tw = estimateTextWidth(label, fontSize);
  const lines = label.split('\n');
  const th = lines.length * fontSize * 1.25;
  const t = textEl({
    id: tId,
    x: x + (w - tw) / 2,
    y: y + (h - th) / 2,
    w: tw,
    h: th,
    content: label,
    fontSize,
    color: textColor || C.text,
    containerId: rId,
    groupIds,
  });
  r.boundElements.push({ id: tId, type: 'text' });
  return [r, t];
}

/** Create a labeled diamond. Returns [diamondEl, textEl]. */
function labeledDiamond({ id, x, y, w, h, bg, stroke, label, fontSize = 12, textColor, groupIds }) {
  const dId = id || uid('gdia');
  const tId = uid('glbl');
  const d = diamond({ id: dId, x, y, w, h, bg, stroke, groupIds });
  const tw = estimateTextWidth(label, fontSize);
  const th = fontSize * 1.25;
  const t = textEl({
    id: tId,
    x: x + (w - tw) / 2,
    y: y + (h - th) / 2,
    w: tw,
    h: th,
    content: label,
    fontSize,
    color: textColor || C.text,
    containerId: dId,
    groupIds,
  });
  d.boundElements.push({ id: tId, type: 'text' });
  return [d, t];
}

/** Connect two elements with an arrow. Mutates both elements' boundElements. */
function connect(fromEl, toEl, opts = {}) {
  const fromPt = resolveAttachPoint(fromEl, opts.fromSide || 'bottom');
  const toPt = resolveAttachPoint(toEl, opts.toSide || 'top');
  const dx = toPt.x - fromPt.x;
  const dy = toPt.y - fromPt.y;

  let pts;
  if (opts.elbowMid != null) {
    // L-shaped elbow: go down to mid, then sideways, then down
    const midY = opts.elbowMid - fromPt.y;
    pts = [[0, 0], [0, midY], [dx, midY], [dx, dy]];
  } else if (opts.points) {
    pts = opts.points;
  } else {
    pts = [[0, 0], [dx, dy]];
  }

  const a = arrow({
    id: opts.id,
    x: fromPt.x,
    y: fromPt.y,
    points: pts,
    fromId: fromEl.id,
    toId: toEl.id,
    color: opts.color || C.arrow,
    strokeStyle: opts.strokeStyle,
    strokeWidth: opts.strokeWidth,
    endArrowhead: opts.endArrowhead != null ? opts.endArrowhead : 'arrow',
    startArrowhead: opts.startArrowhead || null,
    groupIds: opts.groupIds,
  });

  fromEl.boundElements = fromEl.boundElements || [];
  toEl.boundElements = toEl.boundElements || [];
  fromEl.boundElements.push({ id: a.id, type: 'arrow' });
  toEl.boundElements.push({ id: a.id, type: 'arrow' });

  return a;
}

function resolveAttachPoint(el, side) {
  const cx = el.x + el.width / 2;
  const cy = el.y + el.height / 2;
  switch (side) {
    case 'top':    return { x: cx, y: el.y };
    case 'bottom': return { x: cx, y: el.y + el.height };
    case 'left':   return { x: el.x, y: cy };
    case 'right':  return { x: el.x + el.width, y: cy };
    case 'center': return { x: cx, y: cy };
    default:       return { x: cx, y: cy };
  }
}

/** Standalone text (not bound to any shape) */
function freeText({ x, y, content, fontSize = 14, color, align = 'left', fontFamily = 2, groupIds }) {
  return textEl({ x, y, content, fontSize, color: color || C.textSub, align, fontFamily, groupIds });
}

// ═══════════════════════════════════════════════════════════════
// Section 5: Diagram Builders
// ═══════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// DIAGRAM 1: High-Level Agent Architecture
// ───────────────────────────────────────────────────────────────
function buildAgentArchitecture() {
  resetIds();
  _seedCounter = 1000000;
  const els = [];

  // ── Background zones ──
  const zoneW = 1800;
  const agentZoneH = 760;
  const skillZoneH = 170;
  const toolZoneH = 170;

  els.push(rect({ x: 0, y: 0, w: zoneW, h: agentZoneH, bg: C.zone_agents.bg, stroke: C.zone_agents.stroke, strokeWidth: 1, opacity: 60, rounded: false }));
  els.push(rect({ x: 0, y: agentZoneH, w: zoneW, h: skillZoneH, bg: C.zone_skills.bg, stroke: C.zone_skills.stroke, strokeWidth: 1, opacity: 60, rounded: false }));
  els.push(rect({ x: 0, y: agentZoneH + skillZoneH, w: zoneW, h: toolZoneH, bg: C.zone_tools.bg, stroke: C.zone_tools.stroke, strokeWidth: 1, opacity: 60, rounded: false }));

  // ── Zone labels ──
  els.push(freeText({ x: 20, y: 15, content: 'AGENTS (Authority)', fontSize: 18, color: C.orchestrator.stroke }));
  els.push(freeText({ x: 20, y: agentZoneH + 10, content: 'SKILLS (Procedural) — 62 skills', fontSize: 16, color: '#087f5b' }));
  els.push(freeText({ x: 20, y: agentZoneH + skillZoneH + 10, content: 'TOOLS (Execution) — 31 scripts', fontSize: 16, color: '#e67700' }));

  // Layer description texts
  els.push(freeText({ x: 1300, y: 15, content: 'Choose what happens next', fontSize: 13, color: C.textMuted }));
  els.push(freeText({ x: 1300, y: agentZoneH + 10, content: 'Advise + produce artifacts', fontSize: 13, color: C.textMuted }));
  els.push(freeText({ x: 1300, y: agentZoneH + skillZoneH + 10, content: 'Execute deterministic actions', fontSize: 13, color: C.textMuted }));

  // ── Orchestrator ──
  const [orchBox, orchLbl] = labeledBox({
    id: 'orch', x: 630, y: 60, w: 540, h: 90,
    bg: C.orchestrator.bg, stroke: C.orchestrator.stroke,
    label: 'Orchestrator Agent', fontSize: 22,
  });
  els.push(orchBox, orchLbl);
  els.push(freeText({ x: 650, y: 155, content: 'opus · 15 skills · Routes, gates, approves releases', fontSize: 12, color: C.textSub }));

  // ── Five leaf agents (row) ──
  const agentY = 260;
  const agentH = 110;
  const agentGap = 30;

  const agents = [
    { id: 'prod', label: 'Product\nAgent', color: C.product, sub: 'sonnet · 8 skills', desc: 'PRDs, ICP, feedback' },
    { id: 'eng',  label: 'Engineering\nAgent (Staff)', color: C.engineering, sub: 'opus · 5 skills', desc: 'RFC, architecture, delegation' },
    { id: 'qa',   label: 'QA & Release\nAgent', color: C.qa, sub: 'sonnet · 9 skills', desc: 'Test plans, release gates' },
    { id: 'grow', label: 'Growth\nAgent', color: C.growth, sub: 'sonnet · 8 skills', desc: 'Launch, SEO, activation' },
    { id: 'risk', label: 'Ops & Risk\nAgent', color: C.ops, sub: 'sonnet · 9 skills', desc: 'Security, compliance, costs' },
  ];

  const agentW = 280;
  const totalW = agents.length * agentW + (agents.length - 1) * agentGap;
  const startX = (zoneW - totalW) / 2;

  const agentEls = {};
  agents.forEach((a, i) => {
    const x = startX + i * (agentW + agentGap);
    const [box, lbl] = labeledBox({
      id: a.id, x, y: agentY, w: agentW, h: agentH,
      bg: a.color.bg, stroke: a.color.stroke,
      label: a.label, fontSize: 18,
    });
    els.push(box, lbl);
    els.push(freeText({ x: x + 10, y: agentY + agentH + 6, content: a.sub, fontSize: 11, color: C.textMuted }));
    els.push(freeText({ x: x + 10, y: agentY + agentH + 22, content: a.desc, fontSize: 11, color: C.textMuted }));
    agentEls[a.id] = box;
  });

  // ── Arrows: Orchestrator → leaf agents ──
  for (const key of Object.keys(agentEls)) {
    els.push(connect(orchBox, agentEls[key], { color: C.arrowDel, strokeWidth: 2 }));
  }

  // ── Engineering sub-agents ──
  const subY = 460;
  const subH = 90;
  const subW = 240;
  const subGap = 40;
  const engCx = agentEls['eng'].x + agentEls['eng'].width / 2;
  const subTotalW = 3 * subW + 2 * subGap;
  const subStartX = engCx - subTotalW / 2;

  const subs = [
    { id: 'be', label: 'Backend\nEngineer', color: C.backend, sub: 'sonnet · 4 skills', desc: 'API, DB, jobs' },
    { id: 'fe', label: 'Frontend\nEngineer', color: C.frontend, sub: 'sonnet · 4 skills', desc: 'UI, components, docs' },
    { id: 'do', label: 'DevOps\nEngineer', color: C.devops, sub: 'sonnet · 5 skills', desc: 'CI/CD, infra, flags' },
  ];

  const subEls = {};
  subs.forEach((s, i) => {
    const x = subStartX + i * (subW + subGap);
    const [box, lbl] = labeledBox({
      id: s.id, x, y: subY, w: subW, h: subH,
      bg: s.color.bg, stroke: s.color.stroke,
      label: s.label, fontSize: 16,
    });
    els.push(box, lbl);
    els.push(freeText({ x: x + 8, y: subY + subH + 4, content: s.sub, fontSize: 11, color: C.textMuted }));
    els.push(freeText({ x: x + 8, y: subY + subH + 18, content: s.desc, fontSize: 11, color: C.textMuted }));
    subEls[s.id] = box;
  });

  // ── Arrows: Engineering → sub-agents ──
  for (const key of Object.keys(subEls)) {
    els.push(connect(agentEls['eng'], subEls[key], { color: '#087f5b', strokeStyle: 'dashed' }));
  }

  // ── "Task tool" annotation ──
  els.push(freeText({ x: engCx - 50, y: agentY + agentH + 40, content: '↓ Task tool (delegates)', fontSize: 12, color: '#087f5b' }));

  // ── Skills row (representative pills by namespace) ──
  const skillsY = agentZoneH + 40;
  const pillH = 28;
  const pillGap = 8;
  const skills = [
    { label: 'prd-writer', color: C.product },
    { label: 'icp-positioning', color: C.product },
    { label: 'feedback-synthesizer', color: C.product },
    { label: 'architecture-draft', color: C.engineering },
    { label: 'api-contract-designer', color: C.backend },
    { label: 'design-system', color: C.frontend },
    { label: 'deployment-strategy', color: C.devops },
    { label: 'test-plan-generator', color: C.qa },
    { label: 'release-readiness-gate', color: C.qa },
    { label: 'dogfood', color: C.qa },
    { label: 'positioning-messaging', color: C.growth },
    { label: 'landing-page-copy', color: C.growth },
    { label: 'threat-modeling', color: C.ops },
    { label: 'compliance-readiness', color: C.ops },
    { label: 'ship', color: C.orchestrator },
    { label: 'workflow-router', color: C.orchestrator },
  ];

  let sx = 40;
  skills.forEach((s) => {
    const pw = estimateTextWidth(s.label, 11) + 16;
    const [pill, pLbl] = labeledBox({
      x: sx, y: skillsY, w: pw, h: pillH,
      bg: s.color.bg, stroke: s.color.stroke,
      label: s.label, fontSize: 11, strokeWidth: 1,
    });
    pill.strokeWidth = 1;
    els.push(pill, pLbl);
    sx += pw + pillGap;
  });
  els.push(freeText({ x: sx + 10, y: skillsY + 4, content: '...and 46 more', fontSize: 12, color: C.textMuted }));

  // ── Tools row (representative) ──
  const toolsY = agentZoneH + skillZoneH + 40;
  const tools = [
    'validate.sh', 'link.sh', 'promote.sh', 'check-gate.sh',
    'run-tests.sh', 'lint-format.sh', 'dependency-scan.sh',
    'pre-deploy.sh', 'smoke-test.sh', 'posture-check.sh',
    'token-ledger.sh', 'dashboard.sh', 'version-bump.sh',
  ];
  let tx = 40;
  tools.forEach((t) => {
    const tw = estimateTextWidth(t, 11) + 16;
    const [pill, pLbl] = labeledBox({
      x: tx, y: toolsY, w: tw, h: pillH,
      bg: C.zone_tools.bg, stroke: '#d9480f',
      label: t, fontSize: 11, strokeWidth: 1,
    });
    pill.strokeWidth = 1;
    els.push(pill, pLbl);
    tx += tw + pillGap;
  });
  els.push(freeText({ x: tx + 10, y: toolsY + 4, content: '...and 18 more', fontSize: 12, color: C.textMuted }));

  // ── Dependency arrows between layers ──
  els.push(freeText({ x: zoneW - 280, y: agentZoneH - 25, content: 'Agents → Skills (how to think)', fontSize: 11, color: C.textMuted }));
  els.push(freeText({ x: zoneW - 280, y: agentZoneH + skillZoneH - 25, content: 'Agents → Tools (how to act)', fontSize: 11, color: C.textMuted }));

  // ── Title ──
  els.push(freeText({ x: zoneW / 2 - 200, y: -50, content: 'Company OS — Three-Layer Agent Architecture', fontSize: 24, color: C.text }));

  // ── Artifacts annotation ──
  els.push(freeText({ x: zoneW / 2 - 100, y: agentZoneH + skillZoneH + toolZoneH + 20, content: 'Artifacts are the handshake between all layers', fontSize: 14, color: C.textSub }));

  return els;
}

// ───────────────────────────────────────────────────────────────
// DIAGRAM 2: Ship Flow Pipeline
// ───────────────────────────────────────────────────────────────
function buildShipFlow() {
  resetIds();
  _seedCounter = 2000000;
  const els = [];

  const mainY = 340;
  const nodeH = 70;
  const nodeW = 170;
  const gateW = 55;
  const gateH = 55;
  const gap = 20;

  // Title
  els.push(freeText({ x: 50, y: 20, content: 'Company OS — Ship Flow Pipeline', fontSize: 24, color: C.text }));
  els.push(freeText({ x: 50, y: 55, content: '/ship "describe what you want to build" → Orchestrator kicks off the full pipeline', fontSize: 13, color: C.textSub }));

  // ── Main pipeline nodes ──
  let cx = 60;

  function stepNode(label, agent, color, w) {
    const width = w || nodeW;
    const [box, lbl] = labeledBox({
      x: cx, y: mainY, w: width, h: nodeH,
      bg: color.bg, stroke: color.stroke,
      label, fontSize: 13,
    });
    els.push(box, lbl);
    els.push(freeText({ x: cx + 4, y: mainY + nodeH + 4, content: agent, fontSize: 10, color: C.textMuted }));
    cx += width + gap;
    return box;
  }

  function gateNode(label) {
    const [d, l] = labeledDiamond({
      x: cx, y: mainY + (nodeH - gateH) / 2, w: gateW, h: gateH,
      bg: C.gate.bg, stroke: C.gate.stroke,
      label: '⬥', fontSize: 14,
    });
    els.push(d, l);
    els.push(freeText({ x: cx - 5, y: mainY + nodeH + 4, content: label, fontSize: 9, color: C.gate.stroke }));
    cx += gateW + gap;
    return d;
  }

  // Steps
  const s1 = stepNode('Step 1\nLoad Config', 'Orchestrator', C.orchestrator, 140);
  const s2 = stepNode('Step 2\nInventory', 'Orchestrator', C.orchestrator, 130);
  const s2b = stepNode('Step 2.5\nDiscovery\nValidation', 'Product', C.product, 140);
  const s3 = stepNode('Step 3\nClassify', 'Orchestrator', C.orchestrator, 120);
  const s4 = stepNode('Step 4\nExec Plan', 'Orchestrator', C.orchestrator, 130);
  const g1 = gateNode('prd-to-rfc');
  const s5prd = stepNode('PRD', 'Product Agent', C.product, 100);
  const g2 = gateNode('rfc-to-impl');
  const s5rfc = stepNode('RFC +\nAPI Contract', 'Engineering', C.engineering, 130);
  const g3 = gateNode('impl-to-qa');
  const s5impl = stepNode('Step 5\nImplement', 'Engineering', C.engineering, 140);
  const s57 = stepNode('Step 5.7\nUser Docs', 'Eng/Frontend', C.frontend, 130);
  const s58 = stepNode('Step 5.8\nSeed &\nVerify', 'Orchestrator', C.orchestrator, 120);
  const g4 = gateNode('release');
  const s6 = stepNode('Step 6\nRelease\nGate', 'Orchestrator + QA', C.qa, 130);
  const s7 = stepNode('Step 7\nRelease\nSummary', 'Orchestrator', C.orchestrator, 130);
  const s8 = stepNode('Step 8\nWhat\'s Next', 'Orchestrator', C.muted, 120);

  // ── Connect main pipeline ──
  const mainNodes = [s1, s2, s2b, s3, s4, g1, s5prd, g2, s5rfc, g3, s5impl, s57, s58, g4, s6, s7, s8];
  for (let i = 0; i < mainNodes.length - 1; i++) {
    els.push(connect(mainNodes[i], mainNodes[i + 1], {
      fromSide: 'right', toSide: 'left',
      color: C.arrow, strokeWidth: 2,
    }));
  }

  // ── Parallel branches ──
  const parallelY = 150;

  // Threat Model (parallel with implementation, spawned after RFC)
  const [tmBox, tmLbl] = labeledBox({
    x: s5rfc.x, y: parallelY, w: 150, h: 55,
    bg: C.ops.bg, stroke: C.ops.stroke,
    label: 'Threat Model', fontSize: 13,
  });
  els.push(tmBox, tmLbl);
  els.push(freeText({ x: s5rfc.x + 4, y: parallelY + 58, content: 'Ops & Risk', fontSize: 10, color: C.textMuted }));
  els.push(connect(s5rfc, tmBox, { fromSide: 'top', toSide: 'bottom', color: C.ops.stroke, strokeStyle: 'dashed' }));

  // Test Plan (parallel with implementation)
  const [tpBox, tpLbl] = labeledBox({
    x: s5impl.x, y: parallelY, w: 140, h: 55,
    bg: C.qa.bg, stroke: C.qa.stroke,
    label: 'Test Plan', fontSize: 13,
  });
  els.push(tpBox, tpLbl);
  els.push(freeText({ x: s5impl.x + 4, y: parallelY + 58, content: 'QA Agent', fontSize: 10, color: C.textMuted }));
  els.push(connect(s5rfc, tpBox, { fromSide: 'top', toSide: 'left', color: C.qa.stroke, strokeStyle: 'dashed' }));

  // Launch Brief (parallel after PRD)
  const launchY = 530;
  const [lbBox, lbLbl] = labeledBox({
    x: s5prd.x, y: launchY, w: 150, h: 55,
    bg: C.growth.bg, stroke: C.growth.stroke,
    label: 'Launch Brief', fontSize: 13,
  });
  els.push(lbBox, lbLbl);
  els.push(freeText({ x: s5prd.x + 4, y: launchY + 58, content: 'Growth Agent', fontSize: 10, color: C.textMuted }));
  els.push(connect(s5prd, lbBox, { fromSide: 'bottom', toSide: 'top', color: C.growth.stroke, strokeStyle: 'dashed' }));

  // Dogfood (optional, between seed & release gate)
  const [dfBox, dfLbl] = labeledBox({
    x: s58.x, y: launchY, w: 130, h: 55,
    bg: C.qa.bg, stroke: C.qa.stroke,
    label: 'Step 5.9\nDogfood', fontSize: 12,
  });
  els.push(dfBox, dfLbl);
  els.push(freeText({ x: s58.x + 4, y: launchY + 58, content: 'QA (optional)', fontSize: 10, color: C.textMuted }));
  els.push(connect(s58, dfBox, { fromSide: 'bottom', toSide: 'top', color: C.qa.stroke, strokeStyle: 'dashed' }));

  // ── Parallel branch label ──
  els.push(freeText({ x: s5rfc.x - 10, y: parallelY - 30, content: '↕ Parallel branches (run concurrently)', fontSize: 12, color: C.textMuted }));

  // ── Artifact outputs ──
  const artY = mainY - 50;
  els.push(freeText({ x: s5prd.x, y: artY, content: '→ artifacts/prds/', fontSize: 10, color: C.product.stroke }));
  els.push(freeText({ x: s5rfc.x, y: artY, content: '→ artifacts/rfcs/', fontSize: 10, color: C.engineering.stroke }));
  els.push(freeText({ x: s6.x, y: artY, content: '→ artifacts/qa-reports/', fontSize: 10, color: C.qa.stroke }));

  // ── Legend ──
  els.push(freeText({ x: 60, y: 640, content: 'Legend:', fontSize: 14, color: C.text }));
  const [lgGate, lgGateLbl] = labeledDiamond({ x: 60, y: 670, w: 30, h: 30, label: '⬥', fontSize: 10 });
  els.push(lgGate, lgGateLbl);
  els.push(freeText({ x: 100, y: 672, content: '= Stage gate checkpoint', fontSize: 12, color: C.textSub }));
  els.push(freeText({ x: 60, y: 710, content: '--- = Parallel / optional branch', fontSize: 12, color: C.textSub }));

  return els;
}

// ───────────────────────────────────────────────────────────────
// DIAGRAM 3: Engineering Delegation
// ───────────────────────────────────────────────────────────────
function buildEngineeringDelegation() {
  resetIds();
  _seedCounter = 3000000;
  const els = [];

  // Title
  els.push(freeText({ x: 50, y: 20, content: 'Engineering Agent — Staff Engineer Orchestration', fontSize: 24, color: C.text }));
  els.push(freeText({ x: 50, y: 55, content: 'Owns "how". Translates PRDs into architecture, decomposes work, delegates to sub-agents.', fontSize: 13, color: C.textSub }));

  // ── Staff Engineer (center) ──
  const [staffBox, staffLbl] = labeledBox({
    id: 'staff', x: 520, y: 340, w: 280, h: 80,
    bg: C.engineering.bg, stroke: C.engineering.stroke,
    label: 'Staff Engineer\n(opus)', fontSize: 18,
  });
  els.push(staffBox, staffLbl);

  // ── 7 Phases (arranged around) ──
  const phaseW = 180;
  const phaseH = 65;

  const phases = [
    { label: '① Architecture\n→ RFC/ADR', x: 160, y: 100, color: C.engineering },
    { label: '② API Contract\nDesign', x: 480, y: 100, color: C.backend },
    { label: '③ Decompose\nby Domain', x: 800, y: 100, color: C.engineering },
    { label: '④ Delegate to\nSub-agents', x: 1020, y: 260, color: C.engineering },
    { label: '⑤ Integrate +\nResolve Conflicts', x: 1020, y: 420, color: C.engineering },
    { label: '⑥ Self-Review\n(code-review)', x: 800, y: 530, color: C.engineering },
    { label: '⑦ Handoff\nto QA', x: 480, y: 530, color: C.qa },
  ];

  const phaseEls = [];
  phases.forEach((p) => {
    const [box, lbl] = labeledBox({
      x: p.x, y: p.y, w: phaseW, h: phaseH,
      bg: p.color.bg, stroke: p.color.stroke,
      label: p.label, fontSize: 13,
    });
    els.push(box, lbl);
    phaseEls.push(box);
  });

  // ── Phase flow arrows (sequential 1→2→3→4→5→6→7) ──
  for (let i = 0; i < phaseEls.length - 1; i++) {
    const fromSide = i < 2 ? 'right' : (i === 2 ? 'bottom' : (i < 5 ? 'bottom' : 'left'));
    const toSide = i < 2 ? 'left' : (i === 2 ? 'top' : (i < 5 ? 'top' : 'right'));
    els.push(connect(phaseEls[i], phaseEls[i + 1], {
      fromSide, toSide,
      color: '#087f5b', strokeWidth: 2,
    }));
  }

  // ── Arrows from Staff Engineer to phases ──
  els.push(connect(staffBox, phaseEls[0], { fromSide: 'left', toSide: 'bottom', color: '#087f5b', strokeStyle: 'dashed' }));
  els.push(connect(staffBox, phaseEls[3], { fromSide: 'right', toSide: 'left', color: '#087f5b', strokeStyle: 'dashed' }));

  // ── Sub-agents row ──
  const subY = 680;
  const subW = 260;
  const subH = 100;
  const subGap = 60;
  const subStartX = 100;

  const subAgents = [
    { id: 'be', label: 'Backend Engineer\n(sonnet)', color: C.backend,
      skills: 'api-contract-designer\nbackground-jobs\nmulti-tenancy\nseed-data',
      scope: 'src/server/ · src/api/ · db/ · seeds/' },
    { id: 'fe', label: 'Frontend Engineer\n(sonnet)', color: C.frontend,
      skills: 'design-system\nmobile-readiness\ninstrumentation\nuser-docs',
      scope: 'src/components/ · src/pages/ · docs/' },
    { id: 'dv', label: 'DevOps Engineer\n(sonnet)', color: C.devops,
      skills: 'deployment-strategy\nobservability-baseline\nfeature-flags\ndev-environment',
      scope: '.github/ · infra/ · tools/dev/' },
  ];

  const subEls = [];
  subAgents.forEach((s, i) => {
    const x = subStartX + i * (subW + subGap);
    const [box, lbl] = labeledBox({
      id: s.id, x, y: subY, w: subW, h: subH,
      bg: s.color.bg, stroke: s.color.stroke,
      label: s.label, fontSize: 16,
    });
    els.push(box, lbl);
    els.push(freeText({ x: x + 8, y: subY + subH + 8, content: s.skills, fontSize: 11, color: C.textSub }));
    els.push(freeText({ x: x + 8, y: subY + subH + 75, content: s.scope, fontSize: 10, color: C.textMuted }));
    subEls.push(box);
  });

  // ── Phase 4 "Delegate" → sub-agents ──
  subEls.forEach(sub => {
    els.push(connect(phaseEls[3], sub, { fromSide: 'bottom', toSide: 'top', color: '#087f5b', strokeStyle: 'dashed' }));
  });

  // ── Parallel execution annotation ──
  els.push(freeText({ x: subStartX, y: subY - 35, content: 'Backend + DevOps run in parallel. Frontend waits for API contract.', fontSize: 12, color: '#e67700' }));

  // ── API Contract as shared artifact ──
  const [apiBox, apiLbl] = labeledBox({
    x: subStartX + subW + subGap / 2 - 40, y: subY + subH + 110, w: subW + subGap + 80, h: 45,
    bg: '#fff9db', stroke: '#e67700',
    label: 'API Contract — shared binding artifact', fontSize: 13,
  });
  els.push(apiBox, apiLbl);

  // Arrows from Backend + Frontend to API Contract
  els.push(connect(subEls[0], apiBox, { fromSide: 'bottom', toSide: 'top', color: '#e67700', strokeStyle: 'dashed' }));
  els.push(connect(subEls[1], apiBox, { fromSide: 'bottom', toSide: 'top', color: '#e67700', strokeStyle: 'dashed' }));

  // ── Staff Engineer skills ──
  els.push(freeText({ x: 520, y: 425, content: 'Skills: architecture-draft · implementation-decomposer · code-review · conflict-resolver · ai-engineering', fontSize: 11, color: C.textMuted }));

  return els;
}

// ───────────────────────────────────────────────────────────────
// DIAGRAM 4: Artifact Lineage & Gates
// ───────────────────────────────────────────────────────────────
function buildArtifactLineage() {
  resetIds();
  _seedCounter = 4000000;
  const els = [];

  // Title
  els.push(freeText({ x: 50, y: 20, content: 'Artifact Lineage & Stage Gates', fontSize: 24, color: C.text }));
  els.push(freeText({ x: 50, y: 55, content: 'Every artifact has YAML frontmatter with id, type, title, status, created, author. Lineage via parent/children/depends_on.', fontSize: 13, color: C.textSub }));

  // ── Status lifecycle (top row) ──
  const statusY = 100;
  const statusW = 130;
  const statusH = 45;
  const statusGap = 60;
  const statusStartX = 450;

  const statuses = [
    { label: 'draft', bg: '#f8f9fa', stroke: '#868e96' },
    { label: 'review', bg: '#fff9db', stroke: '#e67700' },
    { label: 'approved', bg: '#ebfbee', stroke: '#2b8a3e' },
    { label: 'archived', bg: '#e9ecef', stroke: '#adb5bd' },
  ];

  const statusEls = [];
  statuses.forEach((s, i) => {
    const x = statusStartX + i * (statusW + statusGap);
    const [box, lbl] = labeledBox({ x, y: statusY, w: statusW, h: statusH, bg: s.bg, stroke: s.stroke, label: s.label, fontSize: 14 });
    els.push(box, lbl);
    statusEls.push(box);
  });

  // Status arrows
  for (let i = 0; i < statusEls.length - 1; i++) {
    const a = connect(statusEls[i], statusEls[i + 1], { fromSide: 'right', toSide: 'left', color: '#495057' });
    els.push(a);
  }
  els.push(freeText({ x: statusStartX - 130, y: statusY + 10, content: 'Status lifecycle →', fontSize: 14, color: C.textSub }));
  els.push(freeText({ x: statusStartX + statusW / 2 - 20, y: statusY + statusH + 6, content: 'promote.sh', fontSize: 10, color: C.textMuted }));

  // ── Vertical artifact pipeline ──
  const pipeX = 200;
  const artW = 220;
  const artH = 55;
  const artGap = 30;
  let artY = 220;

  const gateX = 500;
  const gateW2 = 360;
  const gateH2 = 50;

  const artifacts = [
    { label: 'PRD', agent: 'Product Agent', dir: 'artifacts/prds/', color: C.product },
    { label: 'RFC / ADR', agent: 'Engineering Agent', dir: 'artifacts/rfcs/', color: C.engineering },
    { label: 'Security Review', agent: 'Ops & Risk Agent', dir: 'artifacts/security-reviews/', color: C.ops },
    { label: 'Test Plan', agent: 'QA & Release Agent', dir: 'artifacts/test-plans/', color: C.qa },
    { label: 'QA Report', agent: 'QA & Release Agent', dir: 'artifacts/qa-reports/', color: C.qa },
    { label: 'Launch Brief', agent: 'Growth Agent', dir: 'artifacts/launch-briefs/', color: C.growth },
  ];

  const gates = [
    { afterIdx: 0, label: 'Gate: prd-to-rfc', checks: 'PRD approved + acceptance criteria present' },
    { afterIdx: 1, label: 'Gate: rfc-to-impl', checks: 'RFC approved + parent PRD approved' },
    { afterIdx: 3, label: 'Gate: impl-to-qa', checks: 'RFC approved + test plan exists' },
    { afterIdx: 5, label: 'Gate: release', checks: 'All artifacts approved + version bumped' },
  ];

  const artEls = [];
  let currentY = artY;
  artifacts.forEach((a, i) => {
    // Check if there's a gate before this artifact
    const gateBefore = gates.find(g => g.afterIdx === i - 1);
    if (gateBefore) {
      // Draw gate
      const [gBox, gLbl] = labeledBox({
        x: gateX, y: currentY, w: gateW2, h: gateH2,
        bg: C.gate.bg, stroke: C.gate.stroke,
        label: gateBefore.label, fontSize: 13,
      });
      els.push(gBox, gLbl);
      els.push(freeText({ x: gateX + 4, y: currentY + gateH2 + 2, content: gateBefore.checks, fontSize: 10, color: C.gate.stroke }));
      currentY += gateH2 + artGap;
    }

    const [box, lbl] = labeledBox({
      x: pipeX, y: currentY, w: artW, h: artH,
      bg: a.color.bg, stroke: a.color.stroke,
      label: a.label, fontSize: 15,
    });
    els.push(box, lbl);
    els.push(freeText({ x: pipeX + artW + 15, y: currentY + 5, content: a.agent, fontSize: 11, color: C.textSub }));
    els.push(freeText({ x: pipeX + artW + 15, y: currentY + 22, content: a.dir, fontSize: 10, color: C.textMuted }));
    artEls.push(box);
    currentY += artH + artGap;
  });

  // Draw last gate
  const lastGate = gates[gates.length - 1];
  const [lgBox, lgLbl] = labeledBox({
    x: gateX, y: currentY, w: gateW2, h: gateH2,
    bg: C.gate.bg, stroke: C.gate.stroke,
    label: lastGate.label, fontSize: 13,
  });
  els.push(lgBox, lgLbl);
  els.push(freeText({ x: gateX + 4, y: currentY + gateH2 + 2, content: lastGate.checks, fontSize: 10, color: C.gate.stroke }));

  // ── Connect artifacts vertically ──
  for (let i = 0; i < artEls.length - 1; i++) {
    els.push(connect(artEls[i], artEls[i + 1], { color: '#495057' }));
  }

  // ── Lineage annotations ──
  els.push(freeText({ x: pipeX - 180, y: artY + artH + 10, content: 'parent →\nchild ↓\ndepends_on →', fontSize: 11, color: C.textMuted }));

  // ── Enforcement chain (bottom) ──
  const chainY = currentY + gateH2 + 60;
  els.push(freeText({ x: 100, y: chainY - 30, content: 'Enforcement Chain', fontSize: 18, color: C.text }));

  const chainW = 170;
  const chainH = 50;
  const chainGap = 40;
  const chainStartX = 100;
  const chainSteps = [
    { label: 'validate.sh', desc: 'Check frontmatter\n+ references' },
    { label: 'link.sh', desc: 'Wire parent↔child\nbidirectionally' },
    { label: 'promote.sh', desc: 'Status transitions\ndraft→review→approved' },
    { label: 'check-gate.sh', desc: 'Stage gate checks\n(PRD/RFC approval)' },
  ];

  const chainEls = [];
  chainSteps.forEach((s, i) => {
    const x = chainStartX + i * (chainW + chainGap);
    const [box, lbl] = labeledBox({
      x, y: chainY, w: chainW, h: chainH,
      bg: '#f8f9fa', stroke: '#495057',
      label: s.label, fontSize: 14,
    });
    els.push(box, lbl);
    els.push(freeText({ x: x + 4, y: chainY + chainH + 6, content: s.desc, fontSize: 10, color: C.textMuted }));
    chainEls.push(box);
  });

  for (let i = 0; i < chainEls.length - 1; i++) {
    els.push(connect(chainEls[i], chainEls[i + 1], { fromSide: 'right', toSide: 'left', color: '#495057' }));
  }

  // ── Stage awareness table ──
  const tableY = chainY + chainH + 70;
  els.push(freeText({ x: 100, y: tableY, content: 'Stage-Aware Enforcement:', fontSize: 14, color: C.text }));
  els.push(freeText({ x: 100, y: tableY + 25, content: 'idea = all advisory  |  mvp = core gates enforced  |  growth/scale = all enforced', fontSize: 12, color: C.textSub }));

  return els;
}

// ───────────────────────────────────────────────────────────────
// DIAGRAM 5: Feedback & Inbound Loop
// ───────────────────────────────────────────────────────────────
function buildFeedbackLoop() {
  resetIds();
  _seedCounter = 5000000;
  const els = [];

  // Title
  els.push(freeText({ x: 50, y: 20, content: 'Customer Feedback → Product Pipeline', fontSize: 24, color: C.text }));
  els.push(freeText({ x: 50, y: 55, content: 'The inbound loop: customer conversations feed feedback synthesis, which generates PRD candidates for the ship flow.', fontSize: 13, color: C.textSub }));

  // ── Input: 6 Conversation Types ──
  const inputX = 60;
  const inputY = 130;
  const inputW = 140;
  const inputH = 38;
  const inputGap = 8;

  const convTypes = ['Discovery', 'Demo', 'Churn-save', 'Upsell', 'Check-in', 'Cold outreach'];

  const inputEls = [];
  convTypes.forEach((t, i) => {
    const y = inputY + i * (inputH + inputGap);
    const [box, lbl] = labeledBox({
      x: inputX, y, w: inputW, h: inputH,
      bg: '#f3f0ff', stroke: '#6741d9',
      label: t, fontSize: 12, strokeWidth: 1,
    });
    els.push(box, lbl);
    inputEls.push(box);
  });

  els.push(freeText({ x: inputX, y: inputY - 25, content: '6 Conversation Types', fontSize: 14, color: C.product.stroke }));

  // ── Customer Conversations Skill ──
  const ccX = 280;
  const ccY = inputY + 60;
  const [ccBox, ccLbl] = labeledBox({
    x: ccX, y: ccY, w: 200, h: 80,
    bg: C.product.bg, stroke: C.product.stroke,
    label: 'Customer\nConversations\n(S-PROD-08)', fontSize: 13,
  });
  els.push(ccBox, ccLbl);

  // Arrows from conversation types → CC skill
  inputEls.forEach(el => {
    els.push(connect(el, ccBox, { fromSide: 'right', toSide: 'left', color: '#6741d9', strokeWidth: 1 }));
  });

  // ── CONV- Artifact ──
  const [convArt, convArtLbl] = labeledBox({
    x: ccX + 20, y: ccY + 100, w: 160, h: 40,
    bg: '#f8f9fa', stroke: '#868e96',
    label: 'CONV- artifacts', fontSize: 12,
  });
  els.push(convArt, convArtLbl);
  els.push(connect(ccBox, convArt, { color: '#6741d9', strokeWidth: 1 }));
  els.push(freeText({ x: ccX + 20, y: ccY + 145, content: 'artifacts/decision-memos/', fontSize: 10, color: C.textMuted }));

  // ── Signal Routing ──
  const sigX = 560;
  const sigY = inputY + 20;

  const signals = [
    { label: 'churn_signal', target: 'Support\nOperations', targetColor: C.ops, ty: sigY },
    { label: 'icp_signal', target: 'ICP\nPositioning', targetColor: C.product, ty: sigY + 100 },
    { label: 'prd_evidence', target: 'Feedback\nSynthesizer', targetColor: C.product, ty: sigY + 200 },
  ];

  const signalTargets = [];
  signals.forEach((s) => {
    // Signal label
    els.push(freeText({ x: sigX, y: s.ty + 12, content: s.label, fontSize: 11, color: C.textMuted }));

    // Target box
    const [tBox, tLbl] = labeledBox({
      x: sigX + 130, y: s.ty, w: 160, h: 55,
      bg: s.targetColor.bg, stroke: s.targetColor.stroke,
      label: s.target, fontSize: 13,
    });
    els.push(tBox, tLbl);
    signalTargets.push(tBox);
  });

  // Arrow from CC skill to signal area
  els.push(connect(ccBox, signalTargets[0], { fromSide: 'right', toSide: 'left', color: C.ops.stroke, strokeStyle: 'dashed' }));
  els.push(connect(ccBox, signalTargets[1], { fromSide: 'right', toSide: 'left', color: C.product.stroke, strokeStyle: 'dashed' }));
  els.push(connect(ccBox, signalTargets[2], { fromSide: 'right', toSide: 'left', color: C.product.stroke }));

  // ── Feedback Synthesizer detail ──
  const fsBox = signalTargets[2]; // Feedback Synthesizer

  // Scoring thresholds
  const scoreX = sigX + 330;
  const scoreY = sigY + 180;

  const scores = [
    { label: 'Score > 15\n→ /ship', bg: '#ebfbee', stroke: '#2b8a3e' },
    { label: 'Score 8–15\n→ /discovery', bg: '#fff9db', stroke: '#e67700' },
    { label: 'Score < 8\n→ monitor', bg: '#f8f9fa', stroke: '#868e96' },
  ];

  const scoreEls = [];
  scores.forEach((s, i) => {
    const y = scoreY + i * 65;
    const [box, lbl] = labeledBox({
      x: scoreX, y, w: 150, h: 50,
      bg: s.bg, stroke: s.stroke,
      label: s.label, fontSize: 12,
    });
    els.push(box, lbl);
    scoreEls.push(box);
  });

  els.push(freeText({ x: scoreX, y: scoreY - 25, content: 'PRD Candidates Scoring', fontSize: 14, color: C.text }));

  // Arrow from Feedback Synthesizer to scoring
  scoreEls.forEach(s => {
    els.push(connect(fsBox, s, { fromSide: 'right', toSide: 'left', color: '#495057', strokeWidth: 1 }));
  });

  // ── Sprint Prioritizer ──
  const [spBox, spLbl] = labeledBox({
    x: scoreX + 190, y: scoreY - 30, w: 160, h: 50,
    bg: C.product.bg, stroke: C.product.stroke,
    label: 'Sprint\nPrioritizer', fontSize: 13,
  });
  els.push(spBox, spLbl);

  // ── PRD Writer → Ship ──
  const [prdBox, prdLbl] = labeledBox({
    x: scoreX + 190, y: scoreY + 50, w: 160, h: 50,
    bg: C.product.bg, stroke: C.product.stroke,
    label: 'PRD Writer\n→ /ship', fontSize: 13,
  });
  els.push(prdBox, prdLbl);

  els.push(connect(scoreEls[0], prdBox, { fromSide: 'right', toSide: 'left', color: '#2b8a3e' }));
  els.push(connect(fsBox, spBox, { fromSide: 'right', toSide: 'left', color: '#6741d9', strokeStyle: 'dashed' }));

  // ── Full pipeline label ──
  els.push(freeText({ x: scoreX + 190, y: scoreY + 110, content: 'Feeds into the Ship Flow →', fontSize: 12, color: C.textSub }));

  return els;
}

// ───────────────────────────────────────────────────────────────
// DIAGRAM 6: Workflow Router Decision Tree
// ───────────────────────────────────────────────────────────────
function buildWorkflowRouter() {
  resetIds();
  _seedCounter = 6000000;
  const els = [];

  // Title
  els.push(freeText({ x: 50, y: 20, content: 'Workflow Router — 9 Objective Classifications', fontSize: 24, color: C.text }));
  els.push(freeText({ x: 50, y: 55, content: 'The Orchestrator classifies every objective and selects the appropriate pipeline.', fontSize: 13, color: C.textSub }));

  // ── Input ──
  const [inputBox, inputLbl] = labeledBox({
    x: 750, y: 100, w: 200, h: 50,
    bg: '#e8f4fd', stroke: '#1971c2',
    label: 'User Objective', fontSize: 16,
  });
  els.push(inputBox, inputLbl);

  // ── Workflow Router ──
  const [routerBox, routerLbl] = labeledBox({
    id: 'router', x: 700, y: 190, w: 300, h: 60,
    bg: C.orchestrator.bg, stroke: C.orchestrator.stroke,
    label: 'Workflow Router (classify)', fontSize: 16,
  });
  els.push(routerBox, routerLbl);
  els.push(connect(inputBox, routerBox, { color: C.arrowDel }));

  // ── 9 Classifications ──
  const classY = 320;
  const colW = 165;
  const colH = 55;
  const colGap = 15;
  const stepW = colW;
  const stepH = 30;
  const stepGap = 6;

  const classifications = [
    {
      label: 'New Feature', color: C.product,
      steps: ['PRD', 'RFC', 'Build', 'Test', 'Release'],
      skips: [],
    },
    {
      label: 'Bug Fix', color: C.ops,
      steps: ['Triage', 'Fix', 'Test', 'Release'],
      skips: ['PRD', 'RFC', 'Growth'],
    },
    {
      label: 'Improvement', color: C.engineering,
      steps: ['Mini-PRD', 'RFC?', 'Build', 'Test', 'Release'],
      skips: ['RFC optional'],
    },
    {
      label: 'Research\n/ Spike', color: C.orchestrator,
      steps: ['Research', 'Decision Memo'],
      skips: ['PRD', 'RFC', 'Build', 'QA'],
    },
    {
      label: 'Launch', color: C.growth,
      steps: ['QA Gate', 'Growth Assets', 'Release'],
      skips: ['PRD', 'RFC', 'Build'],
    },
    {
      label: 'Compliance', color: C.ops,
      steps: ['Risk Review', 'Remediate', 'Verify'],
      skips: ['PRD', 'Growth'],
    },
    {
      label: 'Prototype\n/ Demo', color: C.product,
      steps: ['Mini-PRD', 'Build', 'Demo Script'],
      skips: ['RFC', 'Security', 'QA'],
    },
    {
      label: 'Refactor\n/ Tech Debt', color: C.engineering,
      steps: ['RFC?', 'Build', 'Test', 'Release'],
      skips: ['PRD', 'Growth', 'Ops'],
    },
    {
      label: 'Dependency\nUpgrade', color: C.engineering,
      steps: ['Scan', 'RFC?', 'Build', 'Test'],
      skips: ['PRD', 'Growth'],
    },
  ];

  const totalColW = classifications.length * colW + (classifications.length - 1) * colGap;
  const colStartX = (1700 - totalColW) / 2;

  const classEls = [];
  classifications.forEach((c, i) => {
    const x = colStartX + i * (colW + colGap);

    // Classification header
    const [box, lbl] = labeledBox({
      x, y: classY, w: colW, h: colH,
      bg: c.color.bg, stroke: c.color.stroke,
      label: c.label, fontSize: 12,
    });
    els.push(box, lbl);
    classEls.push(box);

    // Pipeline steps
    let sy = classY + colH + 15;
    c.steps.forEach((step) => {
      const isOptional = step.includes('?');
      const [sBox, sLbl] = labeledBox({
        x: x + 5, y: sy, w: stepW - 10, h: stepH,
        bg: isOptional ? '#fff9db' : c.color.bg,
        stroke: isOptional ? '#e67700' : c.color.stroke,
        label: step, fontSize: 11,
        strokeWidth: 1,
      });
      els.push(sBox, sLbl);
      sy += stepH + stepGap;
    });

    // Skipped steps
    if (c.skips.length > 0) {
      sy += 5;
      els.push(freeText({ x: x + 5, y: sy, content: 'Skips:', fontSize: 10, color: C.textMuted }));
      sy += 16;
      c.skips.forEach((skip) => {
        const [skBox, skLbl] = labeledBox({
          x: x + 5, y: sy, w: stepW - 10, h: stepH - 4,
          bg: '#f1f3f5', stroke: '#adb5bd',
          label: skip, fontSize: 10,
          strokeWidth: 1,
        });
        skBox.opacity = 60;
        els.push(skBox, skLbl);
        sy += stepH;
      });
    }
  });

  // ── Arrows from Router → classifications ──
  classEls.forEach(el => {
    els.push(connect(routerBox, el, { color: C.arrowDel, strokeWidth: 1 }));
  });

  // ── Stage gate note ──
  els.push(freeText({ x: 50, y: classY + colH + 300, content: 'Stage gates (idea/mvp/growth/scale) control enforcement level. In idea stage, all gates are advisory.', fontSize: 13, color: C.textSub }));

  // ── Step 0 note ──
  els.push(freeText({ x: 50, y: 85, content: 'Step 0: Verify company.config.yaml exists → if missing, route to /setup', fontSize: 12, color: C.textMuted }));

  return els;
}

// ═══════════════════════════════════════════════════════════════
// Section 6: File Writer
// ═══════════════════════════════════════════════════════════════

function writeExcalidraw(filename, elements) {
  const doc = {
    type: 'excalidraw',
    version: 2,
    source: 'https://excalidraw.com',
    elements: elements.filter(Boolean),
    appState: {
      viewBackgroundColor: '#ffffff',
      gridSize: null,
    },
    files: {},
  };
  const outPath = join(__dirname, filename);
  writeFileSync(outPath, JSON.stringify(doc, null, 2), 'utf8');
  console.log(`  ✓ ${filename} (${elements.length} elements)`);
}

// ═══════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════

console.log('Generating Company OS architecture diagrams...\n');

writeExcalidraw('01-agent-architecture.excalidraw', buildAgentArchitecture());
writeExcalidraw('02-ship-flow.excalidraw', buildShipFlow());
writeExcalidraw('03-engineering-delegation.excalidraw', buildEngineeringDelegation());
writeExcalidraw('04-artifact-lineage.excalidraw', buildArtifactLineage());
writeExcalidraw('05-feedback-loop.excalidraw', buildFeedbackLoop());
writeExcalidraw('06-workflow-router.excalidraw', buildWorkflowRouter());

console.log('\nAll 6 diagrams generated successfully.');
console.log('Open in: excalidraw.com, VS Code Excalidraw extension, or Obsidian Excalidraw plugin');
