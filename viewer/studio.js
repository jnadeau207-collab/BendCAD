import * as THREE from 'three';

export const SCHEMES = {
  night: {
    zenith: ['#2A3548', 1.25], horizon: ['#51637F', 1.3], below: ['#3B4A63', 0.9], box: 1.4,
    top: '#05070B', bottom: '#151D2A', major: '#3A4048', minor: '#2A2F36', edge: '#141A24', shadow: 0.62
  },
  day: {
    zenith: ['#DCE1E8', 1.15], horizon: ['#F2F4F7', 1.0], below: ['#C3C8CF', 0.85], box: 1.0,
    top: '#F2F0ED', bottom: '#DEDAD4', major: '#B8BEC9', minor: '#D2D7DE', edge: '#1C2128', shadow: 0.45
  }
};

const BOXES = [
  { az: 35, el: 40, w: 70, h: 34, k: 3.2, tint: [0.999, 1.0, 0.998] },
  { az: -70, el: 74, w: 110, h: 46, k: 1.35, tint: [0.93, 0.97, 1.0] },
  { az: 160, el: 55, w: 80, h: 25, k: 2.0, tint: [0.812, 0.88, 1.0] },
  { az: -20, el: -28, w: 120, h: 30, k: 0.9, tint: [1.0, 0.985, 0.96] }
];

const lin = hex => new THREE.Color(hex);

function skyMaterial(s) {
  const D = Math.PI / 180;
  const boxes = BOXES.map(b => {
    const c = new THREE.Vector3(Math.cos(b.el * D) * Math.cos(b.az * D), Math.cos(b.el * D) * Math.sin(b.az * D), Math.sin(b.el * D));
    const u = new THREE.Vector3(0, 0, 1).cross(c).normalize();
    const v = c.clone().cross(u).normalize();
    return { c, u, v, hu: b.w / 2 * D, hv: b.h / 2 * D, col: new THREE.Vector3(...b.tint).multiplyScalar(b.k * s.box) };
  });
  const uni = {
    zen: { value: lin(s.zenith[0]).multiplyScalar(s.zenith[1]) },
    hor: { value: lin(s.horizon[0]).multiplyScalar(s.horizon[1]) },
    bel: { value: lin(s.below[0]).multiplyScalar(s.below[1]) }
  };
  boxes.forEach((b, i) => {
    uni['c' + i] = { value: b.c }; uni['u' + i] = { value: b.u }; uni['v' + i] = { value: b.v };
    uni['h' + i] = { value: new THREE.Vector2(b.hu, b.hv) }; uni['k' + i] = { value: b.col };
  });
  const box = i => `
    { float au = asin(clamp(dot(d, u${i}), -1.0, 1.0)), av = asin(clamp(dot(d, v${i}), -1.0, 1.0));
      float su = 1.0 - smoothstep(h${i}.x * 0.7, h${i}.x, abs(au)), sv = 1.0 - smoothstep(h${i}.y * 0.7, h${i}.y, abs(av));
      col += k${i} * (su * sv * step(0.0, dot(d, c${i})) + 0.02); }`;
  return new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, uniforms: uni,
    vertexShader: `varying vec3 wp; void main() { wp = (modelMatrix * vec4(position, 1.0)).xyz; gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0); }`,
    fragmentShader: `varying vec3 wp; uniform vec3 zen, hor, bel;
      ${[0, 1, 2, 3].map(i => `uniform vec3 c${i}, u${i}, v${i}, k${i}; uniform vec2 h${i};`).join('\n')}
      void main() {
        vec3 d = normalize(wp);
        vec3 up = mix(hor, zen, smoothstep(0.03, 0.9, d.z));
        vec3 col = mix(bel, up, smoothstep(-0.12, 0.03, d.z));
        ${[0, 1, 2, 3].map(box).join('\n')}
        gl_FragColor = vec4(col, 1.0);
      }`
  });
}

export function environment(renderer, scheme) {
  const sc = new THREE.Scene();
  sc.add(new THREE.Mesh(new THREE.BoxGeometry(100, 100, 100), skyMaterial(SCHEMES[scheme])));
  const pm = new THREE.PMREMGenerator(renderer);
  const rt = pm.fromScene(sc, 0.0, 0.1, 1000);
  pm.dispose();
  return rt.texture;
}

export function background(scheme) {
  const s = SCHEMES[scheme], c = document.createElement('canvas');
  c.width = 4; c.height = 512;
  const g = c.getContext('2d'), gr = g.createLinearGradient(0, 0, 0, 512);
  gr.addColorStop(0, s.top); gr.addColorStop(1, s.bottom);
  g.fillStyle = gr; g.fillRect(0, 0, 4, 512);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

export const FINISHES = {
  'ground-steel': { label: 'Ground alloy steel', color: '#8E949B', metalness: 1, roughness: 0.24, clearcoat: 0.2 },
  'bearing-steel': { label: 'Lapped bearing steel', color: '#C7CCD2', metalness: 1, roughness: 0.1, clearcoat: 0.4 },
  'ceramic': { label: 'Silicon nitride, polished', color: '#2A2D33', metalness: 0, roughness: 0.06, clearcoat: 1, clearcoatRoughness: 0.03, specularIntensity: 1 },
  'peek-cf': { label: 'Carbon PEEK, molded', color: '#3B3631', metalness: 0, roughness: 0.42, clearcoat: 0.5, clearcoatRoughness: 0.3, sheen: 0.4, sheenColor: '#6b5a48' },
  'stainless-brushed': { label: 'Stainless, brushed', color: '#B4BAC1', metalness: 1, roughness: 0.32, clearcoat: 0.15 },
  'stainless-bright': { label: 'Stainless, bright', color: '#C8CDD3', metalness: 1, roughness: 0.16, clearcoat: 0.3 },
  'spring-blued': { label: 'Spring steel, blued', color: '#34497E', metalness: 1, roughness: 0.26, clearcoat: 0.4 },
  'aluminum-machined': { label: 'Aluminum 7075, machined', color: '#D5D9DF', metalness: 1, roughness: 0.2, clearcoat: 0.35, clearcoatRoughness: 0.12 },
  'aluminum-cast-blue': { label: 'Cast aluminum, blue anodized', color: '#2F64A8', metalness: 0.75, roughness: 0.3, clearcoat: 0.6, clearcoatRoughness: 0.08 },
  'aluminum-cast-graphite': { label: 'Cast aluminum, graphite anodized', color: '#4A5059', metalness: 0.8, roughness: 0.32, clearcoat: 0.5, clearcoatRoughness: 0.1 },
  'aluminum-cast-satin': { label: 'Cast aluminum, satin', color: '#AFB6BF', metalness: 1, roughness: 0.34, clearcoat: 0.3 },
  'aluminum-spun': { label: 'Spun aluminum, polished', color: '#E3E6EA', metalness: 1, roughness: 0.07, clearcoat: 0.6, clearcoatRoughness: 0.04 },
  'inconel-heat': { label: 'Inconel, heat tinted', color: '#A7927A', metalness: 1, roughness: 0.34, clearcoat: 0.2 },
  'inconel-cast': { label: 'IN713C, investment cast', color: '#9A9284', metalness: 1, roughness: 0.4 },
  'stainless-heat': { label: 'Heat-resistant stainless, tinted', color: '#B39A7C', metalness: 1, roughness: 0.28, clearcoat: 0.25, tintTop: '#5E6A9A' },
  'copper-nickel': { label: 'Copper-nickel tube', color: '#C0815A', metalness: 1, roughness: 0.26, clearcoat: 0.3 },
  part: { label: 'Titanium', color: '#AEB7C3', metalness: 0.82, roughness: 0.3, clearcoat: 0.35, clearcoatRoughness: 0.14 }
};

export function partMaterial(key, lo, hi) {
  const f = FINISHES[key] || FINISHES.part;
  const m = new THREE.MeshPhysicalMaterial({
    color: new THREE.Color(f.color), metalness: f.metalness, roughness: f.roughness,
    clearcoat: f.clearcoat || 0, clearcoatRoughness: f.clearcoatRoughness ?? 0.14,
    specularIntensity: f.specularIntensity ?? 1, envMapIntensity: 1.0,
    iridescence: f.iridescence || 0, iridescenceIOR: f.iridescenceIOR || 1.3,
    iridescenceThicknessRange: f.iridescenceThicknessRange || [100, 400],
    sheen: f.sheen || 0, sheenColor: new THREE.Color(f.sheenColor || '#000000'),
    side: THREE.DoubleSide, polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1
  });
  const tint = !!(f.tintTop && lo);
  const u = {
    hf: { value: -9 }, sf: { value: -9 }, facc: { value: new THREE.Color('#6EE7FF') },
    tintTop: { value: new THREE.Color(f.tintTop || '#000000') }, tz: { value: new THREE.Vector2(lo ? lo[2] : 0, hi ? hi[2] : 1) }
  };
  m.userData.u = u;
  m.onBeforeCompile = sh => {
    Object.assign(sh.uniforms, u);
    sh.vertexShader = 'attribute float fid;\nvarying float vf;\nvarying float vz;\n' +
      sh.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\nvf = fid;\nvz = position.z;');
    sh.fragmentShader = 'varying float vf; varying float vz; uniform float hf, sf; uniform vec3 facc, tintTop; uniform vec2 tz;\n' + sh.fragmentShader
      .replace('#include <color_fragment>', '#include <color_fragment>\n' + (tint
        ? 'float hz = 1.0 - smoothstep(tz.x, mix(tz.x, tz.y, 0.75), vz);\ndiffuseColor.rgb = mix(diffuseColor.rgb, tintTop, hz * hz * 0.75);'
        : ''))
      .replace('#include <emissivemap_fragment>', '#include <emissivemap_fragment>\nif (abs(vf - sf) < 0.5) totalEmissiveRadiance += facc * 0.42;\nelse if (abs(vf - hf) < 0.5) totalEmissiveRadiance += facc * 0.16;');
  };
  m.customProgramCacheKey = () => (tint ? 'tint' : 'part');
  return m;
}

export function grid(scheme) {
  const s = SCHEMES[scheme];
  const m = new THREE.ShaderMaterial({
    transparent: true, depthWrite: false, extensions: {},
    uniforms: { major: { value: lin(s.major) }, minor: { value: lin(s.minor) }, fade: { value: 600 }, cell: { value: 10 }, ctr: { value: new THREE.Vector3() } },
    vertexShader: `varying vec3 wp; void main() { wp = (modelMatrix * vec4(position, 1.0)).xyz; gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0); }`,
    fragmentShader: `varying vec3 wp; uniform vec3 major, minor, ctr; uniform float fade, cell;
      float line(vec2 p, float s) { vec2 g = abs(fract(p / s - 0.5) - 0.5) / fwidth(p / s); return 1.0 - min(min(g.x, g.y), 1.0); }
      void main() {
        vec2 p = wp.xy;
        float a1 = line(p, cell), a2 = line(p, cell * 10.0);
        float lod = 1.0 - smoothstep(0.15, 0.4, max(fwidth(p.x), fwidth(p.y)) / cell);
        vec3 col = mix(minor, major, a2);
        float a = max(a1 * 0.4 * lod, a2 * 0.7);
        vec2 ax = abs(p) / fwidth(p);
        if (ax.y < 1.0) { col = mix(col, vec3(0.82, 0.29, 0.29), 0.75); a = max(a, 0.55); }
        if (ax.x < 1.0) { col = mix(col, vec3(0.24, 0.61, 0.31), 0.75); a = max(a, 0.55); }
        float d = length(p - ctr.xy);
        a *= 1.0 - smoothstep(fade * 0.35, fade, d);
        if (a < 0.01) discard;
        gl_FragColor = vec4(col, a);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }`
  });
  const g = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), m);
  g.renderOrder = -1;
  g.userData.helper = true;
  return g;
}

export class ContactShadow {
  constructor(renderer, size = 1024) {
    this.r = renderer;
    this.rt = new THREE.WebGLRenderTarget(size, size);
    this.rt2 = new THREE.WebGLRenderTarget(size, size);
    this.rt.texture.generateMipmaps = this.rt2.texture.generateMipmaps = false;
    this.cam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    this.depth = new THREE.MeshDepthMaterial({ side: THREE.DoubleSide });
    this.depth.onBeforeCompile = sh => {
      sh.uniforms.dark = { value: 1.0 };
      sh.fragmentShader = 'uniform float dark;\n' + sh.fragmentShader.replace(
        /gl_FragColor = vec4\( vec3\( 1.0 - fragCoordZ \), opacity \);/,
        'gl_FragColor = vec4(vec3(0.0), (1.0 - fragCoordZ) * dark);');
    };
    this.blur = new THREE.ShaderMaterial({
      uniforms: { tex: { value: null }, dir: { value: new THREE.Vector2() } },
      vertexShader: 'varying vec2 uv0; void main() { uv0 = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }',
      fragmentShader: `varying vec2 uv0; uniform sampler2D tex; uniform vec2 dir;
        void main() { vec4 s = vec4(0.0); float w[5]; w[0]=0.227; w[1]=0.1945; w[2]=0.1216; w[3]=0.054; w[4]=0.0162;
          s += texture2D(tex, uv0) * w[0];
          for (int i = 1; i < 5; i++) { s += texture2D(tex, uv0 + dir * float(i)) * w[i]; s += texture2D(tex, uv0 - dir * float(i)) * w[i]; }
          gl_FragColor = s; }`,
      depthTest: false, depthWrite: false
    });
    this.quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.blur);
    this.qs = new THREE.Scene(); this.qs.add(this.quad);
    this.qc = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    this.mat = new THREE.MeshBasicMaterial({ map: this.rt.texture, transparent: true, depthWrite: false, opacity: 0.6, color: 0x000000 });
    this.mat.onBeforeCompile = sh => {
      sh.fragmentShader = sh.fragmentShader.replace('#include <map_fragment>', 'diffuseColor.a *= texture2D(map, vMapUv).a;');
    };
    this.plane = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), this.mat);
    this.plane.renderOrder = -0.5;
    this.plane.userData.helper = true;
  }
  update(scene, box, height, strength) {
    const c = box.getCenter(new THREE.Vector3()), s = box.getSize(new THREE.Vector3());
    const half = Math.max(s.x, s.y) * 0.75 + 20, z0 = box.min.z - 0.4;
    this.plane.position.set(c.x, c.y, z0);
    this.plane.scale.set(half * 2, half * 2, 1);
    this.mat.opacity = strength;
    const cam = this.cam;
    cam.left = -half; cam.right = half; cam.top = half; cam.bottom = -half;
    cam.near = 0; cam.far = height;
    cam.position.set(c.x, c.y, z0);
    cam.up.set(0, 1, 0);
    cam.lookAt(c.x, c.y, z0 + 1);
    cam.scale.x = -1;
    cam.updateMatrixWorld(); cam.updateProjectionMatrix();
    const r = this.r, prevO = scene.overrideMaterial, prevB = scene.background, prevT = r.getRenderTarget(), prevC = r.getClearAlpha();
    const hidden = [];
    scene.traverse(o => { if (o.visible && (o.userData.helper || o.isLineSegments)) { hidden.push(o); o.visible = false; } });
    scene.overrideMaterial = this.depth; scene.background = null;
    r.setClearAlpha(0);
    r.setRenderTarget(this.rt); r.clear(); r.render(scene, cam);
    scene.overrideMaterial = prevO; scene.background = prevB;
    hidden.forEach(o => { o.visible = true; });
    const px = 1 / this.rt.width;
    for (const k of [2.2, 1.1]) {
      this.blur.uniforms.tex.value = this.rt.texture; this.blur.uniforms.dir.value.set(px * k, 0);
      r.setRenderTarget(this.rt2); r.clear(); r.render(this.qs, this.qc);
      this.blur.uniforms.tex.value = this.rt2.texture; this.blur.uniforms.dir.value.set(0, px * k);
      r.setRenderTarget(this.rt); r.clear(); r.render(this.qs, this.qc);
    }
    r.setRenderTarget(prevT); r.setClearAlpha(prevC);
  }
}

export function hatchTexture() {
  const c = document.createElement('canvas');
  c.width = c.height = 64;
  const g = c.getContext('2d');
  g.fillStyle = '#ffffff'; g.fillRect(0, 0, 64, 64);
  g.strokeStyle = 'rgba(0,0,0,0.28)'; g.lineWidth = 3;
  for (let k = -64; k <= 128; k += 16) { g.beginPath(); g.moveTo(k, 0); g.lineTo(k + 64, 64); g.stroke(); }
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 8;
  return t;
}

export function mirrorFloor(renderer, scene, Reflector) {
  const shader = {
    name: 'StudioFloor',
    uniforms: { color: { value: null }, tDiffuse: { value: null }, textureMatrix: { value: null }, strength: { value: 0.32 }, fade: { value: 400 }, ctr: { value: new THREE.Vector3() } },
    vertexShader: `uniform mat4 textureMatrix; varying vec4 vUv; varying vec3 wp;
      void main() { vUv = textureMatrix * vec4(position, 1.0); wp = (modelMatrix * vec4(position, 1.0)).xyz; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: `uniform sampler2D tDiffuse; uniform float strength, fade; uniform vec3 ctr; varying vec4 vUv; varying vec3 wp;
      void main() {
        vec4 r = texture2DProj(tDiffuse, vUv);
        float f = 1.0 - smoothstep(fade * 0.25, fade, length(wp.xy - ctr.xy));
        gl_FragColor = vec4(r.rgb, r.a * strength * f);
      }`
  };
  const w = Math.max(256, renderer.domElement.width >> 1), h = Math.max(256, renderer.domElement.height >> 1);
  const m = new Reflector(new THREE.PlaneGeometry(1, 1), { shader, textureWidth: w, textureHeight: h, multisample: 4, clipBias: 0.0 });
  m.material.transparent = true; m.material.depthWrite = false;
  m.renderOrder = -2;
  m.userData.helper = true;
  const rt = m.getRenderTarget();
  const a = new THREE.WebGLRenderTarget(w, h, { type: THREE.HalfFloatType }), b = new THREE.WebGLRenderTarget(w, h, { type: THREE.HalfFloatType });
  const blur = new THREE.ShaderMaterial({
    uniforms: { tex: { value: null }, dir: { value: new THREE.Vector2() } }, depthTest: false, depthWrite: false,
    vertexShader: 'varying vec2 uv0; void main() { uv0 = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }',
    fragmentShader: `varying vec2 uv0; uniform sampler2D tex; uniform vec2 dir;
      void main() { vec4 s = texture2D(tex, uv0) * 0.227;
        s += (texture2D(tex, uv0 + dir) + texture2D(tex, uv0 - dir)) * 0.1945;
        s += (texture2D(tex, uv0 + dir * 2.0) + texture2D(tex, uv0 - dir * 2.0)) * 0.1216;
        s += (texture2D(tex, uv0 + dir * 3.0) + texture2D(tex, uv0 - dir * 3.0)) * 0.054;
        s += (texture2D(tex, uv0 + dir * 4.0) + texture2D(tex, uv0 - dir * 4.0)) * 0.0162;
        gl_FragColor = s; }`
  });
  const qs = new THREE.Scene(), qc = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  qs.add(new THREE.Mesh(new THREE.PlaneGeometry(2, 2), blur));
  m.material.uniforms.tDiffuse.value = b.texture;
  const base = m.onBeforeRender;
  m.onBeforeRender = function (r, sc, cam) {
    const hidden = [];
    sc.traverse(o => { if (o !== m && o.visible && (o.userData.helper || o.userData.stencil || o.userData.cap || o.isLineSegments)) { hidden.push(o); o.visible = false; } });
    const bg = sc.background, ca = r.getClearAlpha(), cc = r.getClearColor(new THREE.Color());
    sc.background = null; r.setClearColor(0x000000, 0);
    base.call(this, r, sc, cam);
    sc.background = bg;
    hidden.forEach(o => { o.visible = true; });
    const prev = r.getRenderTarget();
    blur.uniforms.tex.value = rt.texture; blur.uniforms.dir.value.set(1.6 / w, 0);
    r.setRenderTarget(a); r.clear(); r.render(qs, qc);
    blur.uniforms.tex.value = a.texture; blur.uniforms.dir.value.set(0, 1.6 / h);
    r.setRenderTarget(b); r.clear(); r.render(qs, qc);
    r.setRenderTarget(prev); r.setClearColor(cc, ca);
  };
  return m;
}
