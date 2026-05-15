# ION Hospitality Extension Packs

Hospitality sector (Layer 5) attribute packs. Covers time-bounded reservations and prepared food delivery.

**Sector principle:** buyer reserves or consumes an experience, not a physical good.

## Active packs

| Pack | CRC | Attaches to | Status |
|---|---|---|---|
| `fnb-delivery/v1` | `HSC-fnb-delivery` | `Resource.resourceAttributes` | **ACTIVE** — food delivery and online ordering |

## Reserved packs (working groups pending)

| Pack | CRC | What it will cover |
|---|---|---|
| `accommodation/v1` | `HSC-accommodation` | Hotel rooms, villas, homestays, serviced apartments |
| `restaurant/v1` | `HSC-restaurant` | Table reservations at restaurants and dining venues |
| `events/v1` | `HSC-events` | Tours, activities, attractions, entertainment, MICE |
| `wellness/v1` | `HSC-wellness` | Gym, spa, salon, fitness classes, wellness services |

## Hospitality vs Trade — food classification

Hospitality (`HSC-fnb-delivery`) covers prepared food made to order. Trade (`TRC-food-bev`) covers packaged physical food products.

| Item | Sector | CRC |
|---|---|---|
| Nasi goreng from GoFood/GrabFood | Hospitality | `HSC-fnb-delivery` |
| Restaurant meal for delivery | Hospitality | `HSC-fnb-delivery` |
| Packaged Indomie from Tokopedia | Trade | `TRC-food-bev` |
| AQUA 600ml from apotek | Trade | `TRC-food-bev` |
| Protein powder supplement | Trade | `TRC-food-bev` |

The classification test: **is the item prepared fresh after the order?** If yes → Hospitality. If it is a stocked, packaged product → Trade.
