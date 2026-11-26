"""Local extension validation, not Beckn/ONIX conformance."""
import json,pathlib,hashlib,base64,uuid
from jsonschema import Draft202012Validator,FormatChecker
p=pathlib.Path(__file__).parent
schemas={x.parent.parent.name:json.loads(x.read_text()) for x in (p/'schemas').glob('*/v1/schema.json')}
errors=[]; known=[]; count=0; messages=0; pairs=0
for seq in sorted(p.glob('flows/*/sequence.json')):
 requests={}
 for step in json.loads(seq.read_text())['steps']:
  f=seq.parent/step['file']; raw=f.read_bytes(); obj=json.loads(raw); c=obj['context']; messages+=1
  uuid.UUID(c['transactionId']);uuid.UUID(c['messageId'])
  assert c['action']==step['action']
  if not c['action'].startswith('on_'): requests[c['messageId']]=raw
  elif c['messageId'] in requests:
   assert c['requestDigest']['digest']=='BLAKE-512='+base64.b64encode(hashlib.blake2b(requests[c['messageId']]).digest()).decode();pairs+=1
  def walk(x):
   global count
   if isinstance(x,dict):
    if x.get('@type','').startswith('ion:IONHospitality'):
     key=x['@type'].replace('ion:ION','');count+=1
     for e in Draft202012Validator(schemas[key],format_checker=FormatChecker()).iter_errors(x):
      row=(f.parent.name,f.name,key,e.message)
      if f.name=='06_on_init.json' and key=='HospitalityContract' and list(e.path)==['acceptedPolicies'] and e.validator=='minItems':known.append(row)
      else:errors.append(row)
    for v in x.values():walk(v)
   elif isinstance(x,list):
    for v in x:walk(v)
  walk(obj)
print(f'Messages: {messages}; correlated callback digests: {pairs}; extension occurrences: {count}; known schema violations: {len(known)}; unexpected schema violations: {len(errors)}')
for row in known+errors:print(*row,sep=' | ')
print('Known violations are NOT passes. Core API, signatures, policy resolution, Rego and runtime semantics not validated.')
raise SystemExit(1 if errors else 0)
