// Renderiza post (1080x1350) e story (1080x1920) de cada dia de days.js em ig/<data>/
// Uso: node render.js <pasta_saida> [data1,data2,...]
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
const days=require('./days.js');
const out=process.argv[2]||'out';const only=(process.argv[3]||'').split(',').filter(Boolean);
const css=fs.readFileSync(path.join(__dirname,'style.css'),'utf8');
const img=f=>'data:image/png;base64,'+fs.readFileSync(path.join(__dirname,'assets',f+'.png')).toString('base64');
const FONTS='<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Figtree:wght@400;500;600;700;800&display=block" rel="stylesheet">';
const page=(d,kind)=>`<!doctype html><html><head><meta charset="utf-8">${FONTS}<style>${css}</style></head><body>
<div class="canvas ${kind}"><img class="logo" src="${img('logo')}"><h1>${d.title}</h1>
${kind==='post'
 ?`<div class="subrow"><p class="sub">${d.sub}</p><img class="pig" src="${img(d.pig)}"></div><div class="card">${d.card}</div><div class="foot">Começar é grátis · link na bio</div>`
 :`<div class="subwrap"><p class="sub">${d.sub}</p></div><div class="card">${d.card}</div>
  <div class="bubrow"><div class="bubble">💬 ${d.q}<small>Responde no direct!</small></div><img class="pig" src="${img(d.pig)}"></div>
  <div class="cta">📲 Baixe o Prumo · link na bio</div>`}
</div></body></html>`;
(async()=>{const b=await chromium.launch();
 for(const d of days){if(only.length&&!only.includes(d.date))continue;
  const dir=path.join(out,d.date);fs.mkdirSync(dir,{recursive:true});
  for(const [kind,h] of [['post',1350],['story',1920]]){
   const p=await b.newPage({viewport:{width:1080,height:h},deviceScaleFactor:1});
   await p.setContent(page(d,kind),{waitUntil:'networkidle'}).catch(()=>{});
   await p.evaluate(()=>document.fonts.ready);
   const fam=await p.evaluate(()=>[document.fonts.check('700 84px Fredoka'),document.fonts.check('400 32px Figtree')]);
   // checa se algo saiu do quadro
   const over=await p.evaluate(()=>{const c=document.querySelector('.card').getBoundingClientRect();const f=document.querySelector('.foot,.bubrow').getBoundingClientRect();return Math.round(c.bottom)+'/'+Math.round(f.top)});
   await p.screenshot({path:path.join(dir,kind+'.jpg'),type:'jpeg',quality:92});
   console.log(d.date,kind,'fonts',fam.join(','),'card/foot',over);await p.close()}
  fs.writeFileSync(path.join(dir,'caption.txt'),d.caption)}
 await b.close()})();
