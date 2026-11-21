# LogisticsProvider v1 overview

`LogisticsProvider` is the catalog-plane description of an organization offering
transport, forwarding, orchestration, or storage services. It tells consumers
where and how the provider can operate without duplicating identity, catalog, or
location information owned by Beckn core objects.

Core `Provider` owns the provider identifier and descriptor. Core `Catalog` owns
catalog validity. Until upstream Beckn Location has an identifier, this pack
uses the common `IdentifiableLocation` shape for operating locations that must
be referenced by logistics-specific hub records. Its flat `id`, `geo`, and
`address` layout remains compatible with Beckn Location field paths.

The generic layer is geography-neutral. The ION layer composes common Indonesian
address subdivisions and business registration, and provides Indonesian licence
and association categories without reducing credentials to status booleans.

