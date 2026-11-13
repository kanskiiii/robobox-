// Metres, Y up, -Z forward, -X rider's left.
export const v = (x, y, station) => [x, y, -station];
export const add = (a, b) => a.map((x, i) => x + b[i]);
export const sub = (a, b) => a.map((x, i) => x - b[i]);
export const mul = (a, k) => a.map(x => x * k);
const dot = (a, b) => a.reduce((sum, x, i) => sum + x * b[i], 0);
export const cross = ([a,b,c], [x,y,z]) => [b*z-c*y, c*x-a*z, a*y-b*x];
export const length = a => Math.hypot(...a);
export const unit = a => mul(a, 1 / length(a));
export const tau = 2 * Math.PI;
export const mix = (a, b, t) => add(mul(a, 1-t), mul(b, t));

export class Mesh {
  vertices = [];
  triangles = [];
  solids = [];

  vertex(point) {
    this.vertices.push(point);
    return this.vertices.length - 1;
  }

  tri(a, b, c) { this.triangles.push([a,b,c]); }
  quad(a, b, c, d) { this.tri(a,b,c); this.tri(a,c,d); }

  // Rings use a consistent winding. Caps use their own vertices for a hard edge.
  rings(points, { closed = false, cap = true, flip = false } = {}) {
    const startVertex = this.vertices.length;
    const startFace = this.triangles.length;
    const rings = points.map(ring => ring.map(point => this.vertex(point)));
    const count = rings[0].length;
    for (let j = 0; j < rings.length - (closed ? 0 : 1); j++) {
      const a = rings[j], b = rings[(j+1) % rings.length];
      for (let i = 0; i < count; i++) {
        const k = (i+1) % count;
        if (flip) this.quad(a[i], b[i], b[k], a[k]);
        else this.quad(a[i], a[k], b[k], b[i]);
      }
    }
    if (!closed && cap) {
      for (const j of [0, points.length-1]) {
        const rim = points[j].map(point => this.vertex(point));
        const center = this.vertex(mul(points[j].reduce(add), 1/count));
        for (let i = 0; i < count; i++) {
          const k = (i+1) % count;
          if ((j === 0) !== flip) this.tri(center, rim[k], rim[i]);
          else this.tri(center, rim[i], rim[k]);
        }
      }
    }
    this.solids.push({startVertex,startFace,endVertex:this.vertices.length,endFace:this.triangles.length});
  }

  tube(centers, radii, sides = 12, hint = [1,0,0]) {
    const profile = centers.map((center, i) => {
      const forward = unit(sub(centers[Math.min(i+1, centers.length-1)], centers[Math.max(i-1,0)]));
      const ref = Math.abs(dot(hint, forward)) > .95 ? [0,1,0] : hint;
      const across = unit(cross(ref, forward));
      const up = cross(forward, across);
      const [a,b] = [radii[i]].flat().length === 1 ? [radii[i],radii[i]] : radii[i];
      return Array.from({length:sides}, (_, k) => {
        const t = k*tau/sides;
        return add(center, add(mul(across, a*Math.cos(t)), mul(up,b*Math.sin(t))));
      });
    });
    this.rings(profile);
  }

  rod(a, b, r, sides = 12) { this.tube([a,b], [r,r], sides); }

  // A closed, turned section. Profile uses [axial offset, radius].
  lathe(center, axis, profile, sides = 48, tooth = () => 0) {
    const ref = Math.abs(axis[1]) > .9 ? [1,0,0] : [0,1,0];
    const d = unit(cross(axis, ref));
    const e = cross(axis,d);
    const rings = profile.map(([x,r], j) => Array.from({length:sides}, (_,i) => {
      const a = i*tau/sides;
      const radius = r + tooth(i,j);
      return add(add(center,mul(axis,x)), add(mul(d,radius*Math.cos(a)),mul(e,radius*Math.sin(a))));
    }));
    this.rings(rings, {closed:true});
  }

  // Station sections [station, center height, half width, half height, center X].
  shell(sections, sides = 12, power = .48) {
    const shape = x => Math.sign(x)*Math.abs(x)**power;
    this.rings(sections.map(([s,y,w,h,x=0]) => Array.from({length:sides}, (_,i) => {
      const a = (i+.5)*tau/sides;
      return v(x+w*shape(Math.cos(a)),y+h*shape(Math.sin(a)),s);
    })), {flip:true});
  }

  // Closed extruded plate with a bevel. Profile lies in the Y/station plane.
  plate(profile, x, width, bevel = .002) {
    const [cy, cs] = mul(profile.reduce(add),1/profile.length);
    const ordered = profile.slice();
    const area = ordered.reduce((sum, [y,s], i) => {
      const [ny,ns] = ordered[(i+1)%ordered.length];
      return sum + s*ny - ns*y;
    },0);
    if (area < 0) ordered.reverse();
    const rings = [[-width/2,true],[-width/2+bevel,false],[width/2-bevel,false],[width/2,true]]
      .map(([dx,inset]) => ordered.map(([y,s]) => {
        const d = Math.hypot(y-cy,s-cs);
        const k = inset ? Math.max(.15, 1-bevel/d) : 1;
        return v(x+dx,cy+(y-cy)*k,cs+(s-cs)*k);
      }));
    this.rings(rings);
  }

  normals() {
    const normals = this.vertices.map(() => [0,0,0]);
    for (const [a,b,c] of this.triangles) {
      const face = cross(sub(this.vertices[b],this.vertices[a]), sub(this.vertices[c],this.vertices[a]));
      for (const i of [a,b,c]) normals[i] = add(normals[i],face);
    }
    return normals.map(unit);
  }
}
