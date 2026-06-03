# ION Tourism sector flows

Flow specifications for the tourism sector on ION.

**Status:** Planned — flow design pending sector working group decisions.

When defined, flows here will follow the same structure as `flows/trade/` with `patterns/` and `variants/` per commerce pattern.

## If you need tourism on ION now

The tourism working group has not yet ratified its flow patterns. In the interim:

1. **Contact the ION Council** to register interest and join the tourism working group discussion.
2. **Use core packs as a foundation.** The cross-sector packs in `schema/extensions/core/` (address, identity, payment, tax, participant) apply to every sector including tourism.
3. **Use a custom overlay.** For fields specific to your tourism use case that core packs do not cover, you may declare them using a custom `context.jsonld` and `vocab.jsonld` on your own infrastructure. These should not use the `ion:` IRI prefix — use your own namespace.

Once the tourism working group ratifies patterns, this folder will be populated with the same pattern/variant structure as `flows/trade/`.
