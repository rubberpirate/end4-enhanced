.pragma library
.import "../../common/widgets/shapes/material-shapes.js" as Shapes
.import "../../common/widgets/shapes/geometry/offset.js" as Offset
.import "../../common/widgets/shapes/shapes/corner-rounding.js" as Rounding

// Nebula's seven-leaf command shape, using end4's existing polygon renderer.
function clover(leaves) {
    const tip = (-90 + 180 / leaves) * Math.PI / 180;
    return Shapes.customPolygon([
        new Shapes.PointNRound(new Offset.Offset(0.5, 0.5 - 0.464)),
        new Shapes.PointNRound(new Offset.Offset(0.5 + 0.654 * Math.cos(tip), 0.5 + 0.654 * Math.sin(tip)), new Rounding.CornerRounding(0.209))
    ], leaves).normalized();
}
