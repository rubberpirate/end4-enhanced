# Notification bubbles

This addition serves the existing desktop's notification flow. Its direction is
compact, fluid and quiet: a liquid bar extension. Existing settings and Standard
notifications keep their current design.

The user's reference is jrnxf/drip's demo.webp. Bubble mode grows from the actual
center bar island, including M3 Hug. It never creates or paints a replacement
notch. The island's geometry and color remain the source of truth, with a smooth
color transition along the neck to the detached black notification capsule.

Typography inherits Appearance.font.family.main: 13 px semibold title, 11 px
secondary detail, 12 px action labels. Colors follow the reference: black capsule,
#f5f5f5 foreground, #999999 secondary text, #1b7130 primary action. Native app
icons retain the sender's identity. Spacing is 14 px outer padding, 10 px icon/text
and card gaps, 6 px between actions. Capsules use half their height as the radius;
actions are 28 px tall. There are no decorative shadows or borders.

Motion uses Drip's spring equations: 0.62 s fall with 0.2 bounce, 0.3 s feed,
0.5 s expansion with 0.15 bounce after physical detachment, 0.22 s gather and
0.4 s return. The neck is the cubic smooth union of signed-distance fields.
Text starts at 80% expansion, detail follows 40 ms later. The GPU shader is
compiled with Qt's qsb; no extra runtime dependency is introduced.

The signature is the existing island feeding and reabsorbing the droplet. Up to
three notifications form a chain; a smaller drop counts the remainder. Queued
notifications have no running timeout until their own card is revealed. The
configured default timeout remains reactive, and explicit sender timeouts keep
their existing meaning. At the bar center the source is the actual island; other
position choices use a transparent edge popup with no painted source. A click
invokes the sender's default action, otherwise focuses its window or launches its
desktop entry; unresolved senders fall back to notification history. Bottom
bars reverse the flow while keeping text upright. Reduced motion uses a brief
fade. Actions retain native hover, pressed and keyboard focus states; hovering
pauses timeout, and full text is available in a tooltip and notification history.

Verification: captured the GPU-rendered phases on Wayland; checked stacking,
overflow, promotion, early dismissal and reduced motion. Integration checks use
isolated configuration, state and DBus. The reference defines the appearance;
no wider redesign of the desktop is part of this change.
