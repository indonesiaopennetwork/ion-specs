# ION Postman Collection Generator Requirements

## Objective

Build a Ruby tool that generates Postman collections from the protocol examples
under the repository's `releases/` directory. Ruby is required because it is
already part of the repository toolchain.

The tool must generate these two files:

- `IONBuyerAppStarter.postman_collection.json`
- `IONSellerAppStarter.postman_collection.json`

Both files are generated artifacts and must be listed in `.gitignore`.

## Source discovery and collection structure

Release flow examples use this repository structure:

```text
releases/
  releaseN/
    flows/
      <sector>/
        patterns|variants/
          <flow-name>/
            <version>/
              examples/
                <example>.json
```

The generated collections must mirror the meaningful parts of that hierarchy
while omitting the fixed `flows`, version, and `examples` path segments. For
example:

```text
ION Starter Kit Buyer App/release1/trade/patterns/storefront/<request>
```

Each supported example under the source `examples/` directory becomes a request
inside the corresponding Postman folder.

## Collection routing

The Buyer App collection contains BAP-to-BPP or BAP-to-Discovery-Service actions:

```text
discover
select
init
confirm
status
track
rate
cancel
update
support
reconcile
```

The Seller App collection contains the corresponding BPP/Discovery-Service-to-BAP
callbacks and catalog publication:

```text
catalog/publish
on_discover
on_select
on_init
on_confirm
on_status
on_track
on_rate
on_cancel
on_update
on_support
on_reconcile
```

## Request endpoints

Buyer App requests must target the BAP adapter:

```text
{{bap_adapter_url}}/<action>
```

Examples include `{{bap_adapter_url}}/discover` and
`{{bap_adapter_url}}/select`.

Seller App requests must target the BPP adapter:

```text
{{bpp_adapter_url}}/<action>
```

Examples include `{{bpp_adapter_url}}/on_select` and
`{{bpp_adapter_url}}/on_status`.

Adapter variables may be overridden by the active Postman environment.

## Request body transformation

The generated request body must omit every `_meta` key. Within `context`, the
following fields must use Postman variables:

| Context field | Generated value |
|---|---|
| `networkId` | `{{networkId}}` |
| `bapId` | `{{bap_id}}` |
| `bapUri` | `{{bap_uri}}` |
| `bppId` | `{{bpp_id}}` |
| `bppUri` | `{{bpp_uri}}` |
| `transactionId` | `{{$guid}}` for `discover`; `{{transaction_id}}` for every other action |
| `messageId` | `{{$guid}}` |
| `timestamp` | `{{$isoTimestamp}}` |

All other example content must remain available in the generated request body.

## Collection variables

Both collections must declare these variables:

| Variable | Default value |
|---|---|
| `bap_adapter_url` | `http://localhost:8081/bap/caller` |
| `bpp_adapter_url` | Empty |
| `bap_id` | Empty |
| `base_url` | Empty |
| `bap_uri` | `{{base_url}}/bap/receiver` |
| `bpp_id` | Empty |
| `bpp_uri` | `{{base_url}}/bpp/receiver` |
| `networkId` | Empty |
| `transaction_id` | Empty |
| `bap_base_url` | `http://localhost:8081` |

`{{$guid}}` and `{{$isoTimestamp}}` are Postman dynamic variables and must not be
declared as custom collection variables.

## Request ordering

Requests within each flow folder must follow Beckn transaction order.

Buyer App order:

```text
discover
select
init
confirm
status
track
rate
cancel
update
support
reconcile
```

Seller App order:

```text
catalog/publish
on_discover
on_select
on_init
on_confirm
on_status
on_track
on_rate
on_cancel
on_update
on_support
on_reconcile
```

When an action has both preview and actual examples, preview requests such as
`cancel_preview` and `update_preview` must appear before the corresponding actual
requests. Other examples for the same action must use deterministic ordering.
