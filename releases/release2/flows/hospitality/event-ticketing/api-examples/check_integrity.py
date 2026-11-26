"""Extra fixture integrity tests; not an ION protocol or runtime validator."""
from pathlib import Path
import json,hashlib,base64,copy,yaml
from jsonschema import Draft202012Validator
R=Path(__file__).parent
load=lambda p:json.loads(p.read_text())
D=lambda b:'BLAKE-512='+base64.b64encode(hashlib.blake2b(b).digest()).decode()
S={p.parent.parent.name:load(p) for p in (R/'schemas').glob('*/v1/schema.json')}
pol={}
for p in (R/'policies').rglob('*.yaml'):
 x=yaml.safe_load(p.read_text());pol[x['iri']]=(x['version'],hashlib.sha256(p.read_bytes()).hexdigest())
def walk(x):
 if isinstance(x,dict):
  yield x
  for v in x.values():yield from walk(v)
 elif isinstance(x,list):
  for v in x:yield from walk(v)
def bags(x,k):return [v for v in walk(x) if v.get('@type')=='ion:IONHospitality'+k]
checks=0
for p in sorted((R/'flows').glob('SC*')):
 seq=load(p/'sequence.json'); previews={};requests={}
 for step in seq['steps']:
  f=p/step['file'];o=load(f);c=o['context'];a=c['action'];mid=c['messageId']
  if a.startswith('on_') and mid in requests:
   assert D(requests[mid])==c['requestDigest']['digest'];checks+=1
   if a in ['on_update','on_cancel'] and json.loads(requests[mid])['context'].get('try') is True:previews[a[3:]]=f.read_bytes()
  elif not a.startswith('on_'):
   if c.get('try') is False and a in ['cancel','update']:
    assert D(previews[a])==c['requestDigest']['digest'],(p.name,f.name);checks+=1
   requests[mid]=f.read_bytes()
  for x in bags(o,'Contract'):
   for v in x.get('offeredPolicies',[])+x.get('acceptedPolicies',[]):
    assert pol[v['policyRef']]==(v['version'],v['digest']),(p.name,f.name,v);checks+=1
  for x in bags(o,'Consideration'):
   total=sum((-1 if v['kind']=='DISCOUNT' else 1)*v['amountMinor'] for v in x['components'] if not v['included']);assert total==x['payableMinor'],(p.name,f.name,total,x['payableMinor']);checks+=1
  if a in ['on_confirm','on_status','on_cancel','on_update'] and 'contract' in o.get('message',{}):
   ct=o['message']['contract'];ts=bags(ct,'Performance');assert len({t['ticketId'] for t in ts})==len(ts),(p.name,f.name);checks+=1
   for t in ts:
    for al in t['allocations']:
     if al.get('seatIds'):assert len(al['seatIds'])==al['admissions'],(p.name,f.name);checks+=1
   for v in bags(ct,'Consideration'):
    assert sum(r['amountMinor'] for r in v.get('refunds',[]))<=v['payableMinor'],(p.name,f.name);checks+=1
# focused negative tests for new semantics
fixture=lambda sc,f,k:bags(load(R/'flows'/sc/f),k)[0]
def reject(k,x):
 global checks
 assert not Draft202012Validator(S['Hospitality'+k]).is_valid(x),k;checks+=1
x=fixture('SC03','08_on_confirm.json','Contract');x['acceptedPolicies']=[];reject('Contract',x)
x=fixture('SC04','06_on_init.json','Commitment');x['allocations'][0].pop('seatIds');reject('Commitment',x)
x=fixture('SC35','10_on_status.json','Consideration');x['refunds'][0].pop('attemptRef');reject('Consideration',x)
x=fixture('SC27','14_on_cancel.json','Consideration');x['refunds'][0].pop('ticketIds');reject('Consideration',x)
x=fixture('SC29','11_on_update.json','Contract');x['change']['decision']='ACCEPTED';reject('Contract',x)
x=fixture('SC30','11_on_update.json','Contract');x['change'].pop('proposedSessions');reject('Contract',x)
assert {p.name for p in (R/'flows').glob('SC*')}=={f'SC{i:02}' for i in range(1,45) if i!=24};checks+=1
print(f'PASS: {checks} integrity assertions, including six new schema rejection cases. Local fixtures only.')
