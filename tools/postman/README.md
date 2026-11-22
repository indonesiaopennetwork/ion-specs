# ION Postman collection generator

This Ruby tool generates two Postman Collection v2.1 files from the protocol
examples stored below each release's `flows/` directory:

- `IONBuyerAppStarter.postman_collection.json` contains BAP requests to BPPs or
  the discovery service.
- `IONSellerAppStarter.postman_collection.json` contains BPP/discovery-service
  callbacks to BAPs and catalog publication.

The generated files are local build artifacts and are ignored by Git.

## Requirements

Ruby 2.6 or newer is sufficient. The generator uses only the Ruby standard
library and has no installation step.

## Generate the collections

From this directory:

```bash
ruby generate_collections.rb
```

By default the command reads the repository's `releases/` directory and writes
both collections here. Use explicit paths when operating on fixtures or another
checkout:

```bash
ruby generate_collections.rb --releases ../../releases --output-dir .
```

Run `ruby generate_collections.rb --help` for all options. Generation is
deterministic and replaces only the two known output filenames, using atomic
writes. A symlink or non-file at either output path is rejected.

Buyer requests target `{{bap_adapter_url}}/<context.action>`, and seller-side
requests target `{{bpp_adapter_url}}/<context.action>`. Environment variables
can override the collection defaults for each deployment.

## Phase 1 behavior

The source layout:

```text
releases/releaseN/flows/<sector>/{patterns,variants}/<flow>/vN/examples/*.json
```

becomes this Postman folder layout:

```text
releaseN/<sector>/{patterns,variants}/<flow>/<request>
```

Buyer actions are `discover`, `select`, `init`, `confirm`, `status`, `track`,
`rate`, `support`, `cancel`, `update`, and `reconcile`. Seller-side actions are
their `on_` callbacks plus `catalog/publish`.

## Phase 2 placeholders and ordering

Generated request bodies omit every `_meta` key and replace these context fields
with Postman placeholders: `networkId`, `bapId`, `bapUri`, `bppId`, `bppUri`,
`transactionId`, `messageId`, and `timestamp`. A `discover` request uses
`{{$guid}}` for `transactionId`; all other requests use `{{transaction_id}}`.
Every request uses `{{$guid}}` for `messageId` and `{{$isoTimestamp}}` for its
timestamp.

Both collections declare:

| Variable | Collection default |
|---|---|
| `bap_adapter_url` | `http://localhost:8081/bap/caller` |
| `bpp_adapter_url` | Empty; supply through the active environment |
| `bap_id` | Empty |
| `base_url` | Empty |
| `bap_uri` | `{{base_url}}/bap/receiver` |
| `bpp_id` | Empty |
| `bpp_uri` | `{{base_url}}/bpp/receiver` |
| `networkId` | Empty |
| `transaction_id` | Empty |
| `bap_base_url` | `http://localhost:8081` |
Requests within a flow follow transaction order. Same-action variants, such as
multiple discovery or status examples, are ordered by request name, except that
preview messages are placed before their actual messages. Phase 2 does not yet
add authentication, signing scripts, environments, or response assertions.

## Phase 3 fixes

Preview examples such as `cancel_preview` and `update_preview` are emitted before
the corresponding actual messages. Timestamps use Postman's built-in dynamic
variable `{{$isoTimestamp}}`, so no custom timestamp environment variable is
required.

## Verify

Run the complete tool suite:

```bash
ruby -Itest -e 'Dir["test/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

Then exercise the generator against the repository data and parse both outputs:

```bash
ruby generate_collections.rb
ruby -rjson -e 'ARGV.each { |path| JSON.parse(File.read(path)); puts "valid JSON: #{path}" }' \
  IONBuyerAppStarter.postman_collection.json \
  IONSellerAppStarter.postman_collection.json
```
