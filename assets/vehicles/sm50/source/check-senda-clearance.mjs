import { components, datums } from './senda.mjs';

const byName = new Map(components.map(part => [part.name, part]));
const widthAndTravel = {
  FrontWheel: { halfWidth: .050, travel: 120, radius: .296, id: 'wheel_front_17' },
  RearWheel: { halfWidth: .065, travel: 110, radius: .307, id: 'wheel_rear_17' },
};
// Adjacent bodywork and chassis parts, excluding wheel, axle, drivetrain, and brake hardware.
const fixed = {
  FrontWheel: ['Frame', 'front_fender', 'headlight_mask', 'exhaust', 'radiator', 'coolant_hoses', 'tank_std'],
  RearWheel: ['Frame', 'seat_std', 'side_panel_l', 'side_panel_r', 'tail_plate', 'airbox', 'exhaust', 'oil_tank', 'oil_line'],
};
const results = {};
for (const [name, { halfWidth, travel, radius, id }] of Object.entries(widthAndTravel)) {
  const axle = datums['Mount_' + name];
  const wheel = byName.get('Part_sd_' + id);
  const actualRadius = Math.max(...wheel.layers.vertex.vertices.map(p => Math.hypot(p[1] - axle[1], p[2] - axle[2])));
  if (Math.abs(actualRadius - radius) > 1e-7) throw new Error('Unexpected ' + name + ' radius');

  const adjacent = fixed[name].map(id => byName.get(id === 'Frame' ? id : 'Part_sd_' + id));
  const limits = [];
  for (let offset = -40; offset <= travel; offset += 5) {
    const clearances = adjacent.map(part => {
      let gap = Infinity;
      for (const [x, y, z] of part.layers.vertex.vertices) {
        const radialGap = Math.hypot(y - axle[1] - offset / 1000, z - axle[2]) - radius;
        gap = Math.min(gap, Math.max(Math.abs(x - axle[0]) - halfWidth, radialGap));
      }
      return { part: part.name, gapMm: Math.round(gap * 1000) };
    });
    limits.push({ offsetMm: offset, ...clearances.reduce((a, b) => a.gapMm <= b.gapMm ? a : b) });
  }
  results[name] = {
    travelMm: travel, radiusM: actualRadius, limits,
    closest: limits.reduce((a, b) => a.gapMm <= b.gapMm ? a : b),
    firstInside: limits.find(entry => entry.gapMm < 0) ?? null,
  };
}
console.log(JSON.stringify(results, null, 2));
if (Object.values(results).some(wheel => wheel.firstInside)) process.exitCode = 1;
