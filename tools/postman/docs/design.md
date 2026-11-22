# ION Postman collection generator design

## Phase 1: deterministic collection scaffold

### Outcome and acceptance criteria

Phase 1 turns every protocol example below a release flow into exactly one
role-appropriate Postman request. It generates valid Collection v2.1 JSON,
reconstructs the release/sector/pattern-or-variant/flow hierarchy, preserves the
example payload, and produces stable output for unchanged inputs.

Invalid JSON, missing actions, unsupported actions, empty releases, ambiguous
generated request names, and unsafe output targets are blocking errors. The
generator never changes release artifacts.

### Data flow

1. `Discovery` enumerates numerically ordered `releaseN` directories and parses
   JSON only from the fixed flow-example layout.
2. `Router` assigns each example from `context.action` to the buyer or seller
   collection using explicit allowlists.
3. `CollectionBuilder` creates the Postman folder tree and request objects.
4. `AtomicWriter` writes only the two known artifact names through a temporary
   file in the destination directory.

Discovery, routing, transformation, and writing are separate so each can be
tested without invoking the command-line process.

### Mapping decisions

The fixed `flows`, version (`vN`), and `examples` path segments are omitted. The
version is omitted to match the required example path. If two versions would
therefore create the same request name in one folder, generation fails and names
both sources instead of silently choosing one.

Request names come from example filenames without `.json`. The original parsed
JSON object is pretty-printed into a raw request body. Each request uses `POST`,
sets `Content-Type: application/json`, and maps `context.action` to the URL path.
`catalog/publish` remains a two-segment path. An optional `_meta.description` is
copied into the Postman request description. Phase 1 originally retained `_meta`
in the body; the current Phase 2 transformation deliberately removes it from the
wire payload.

Phase 1 initially used one generic `baseUrl`. Phase 2 supersedes that mapping
with the required `bap_adapter_url` and `bpp_adapter_url` variables.

### Alternatives and tradeoffs

Inferring direction from filename prefixes was rejected because the payload's
`context.action` is the protocol field and exposes filename/payload mismatches.
A permissive skip for unknown actions was rejected because it would make the
generated starter kits incomplete without warning. External gems were avoided;
Ruby's JSON, pathname, option parsing, and tempfile libraries cover this phase.

### Known limitations

- Only the required buyer actions, their callbacks, and `catalog/publish` are
  supported.
- The generator does not validate payloads against OpenAPI or JSON Schema.
- It does not create Postman environments, signatures, tests, or example
  responses.
- A release directory with no flow examples blocks generation, making incomplete
  input explicit.

## Phase 2: runtime placeholders and transaction order

### Outcome and acceptance criteria

Phase 2 makes the generated collections portable between Postman environments.
Buyer requests use `bap_adapter_url`, seller-side requests use
`bpp_adapter_url`, volatile context values become placeholders, and `_meta`
authoring data is removed from wire bodies. Requests within each flow are ordered
by protocol transaction sequence rather than alphabetically.

### Transformation decisions

`PayloadTransformer` deep-copies each parsed example, removes `_meta` keys at any
depth, and then replaces the required context values. Deep copying is important:
Release 1 is immutable input, and one collection build must not affect another.

Only the `discover` action receives an independent `{{$guid}}` transaction ID.
Callbacks such as `on_discover`, catalog publication, and every other action use
`{{transaction_id}}`. All actions use `{{$guid}}` for `messageId` and
`{{$isoTimestamp}}` for `timestamp`.

The requirements name `bpp_adapter_url` as a runtime placeholder but do not
assign a default. It is therefore declared as an empty collection variable so an
environment can provide it without the generator inventing a deployment-specific
value. The other variable defaults follow the requirements verbatim.

### Ordering decisions

The explicit buyer sequence is `discover`, `select`, `init`, `confirm`, `status`,
`track`, `cancel`, `update`, `support`, `reconcile`. The Phase 1 `rate` action is
still supported and is placed after `track`; this preserves the relative order
of every explicitly listed Phase 2 action. Seller order begins with
`catalog/publish` and then follows the paired callback sequence. Multiple examples
for one action use filename order as the deterministic tie-breaker.

### Known limitations

- `bpp_adapter_url` has no repository-defined default and must be supplied by an
  environment.
- Authentication, signing, environments, and response assertions remain
  deferred.

## Phase 3: preview ordering and dynamic timestamps

Phase 3 uses Postman's built-in `{{$isoTimestamp}}` dynamic variable, removing
the custom `isoTimestamp` collection variable introduced in Phase 2. Within one
action, request names containing `_preview` receive a higher sort priority than
all non-preview examples. The remaining examples keep deterministic filename
order, so this narrowly changes only the required preview-before-actual behavior.
