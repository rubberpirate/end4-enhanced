.pragma library
// From Nebula by LilaccFlowerr (AGPL-3.0); see README.md and LICENSE.

function clamp(t) {
    return Math.max(0, Math.min(1, t));
}

function phase(t, start, length) {
    return clamp((t - start) / length);
}

function decel(t) {
    return 1 - Math.pow(1 - t, 3);
}

function back(t, overshoot) {
    const c1 = 1.70158 * overshoot, c3 = c1 + 1;
    return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
}

function outBack(t, s) {
    t = t - 1;
    return t * t * ((s + 1) * t + s) + 1;
}

function inBack(t, s) {
    return t * t * ((s + 1) * t - s);
}

function inQuad(t) {
    return t * t;
}

function outCubic(t) {
    t = t - 1;
    return t * t * t + 1;
}

function outQuint(t) {
    t = t - 1;
    return t * t * t * t * t + 1;
}
