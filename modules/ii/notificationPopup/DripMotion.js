// Motion and liquid geometry ported from jrnxf/drip (MIT); see THIRD_PARTY.md.
.pragma library

function spring(time, duration, bounce) {
    if (time <= 0) return 0;
    const natural = 2 * Math.PI / duration;
    const ratio = 1 - bounce;
    if (ratio >= 1) return 1 - Math.exp(-natural * time) * (1 + natural * time);
    const damped = natural * Math.sqrt(1 - ratio * ratio);
    return 1 - Math.exp(-ratio * natural * time)
        * (Math.cos(damped * time) + ratio * natural / damped * Math.sin(damped * time));
}

function value(initial) { return { base: initial, target: initial, parts: [] }; }
function sample(v, time) {
    return v.parts.reduce((n, p) => n + p.change * spring(time - p.start, p.duration, p.bounce), v.base);
}
function animate(v, target, duration, bounce, start) {
    v.parts.push({ change: target - v.target, duration: duration, bounce: bounce, start: start });
    v.target = target;
}
function firstTime(start, predicate) {
    let t = start;
    while (t < start + 2 && !predicate(t)) t += 0.001;
    return t;
}
function enter(width, height, top, anchorCenter, anchorBottom, notchHeight, time, reduced) {
    const initial = anchorCenter === null ? notchHeight - 24 - 26 / 2 : anchorCenter;
    const m = { center: value(initial), width: value(12), height: value(12), blend: value(24),
        start: time, leaving: false, end: time + 2.5, top: top, fullHeight: height };
    if (reduced) {
        m.center = value(top + height / 2); m.width = value(width); m.height = value(height);
        m.blend = value(0); m.cue = time; m.end = time + 0.18;
        return m;
    }
    animate(m.width, 26, 0.3, 0, time);
    animate(m.height, 26, 0.3, 0, time);
    animate(m.center, top + height / 2, 0.62, 0.2, time);
    const detached = firstTime(time, t => sample(m.center, t) - 13 >= anchorBottom + 8);
    animate(m.blend, 0, 0.35, 0, detached);
    animate(m.width, width, 0.5, 0.15, detached);
    animate(m.height, height, 0.5, 0.15, detached);
    m.cue = firstTime(detached, t => spring(t - detached, 0.5, 0.15) >= 0.8);
    m.end = detached + 1.7;
    return m;
}
function leave(m, anchorCenter, anchorHeight, notchHeight, time, reduced) {
    if (m.leaving) return;
    m.exitOpacity = opacity(m, time, false);
    m.exitDetailOpacity = opacity(m, time, true);
    m.leaving = true; m.exit = time;
    if (reduced) { m.end = time + 0.15; return; }
    animate(m.width, 26, 0.22, 0, time + 0.03);
    animate(m.height, 26, 0.22, 0, time + 0.03);
    const rise = firstTime(time + 0.03, t => Math.max(Math.abs(sample(m.width, t) - 26), Math.abs(sample(m.height, t) - 26)) <= 2);
    animate(m.blend, 24, 0.3, 0, rise);
    const swallowed = anchorCenter === null ? notchHeight - 24 - 39 : anchorCenter - anchorHeight / 2 + 15;
    animate(m.center, swallowed, 0.4, 0, rise);
    m.end = rise + 0.9;
}
function move(m, top, time, reduced) {
    const shift = top - m.top;
    if (!shift || m.leaving) return;
    m.top = top;
    if (reduced) m.center = value(m.center.target + shift);
    else {
        animate(m.center, m.center.target + shift, 0.45, 0.12, time);
        m.end = Math.max(m.end, time + 1.7);
    }
}
function resize(m, width, time, reduced) {
    if (reduced) m.width = value(width);
    else { animate(m.width, width, 0.4, 0.1, time); m.end = Math.max(m.end, time + 1.5); }
}
function opacity(m, time, detail) {
    if (m.leaving) return (detail ? m.exitDetailOpacity : m.exitOpacity) * Math.max(0, 1 - (time - m.exit) / 0.12);
    return Math.max(0, Math.min(1, (time - m.cue - (detail ? 0.04 : 0)) / 0.18));
}
