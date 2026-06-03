# ION Mobility Extension Packs

**Status:** Planned — schema design pending sector working group decisions.

## If you need mobility on ION now

The mobility working group has not yet ratified its schema packs. In the interim:

1. **Contact the ION Council** to register interest and join the mobility working group discussion.
2. **Use core packs.** `schema/extensions/core/` packs (address, identity, payment, tax, participant) apply to every sector and can be used immediately.
3. **Use a custom overlay.** For mobility-specific fields, publish your own `context.jsonld` and `vocab.jsonld` on your own infrastructure using your own IRI namespace — not the `ion:` prefix.

Once the mobility working group ratifies its pack definitions, this directory will be populated with pack folders following the same structure as `schema/extensions/trade/`.
