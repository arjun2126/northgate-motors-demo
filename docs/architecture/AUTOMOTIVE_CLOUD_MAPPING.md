# P7-19 — Automotive Cloud concept mapping

Northgate is a custom dealership demonstration on standard Salesforce CRM, not an Automotive
Cloud installation. This one-page mapping describes licensed concepts; it creates no objects,
package, entitlement, migration or Automotive Cloud integration. Product availability and exact
target schema must be verified before any future licensed implementation.

| Current Northgate source | Automotive Cloud / adjacent licensed concept | Actual boundary |
|---|---|---|
| Vehicle__c, VIN__c, VinValidator, reservation guard | Vehicle: individual vehicle identity and lifecycle | Custom inventory with checksum/reservation rules, not an OEM vehicle master or telematics feed |
| Vehicle_Model__c, Product2, PricebookEntry | Vehicle Definition and product/trim configuration | Fictional make/model catalog plus standard products/prices; no factory build/configurator or licensed definition migration |
| Vehicle photo formula/model path and NG_VehicleImages | Vehicle imagery/catalog presentation | Thirty licensed stock illustrations; no claim of exact OEM/year identity, generated photography or manufacturer endorsement |
| Rooftop__c, Staff__c, existing User roles | Dealer/retailer network, locations and staff responsibilities | Four custom rooftops and reporting staff; Staff rows are not licensed user identities or dealer-network access |
| Account/Contact, Opportunity.Vehicle__c, delivery/enrollment links | Household/customer and vehicle ownership/driver relationships; Asset where appropriate | Existing CRM relationships are not a complete vehicle ownership/usage history or an Asset conversion |
| Opportunity, standard Quote/QuoteLineItem, CP2 services | Vehicle sale/offer and Revenue Cloud/CPQ integration | Existing custom primary-vehicle pricing, trade-in checks and native approvals remain authoritative; no licensed CPQ/order engine |
| Financing__c, Trade_In__c | Finance offer/application and trade-in valuation seams | Custom previews/status/approvals, not lender origination, credit decisions, payment settlement or external valuation |
| Service_Visit__c, Test_Drive__c, standard Case/SLA | Aftersales service; adjacent Work Order/Service Appointment/Field Service concepts | Custom daily capacity/intake/history and native Case/SLA; no dispatch optimization, technician skills, work-order migration or mobile Field Service |
| Consent__c, CampaignMember, custom loyalty ledger | Customer engagement, consent and loyalty integrations | Custom simulations, not native consent compliance proof, Marketing Cloud delivery or licensed Loyalty Management |
| NG_Rooftops Sales Territory model | Sales account-sharing alignment | Native Sales Territories in Planning with zero assignments; not a Field Service territory or a licensed dealer-network hierarchy |

The largest gaps are authoritative OEM identity/vehicle definitions, complete ownership history,
warranty/claims/recall processing, dealer/manufacturer synchronization, order/payment/finance
integration, telematics and production entitlement/security. No existing custom object is an
automatic equivalent of a licensed object merely because its label is similar.

A future migration must first verify licensing/schema, external IDs/ownership, historical
provenance, consent, per-persona access and coexistence with CP2/approvals. Map and validate
records in a separately approved plan; do not rename objects, backfill ownership, recalculate
loyalty, enable features or change the accepted dealership workflows for this concept note.
Related actual seams: SIMULATION_CPQ.md, SIMULATION_FIELD_SERVICE.md, SIMULATION_LOYALTY.md,
SIMULATION_NURTURE.md and SIMULATION_INTEGRATION.md.
