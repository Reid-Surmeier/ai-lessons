// copy buttons, OS tabs, active TOC entry
document.querySelectorAll('.ah-cmd').forEach(box=>{
  const code=box.querySelector('code'), btn=box.querySelector('button'); if(!btn) return;
  btn.addEventListener('click',async()=>{
    try{await navigator.clipboard.writeText(code.textContent.trim());}catch(e){}
    btn.classList.add('ok'); btn.innerHTML=CHECK; setTimeout(()=>{btn.classList.remove('ok');btn.innerHTML=COPY;},1400);
  });
});
const COPY='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
const CHECK='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
document.querySelectorAll('.ah-cmd button').forEach(b=>b.innerHTML=COPY);
// OS tabs
const isMac=/Mac/.test(navigator.platform), tabs=document.querySelectorAll('.ah-tabs button');
function selectOS(os){
  tabs.forEach(b=>b.setAttribute('aria-selected',b.dataset.os===os));
  document.querySelectorAll('[data-os-panel]').forEach(p=>p.hidden=p.dataset.osPanel!==os);
}
if(tabs.length){ tabs.forEach(b=>b.addEventListener('click',()=>selectOS(b.dataset.os))); selectOS(isMac?'mac':'windows'); }
// active TOC
const links=[...document.querySelectorAll('.ah-aside a')];
if(links.length&&'IntersectionObserver' in window){
  const map=new Map(links.map(a=>[a.getAttribute('href').slice(1),a]));
  const io=new IntersectionObserver(es=>{es.forEach(e=>{if(e.isIntersecting){links.forEach(l=>l.classList.remove('active'));map.get(e.target.id)?.classList.add('active');}})},{rootMargin:'-70px 0px -70% 0px'});
  map.forEach((a,id)=>{const el=document.getElementById(id); if(el) io.observe(el);});
}
