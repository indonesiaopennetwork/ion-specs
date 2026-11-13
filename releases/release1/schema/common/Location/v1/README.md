# ION Location v1

ION-maintained Location compatible with `ion-beckn.yaml`. A Location contains
at least one of `geo` or `address`; both may be supplied. Its `address` uses the
common ION Address and therefore supports `addressAttributes`.

Use this shape where an extension pack needs the ION-maintained Address. Keep
using pinned vendored Location schemas where no ION address extension is needed.
