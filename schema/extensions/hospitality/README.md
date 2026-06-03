
## Minimum for your first integration

**Hospitality BPP (food menu-item, menu-item-order pattern):** You must implement at minimum `menu-item/v1` (or `fnb-menu-item/v1`) plus `commitment/v1`, `consideration/v1`, and `performance/v1` to pass ONIX validation. `contract/v1` is required after `/confirm`.

**Hospitality BAP (food ordering app):** You must be able to read `menu-item/v1` (or `fnb-menu-item/v1`), `offer/v1`, and `consideration/v1`.

# ION Hospitality Extension Packs

Hospitality sector (Layer 5) attribute packs. Covers time-bounded reservations and prepared food menu-item.

**Sector principle:** buyer reserves or consumes an experience, not a physical good.

## Active packs

| Pack | CRC | Attaches to | Status |
|---|---|---|---|
| `menu-item/v1` | `HSC-restaurant-ordering` | `Resource.resourceAttributes` | **ACTIVE** — food menu-item and online ordering |

## Reserved packs (working groups pending)

| Pack | CRC | What it will cover |
|---|---|---|
| `accommodation/v1` | `HSC-accommodation` | Hotel rooms, villas, homestays, serviced apartments |
| `restaurant/v1` | `HSC-restaurant` | Table reservations at restaurants and dining venues |
| `events/v1` | `HSC-events` | Tours, activities, attractions, entertainment, MICE |
| `wellness/v1` | `HSC-wellness` | Gym, spa, salon, fitness classes, wellness services |

## Hospitality vs Trade — food classification

Hospitality (`HSC-restaurant-ordering`) covers prepared food made to order. Trade (`TRC-food-bev`) covers packaged physical food products.

| Item | Sector | CRC |
|---|---|---|
| Nasi goreng from GoFood/GrabFood | Hospitality | `HSC-restaurant-ordering` |
| Restaurant meal for menu-item | Hospitality | `HSC-restaurant-ordering` |
| Packaged Indomie from Tokopedia | Trade | `TRC-food-bev` |
| AQUA 600ml from apotek | Trade | `TRC-food-bev` |
| Protein powder supplement | Trade | `TRC-food-bev` |

The classification test: **is the item prepared fresh after the order?** If yes → Hospitality. If it is a stocked, packaged product → Trade.
