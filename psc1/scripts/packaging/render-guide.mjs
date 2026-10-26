// Documentation links must keep their source meaning when embedded in an npm README.
export function renderSourceGuide(markdown, {commit, sourcePath}) {
 if (!/^[a-f0-9]{40}$/.test(commit) || !sourcePath.startsWith('psc1/docs/'))
  throw Error('PSC1_GUIDE_SOURCE_IDENTITY');
 const base='https://github.com/dwijayuda/pskernel/blob/'+commit+'/'+sourcePath;
 return markdown.replace(/\]\(([^()\n]+)\)/g, (all,href)=>{
  if (/^(https?:|mailto:|#)/.test(href)) return all;
  return ']('+new URL(href,base).href+')';
 });
}
