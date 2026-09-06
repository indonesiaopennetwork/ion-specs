# ION Transport and HTTP Signing

This document covers everything a developer needs to implement the HTTP transport layer for ION — signing outbound requests, verifying inbound messages, and understanding the synchronous ACK/callback pattern. It is derived from `beckn.yaml → components/schemas/Signature` and the ION network profile in `ion.yaml`.

---

## The two-message pattern

Every ION API call follows a strict two-message pattern. Understanding this is the first thing to get right before writing any code.

```
BPP endpoint:   POST /select          ← CN sends request
                → HTTP 200 + ACK      ← BPP acknowledges immediately (sync)
                ↓
BPP later:      POST {bapUri}/on_select  ← BPP sends callback to CN (async)
                → HTTP 200 + ACK         ← CN acknowledges callback
```

**The ACK is not the response.** The ACK is only "I received and authenticated your request." The actual response — the quote, the confirmation, the order status — arrives as a separate HTTP POST to the other party's registered callback URL. You must implement both sides: the endpoint that receives requests and sends ACKs, and the mechanism that sends callbacks to counterparty callback URLs.

Synchronous errors (invalid signature, malformed payload, missing required field) return a NACK instead of an ACK, with an `error.code` in the body. Schema validation rejections are `ION-8xxx`. See `errors/README.md`.

---

## Endpoints you implement

### If you are a BPP (seller app / provider platform)

You expose these endpoints at the URL you register as `bppUri`:

```
POST /catalog/publish     ← Catalog push to ION Catalogue Service
POST /select              ← Receive item selection from BAP
POST /init                ← Receive delivery address and payment method
POST /confirm             ← Receive binding order confirmation
POST /track               ← Receive tracking request (optional)
POST /cancel              ← Receive cancellation request
POST /update              ← Receive order update request
POST /rate                ← Receive rating from BAP
POST /support             ← Receive support channel query
POST /reconcile           ← Receive reconciliation initiation (ION extension)
POST /raise               ← Receive dispute escalation (ION extension)
POST /raise/status        ← Receive dispute status query
POST /raise/close         ← Receive dispute close
POST /raise/reopen        ← Receive dispute reopen
```

You send callbacks to `{bapUri}`:

```
POST {bapUri}/on_select
POST {bapUri}/on_init
POST {bapUri}/on_confirm
POST {bapUri}/on_track
POST {bapUri}/on_cancel
POST {bapUri}/on_update
POST {bapUri}/on_rate
POST {bapUri}/on_support
POST {bapUri}/on_status    ← Unsolicited; push on every state change
POST {bapUri}/on_reconcile
POST {bapUri}/on_raise
POST {bapUri}/on_raise/status
```

### If you are a BAP (buyer app / consumer platform)

You expose the `/on_*` endpoints above at your `bapUri`. You send requests to `{bppUri}`.

---

## HTTP signing — how it works

Every request and callback carries an `Authorization` header containing a digital signature. ION uses **Ed25519** with a **BLAKE2b-512** body digest. There are two signature formats depending on the direction.

### For requests (CN→PN) and PN-initiated callbacks

**Header name:** `Authorization`

**Wire format:**
```
Signature keyId="{keyId}",algorithm="ed25519",created="{unix_ts}",expires="{unix_ts}",headers="(created) (expires) digest",signature="{base64}"
```

**Example:**
```
Authorization: Signature keyId="ion.id/gro.ion/bap-main-key|ed25519",algorithm="ed25519",created="1714000000",expires="1714000600",headers="(created) (expires) digest",signature="BASE64ENCODED_ED25519_SIGNATURE=="
```

**Signing string** (sign these three lines with your Ed25519 private key):
```
(created): 1714000000
(expires): 1714000600
digest: BLAKE2b-512=BASE64_BODY_HASH
```

**`keyId` format:** `{namespace}/{registry}/{record}|ed25519`
- For ION sandbox: `ion.id/gro.ion/{your-bap-or-bpp-id}|ed25519`
- Or a full `dedi://` protocol URL followed by `|ed25519`

**`created` and `expires`:** Unix timestamps. `expires` must be ≥ `created`. ION recommends a 10-minute TTL (`expires = created + 600`). Requests with `expires` in the past are rejected with `ION-1001`.

**Body digest:** Hash the raw request body bytes (UTF-8, no normalisation) with BLAKE2b-512. Base64-encode the result. Prefix with `BLAKE2b-512=`.

### For PN solicited callbacks (responses to CN requests)

**Header name:** `Authorization`

**Signing string** (four lines — the fourth chains back to the CN's original request):
```
(created): 1714000050
(expires): 1714000650
digest: BLAKE2b-512=BASE64_CALLBACK_BODY_HASH
request-signature: BASE64_RAW_SIGNATURE_FROM_CN_AUTHORIZATION_HEADER
```

The `request-signature` line contains the raw Base64 Ed25519 signature value extracted verbatim from the `signature="..."` field of the CN's original `Authorization` header. This binds the callback cryptographically to the triggering request.

**`headers` attribute** must be `"(created) (expires) digest request-signature"` (note the extra field vs. the standard signature).

### The ACK response signature

Every HTTP 200 ACK response must itself carry a signature header:

**Response header name:** `Signature` (not `Authorization`)

This is an `AckSignatureHeader` — the responding party signs the ACK body to prove authenticity of the acknowledgement. Format is the same as the standard Signature.

---

## Verifying inbound signatures

When you receive a request or callback, verify before processing:

1. **Parse the `Authorization` header** — extract `keyId`, `created`, `expires`, `signature`.
2. **Reject expired requests** — if `expires < now`, return NACK `ION-1001`.
3. **Look up the public key** — resolve `keyId` against the ION network registry at `https://registry.ion.id`. The registry returns the sender's Ed25519 public key.
4. **Reconstruct the signing string** — compute BLAKE2b-512 of the raw request body; build the three-line (or four-line, for callbacks) signing string.
5. **Verify the Ed25519 signature** — verify `signature` against the signing string using the sender's public key.
6. **If verification fails** — return HTTP 401 with NACK `ION-1002`.

Do not process the request body before verifying the signature.

---

## Quick-start: signing in Python

```python
import base64, time, hashlib, json
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization

def blake2b_512_b64(body_bytes: bytes) -> str:
    """BLAKE2b-512 body digest, base64-encoded."""
    h = hashlib.blake2b(body_bytes, digest_size=64)
    return base64.b64encode(h.digest()).decode()

def sign_request(
    body: dict,
    private_key: Ed25519PrivateKey,
    key_id: str,
    ttl_seconds: int = 600
) -> str:
    """
    Sign an ION request body and return the Authorization header value.
    
    Args:
        body: The request body dict (will be serialised to JSON).
        private_key: Your Ed25519 private key.
        key_id: Your registered key ID, e.g. 'ion.id/gro.ion/my-bpp|ed25519'
        ttl_seconds: Signature validity window (default 10 minutes).
    
    Returns:
        The full Authorization header value string.
    """
    body_bytes = json.dumps(body, separators=(',', ':')).encode('utf-8')
    digest = blake2b_512_b64(body_bytes)
    
    created = int(time.time())
    expires = created + ttl_seconds
    
    signing_string = (
        f"(created): {created}\n"
        f"(expires): {expires}\n"
        f"digest: BLAKE2b-512={digest}"
    )
    
    signature_bytes = private_key.sign(signing_string.encode('utf-8'))
    signature_b64 = base64.b64encode(signature_bytes).decode()
    
    return (
        f'Signature keyId="{key_id}",'
        f'algorithm="ed25519",'
        f'created="{created}",'
        f'expires="{expires}",'
        f'headers="(created) (expires) digest",'
        f'signature="{signature_b64}"'
    )


def sign_callback(
    body: dict,
    private_key: Ed25519PrivateKey,
    key_id: str,
    cn_auth_header: str,
    ttl_seconds: int = 600
) -> str:
    """
    Sign an ION callback (PN solicited response) with the request-signature chain.
    
    Args:
        cn_auth_header: The full Authorization header from the triggering CN request.
                        The raw Base64 signature is extracted from this.
    """
    body_bytes = json.dumps(body, separators=(',', ':')).encode('utf-8')
    digest = blake2b_512_b64(body_bytes)
    
    created = int(time.time())
    expires = created + ttl_seconds
    
    # Extract raw signature from CN's Authorization header
    import re
    m = re.search(r'signature="([^"]+)"', cn_auth_header)
    cn_raw_sig = m.group(1) if m else ""
    
    signing_string = (
        f"(created): {created}\n"
        f"(expires): {expires}\n"
        f"digest: BLAKE2b-512={digest}\n"
        f"request-signature: {cn_raw_sig}"
    )
    
    signature_bytes = private_key.sign(signing_string.encode('utf-8'))
    signature_b64 = base64.b64encode(signature_bytes).decode()
    
    return (
        f'Signature keyId="{key_id}",'
        f'algorithm="ed25519",'
        f'created="{created}",'
        f'expires="{expires}",'
        f'headers="(created) (expires) digest request-signature",'
        f'signature="{signature_b64}"'
    )


def verify_inbound(
    body_bytes: bytes,
    auth_header: str,
    public_key_bytes: bytes  # fetched from registry.ion.id
) -> bool:
    """Verify an inbound ION request signature."""
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    from cryptography.exceptions import InvalidSignature
    import re
    
    created = int(re.search(r'created="(\d+)"', auth_header).group(1))
    expires = int(re.search(r'expires="(\d+)"', auth_header).group(1))
    sig_b64 = re.search(r'signature="([^"]+)"', auth_header).group(1)
    headers_field = re.search(r'headers="([^"]+)"', auth_header).group(1)
    
    if expires < time.time():
        return False  # expired
    
    digest = blake2b_512_b64(body_bytes)
    signing_lines = [
        f"(created): {created}",
        f"(expires): {expires}",
        f"digest: BLAKE2b-512={digest}",
    ]
    
    if "request-signature" in headers_field:
        cn_sig = re.search(r'request-signature: ([^\n]+)', auth_header)
        if cn_sig:
            signing_lines.append(f"request-signature: {cn_sig.group(1)}")
    
    signing_string = "\n".join(signing_lines)
    
    try:
        pub_key = Ed25519PublicKey.from_public_bytes(public_key_bytes)
        pub_key.verify(
            base64.b64decode(sig_b64),
            signing_string.encode('utf-8')
        )
        return True
    except InvalidSignature:
        return False
```

**Dependencies:** `pip install cryptography`

---

## Error codes for transport failures

| Code | Meaning | Fix |
|---|---|---|
| `ION-1001` | Signature expired (`expires < now`) | Regenerate signature with current timestamp |
| `ION-1002` | Signature verification failed | Check key registration, signing string construction |
| `ION-1003` | Missing `Authorization` header | Add the header to every request |
| `ION-1004` | Malformed signature format | Check header format against the pattern above |
| `ION-1005` | Unknown `keyId` | Ensure your key is registered on the ION network registry |

---

## ION network endpoints (sandbox)

| Service | URL |
|---|---|
| Network registry (key lookup) | `https://registry.ion.id` |
| Catalogue publish | `https://catalog.ion.id/catalog/publish` |
| Discovery service | `https://discover.ion.id` |
| Sandbox BPP gateway | Provided at participant registration |

> **Note:** Production endpoint URLs are provided at participant registration. This spec document covers the sandbox environment (`ion.yaml → x-ion-profile.environment: sandbox`). Do not hardcode these URLs — resolve them from the network registry at startup.

---

## ION network error codes

All transport errors use the `ION-1xxx` range. See `errors/registry.json` for the full list with resolution guidance.

```bash
# Look up a specific error code
jq '.errors[] | select(.code == "ION-1002")' errors/registry.json
```
