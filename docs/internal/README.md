# Internal work records

This directory contains repository work records created for bounded maintenance
tasks such as migrations, release construction, audits, and one-time cleanup.
These documents preserve the reasoning, inventories, validation evidence, and
execution sequence needed to understand those tasks and their commits.

Documents in this directory are not part of the normative ION specification.
They may describe historical repository layouts, temporary review states, or
decisions that were later superseded. Current protocol behavior is defined by
the applicable release artifacts, while current repository and release rules are
defined by the root documentation and accepted architecture documents.

When using an internal work record:

- check its status, date, target release, and source revisions;
- treat paths and counts as historical unless the document says otherwise;
- verify conclusions against the current release manifest and artifacts;
- do not use it as the sole authority for public schema behavior; and
- update it when it is the active record for an unfinished task.

## Records

- [`ION_Release1_Migration_Inventory.md`](ION_Release1_Migration_Inventory.md) —
  inventory, execution sequence, and results of reorganizing the original Trade
  material into the Release 1 layout.
- [`ION_Release1_Logistics_Migration_Plan.md`](ION_Release1_Logistics_Migration_Plan.md) —
  approved working plan for migrating legacy ION Logistics into the Release 1
  structure without depending on the incomplete Beckn Logistics domain model.
