(function (root) {
  'use strict';
  const EPS = 1e-8;
  const pairs = n => { const out=[]; for(let a=0;a<n;a++)for(let b=a+1;b<n;b++)out.push([a,b]); return out; };
  function cube(n, rectangular) {
    const widths = [1.4,.75,1,.55,.9,1.15];
    const vertices = Array.from({length:2**n},(_,i)=>Array.from({length:n},(_,a)=>((i>>a)&1?1:-1)*(rectangular?widths[a]:1)));
    const edges=[],faces=[];
    for(let i=0;i<vertices.length;i++)for(let a=0;a<n;a++)if(!(i&(1<<a)))edges.push([i,i|(1<<a)]);
    for(const [a,b] of pairs(n))for(let i=0;i<vertices.length;i++)if(!(i&(1<<a))&&!(i&(1<<b)))faces.push([i,i|(1<<a),i|(1<<a)|(1<<b),i|(1<<b)]);
    return {vertices,edges,faces};
  }
  function simplex(n) {
    // Rows of a Helmert matrix give n+1 equidistant points in R^n.
    const vertices=Array.from({length:n+1},(_,i)=>Array.from({length:n},(_,j)=>i<=j?1/Math.sqrt((j+1)*(j+2)):i===j+1?-(j+1)/Math.sqrt((j+1)*(j+2)):0));
    const edges=pairs(n+1),faces=[];
    for(let a=0;a<=n;a++)for(let b=a+1;b<=n;b++)for(let c=b+1;c<=n;c++)faces.push([a,b,c]);
    return {vertices,edges,faces};
  }
  function cross(n) {
    const vertices=Array.from({length:2*n},(_,i)=>Array.from({length:n},(_,a)=>a===Math.floor(i/2)?(i%2?1:-1):0));
    const edges=pairs(2*n).filter(([a,b])=>Math.floor(a/2)!==Math.floor(b/2));
    const faces=[];
    for(let a=0;a<n;a++)for(let b=a+1;b<n;b++)for(let c=b+1;c<n;c++)for(let s=0;s<8;s++)faces.push([2*a+(s&1),2*b+((s>>1)&1),2*c+((s>>2)&1)]);
    return {vertices,edges,faces};
  }
  function duoprism() {
    const p=6,q=6,id=(a,b)=>((a+p)%p)*q+((b+q)%q),vertices=[],edges=[],faces=[];
    for(let a=0;a<p;a++)for(let b=0;b<q;b++)vertices.push([Math.cos(2*Math.PI*a/p),Math.sin(2*Math.PI*a/p),Math.cos(2*Math.PI*b/q),Math.sin(2*Math.PI*b/q)]);
    for(let a=0;a<p;a++)for(let b=0;b<q;b++) {edges.push([id(a,b),id(a+1,b)],[id(a,b),id(a,b+1)]);faces.push([id(a,b),id(a+1,b),id(a+1,b+1),id(a,b+1)]);}
    for(let a=0;a<p;a++)faces.push(Array.from({length:q},(_,b)=>id(a,b)));
    for(let b=0;b<q;b++)faces.push(Array.from({length:p},(_,a)=>id(a,b)));
    return {vertices,edges,faces};
  }
  function cell24() {
    const vertices=[];
    for(const [a,b] of pairs(4))for(let s=0;s<4;s++){const v=[0,0,0,0];v[a]=s&1?1:-1;v[b]=s&2?1:-1;vertices.push(v);}
    const edges=pairs(24).filter(([a,b])=>Math.abs(vertices[a].reduce((s,x,i)=>s+(x-vertices[b][i])**2,0)-2)<EPS);
    const connected=new Set(edges.map(e=>e.join(','))),faces=[];
    for(let a=0;a<24;a++)for(let b=a+1;b<24;b++)for(let c=b+1;c<24;c++)if(connected.has(a+','+b)&&connected.has(a+','+c)&&connected.has(b+','+c))faces.push([a,b,c]);
    return {vertices,edges,faces};
  }
  function extrude(g) {
    const k=g.vertices.length;
    return {vertices:[...g.vertices.map(v=>[...v,-.65]),...g.vertices.map(v=>[...v,.65])],edges:[...g.edges.map(e=>e.slice()),...g.edges.map(e=>e.map(i=>i+k)),...g.vertices.map((_,i)=>[i,i+k])],faces:[...g.faces.map(f=>f.slice()),...g.faces.map(f=>f.map(i=>i+k)),...g.edges.map(([a,b])=>[a,b,b+k,a+k])]};
  }
  function shapes(n) {
    return [
      {id:'hypercube',name:n===4?'Tesseract':n===5?'Penteract':'Hexeract',description:`The ${n}D hypercube: ${2**n} vertices and ${n*2**(n-1)} edges.`},
      {id:'simplex',name:`${n}-simplex`,description:`The simplest ${n}D polytope, with ${n+1} mutually equidistant vertices.`},
      {id:'cross',name:n===4?'16-cell':`${n}D cross-polytope`,description:`The hypercube's dual, with ${2*n} vertices on coordinate axes.`},
      {id:'hyperrectangle',name:`${n}D orthotope`,description:'A stretched hypercube with unequal side lengths.'},
      {id:'duoprism',name:n===4?'Hexagonal duoprism':`Duoprism × ${n===5?'interval':'square'}`,description:n===4?'The Cartesian product of two regular hexagons in perpendicular planes.':'A hexagonal duoprism extended along additional independent axes.'},
      {id:'24cell',name:n===4?'24-cell':`24-cell × ${n===5?'interval':'square'}`,description:n===4?'A regular 4D polytope with 24 octahedral cells.':'The regular 24-cell extended along additional independent axes.'}
    ];
  }
  function createShape(id,n) {
    if(!Number.isInteger(n)||n<4||n>6)throw new Error('Choose 4, 5, or 6 dimensions.');
    let g;
    if(id==='hypercube'||id==='hyperrectangle')g=cube(n,id==='hyperrectangle');
    else if(id==='simplex')g=simplex(n);
    else if(id==='cross')g=cross(n);
    else if(id==='duoprism'||id==='24cell'){g=id==='duoprism'?duoprism():cell24();for(let d=4;d<n;d++)g=extrude(g);}
    else throw new Error('Unknown shape: '+id);
    const maxRadius=Math.max(...g.vertices.map(v=>Math.hypot(...v))),scale=1.7/maxRadius;
    g.vertices=g.vertices.map(v=>v.map(x=>x*scale));g.name=shapes(n).find(s=>s.id===id).name;
    return g;
  }
  function rotate(vertices,angles) {
    const out=vertices.map(v=>v.slice());
    for(const [plane,theta] of Object.entries(angles||{})) {
      const [a,b]=plane.split(',').map(Number); if(!Number.isFinite(theta)||!Number.isInteger(a)||!Number.isInteger(b)||a===b||a<0||b<0||!out[0]||a>=out[0].length||b>=out[0].length)continue;
      const c=Math.cos(theta),s=Math.sin(theta);
      for(const v of out){const x=v[a],y=v[b];v[a]=c*x-s*y;v[b]=s*x+c*y;}
    }
    return out;
  }
  function project(vertices,mode='perspective',distance=5) {
    return vertices.map(vertex=>{let v=vertex.slice();while(v.length>3){const z=v.pop(),scale=mode==='orthographic'?1:distance/(distance-z);v=v.map(x=>x*scale);}while(v.length<3)v.push(0);return v;});
  }
  function slice(vertices,edges,faces,level,axis) {
    if(!vertices.length)return {vertices:[],edges:[]};
    if(axis===undefined)axis=vertices[0].length-1;
    const points=[],outEdges=[],pointIds=new Map(),edgeIds=new Set();
    const addPoint=v=>{const p=v.filter((_,i)=>i!==axis),key=p.map(x=>Math.round(x/EPS)).join(',');if(!pointIds.has(key)){pointIds.set(key,points.length);points.push(p);}return pointIds.get(key);};
    function intersect(a,b) {
      const va=vertices[a],vb=vertices[b],da=va[axis]-level,db=vb[axis]-level,result=[];
      if(Math.abs(da)<EPS)result.push(addPoint(va));
      if(Math.abs(db)<EPS)result.push(addPoint(vb));
      if((da<-EPS&&db>EPS)||(da>EPS&&db<-EPS)){const t=da/(da-db);result.push(addPoint(va.map((x,i)=>x+t*(vb[i]-x))));}
      return [...new Set(result)];
    }
    function addEdge(a,b){if(a===b)return;const key=a<b?a+','+b:b+','+a;if(!edgeIds.has(key)){edgeIds.add(key);outEdges.push([a,b]);}}
    for(const [a,b] of edges)intersect(a,b);
    for(const face of faces||[]) {
      const hits=[];
      const coplanar=face.every(i=>Math.abs(vertices[i][axis]-level)<EPS);
      for(let i=0;i<face.length;i++) {const h=intersect(face[i],face[(i+1)%face.length]);hits.push(...h);if(coplanar&&h.length===2)addEdge(h[0],h[1]);}
      const unique=[...new Set(hits)];
      if(!coplanar&&unique.length===2)addEdge(unique[0],unique[1]);
      else if(!coplanar&&unique.length>2){let best=[0,1],distance=-1;for(const [a,b] of pairs(unique.length)){const d=points[unique[a]].reduce((s,x,k)=>s+(x-points[unique[b]][k])**2,0);if(d>distance){distance=d;best=[a,b];}}addEdge(unique[best[0]],unique[best[1]]);}
    }
    return {vertices:points,edges:outEdges};
  }
  const api={shapes,createShape,rotate,project,slice};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  if(root)root.HyperMath=api;
})(typeof window!=='undefined'?window:typeof globalThis!=='undefined'?globalThis:null);
