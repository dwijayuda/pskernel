class InfoviewProvider {
  constructor(){
    this.view=null;
    this.proof=null;
    this.status=null;
  }

  resolveWebviewView(view){
    this.view=view;
    this.render();
  }

  update(proof,status){
    this.proof=proof;
    this.status=status;
    this.render();
  }

  render(){
    if(this.view===null)return;
    const proofText=this.proof===null
      ?'Move the cursor into a theorem.'
      :escapeHtml(this.proof.message);
    const statusText=this.status===null
      ?'No document status.'
      :'Frontend: '+escapeHtml(this.status.frontend)+
        ' · Kernel: '+escapeHtml(this.status.kernel)+
        ' · Verified: '+String(this.status.verifiedDeclarations)+'/'+
        String(this.status.declarations);
    const goalText=this.proof?.initialGoal===undefined
      ?''
      :'<h4>Initial elaborated goal</h4><pre>'+
        escapeHtml([
          ...this.proof.initialGoal.locals.map(renderGoalLocal),
          '⊢ '+this.proof.initialGoal.target,
        ].join('\n'))+
        '</pre>';

    this.view.webview.html=
      '<!doctype html><html><body>'+
      '<h3>ProofScript</h3>'+
      '<p><strong>'+proofText+'</strong></p>'+
      goalText+
      '<p>'+statusText+'</p>'+
      '<hr><p><small>Proof authority: pskernel. '+
      'Cursor-sensitive tactic snapshots are not implemented yet.</small></p>'+
      '</body></html>';
  }
}

function renderGoalLocal(local){
  const rendered=local.name+' : '+local.type;
  if(local.binderInfo==='implicit')return '{'+rendered+'}';
  if(local.binderInfo==='strictImplicit')return '{{'+rendered+'}}';
  if(local.binderInfo==='instImplicit')return '['+rendered+']';
  return rendered;
}

function escapeHtml(value){
  return String(value)
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;');
}

module.exports={InfoviewProvider};
