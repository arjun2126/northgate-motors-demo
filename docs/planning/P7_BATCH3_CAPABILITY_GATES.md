# P7-15/P7-16/P7-18 — native capability and authorization gates

**Final deployment update:** NG_Case_Triage is now deployed under separate approval, with native
readback confirming Draft and no active version. No agent/prompt execution or feature enablement.
Earlier local-only wording below is the implementation baseline; all runtime/identity/usage/
Data Cloud/portal gates remain. Current evidence: `evidence/P7/P7_FINAL_DEPLOYMENT.md`.

Read-only inventory/settings retrieve `09Saj00000mm9AEEAY`, observed 2026-10-26 UTC, is recorded in
`evidence/P7/BATCH3_CAPABILITY_INSPECTION.json` and the evidence-only settings readback directory.
No enablement, publication, permissions, prompts, ingestion or site/user configuration was changed.

## P7-15 — partial local implementation, not an agent demo

CONFIRMED — raw retrieved flags:

```json
{"enableEinsteinGptPlatform":"true","enableEinsteinGptCopilot":"false","enableAgentPlatform":"false","enableBots":"false"}
```

Native GenAiPromptTemplate metadata is supported; none existed in the inventory. The local
NG_Case_Triage Flex template has one Draft version and no activeVersionIdentifier or activation
metadata. It accepts only a Case input and merges Subject/Status/Priority, treats supplied text
as data, requests a bounded advisor summary and explicitly performs no action. No broad action
catalog, Apex call, automation, Knowledge grounding or permission grant is introduced.

Its shape reuses Salesforce's trailheadapps/coral-cloud native Flex-template example:
`cc-employee-app/main/default/genAiPromptTemplates/Generate_Social_Media_Posts.genAiPromptTemplate-meta.xml`.
The model reference sfdc_ai__DefaultOpenAIGPT4OmniMini is an example-supported native default
reference, not proof of runtime availability, credits, quota or permission. Global template
visibility is metadata visibility, not unauthenticated access or a public agent.

Scoped check-only `0Afaj00000p8MduCAE` accepted 1/1 with no tests, warnings or prompt execution.
The template was not deployed/activated. There is no agent: Agent Platform/Copilot/Bots are
disabled and native Bot/GenAiPlannerBundle types were not listed. Do not label a template or a
mock response as a functioning native agent.

Remaining owner decisions/actions: approve native Agentforce enablement/capability inspection,
actual internal Service identity/CRUD/FLS and model/usage limits; then authorize the agent's
read-only topic/actions and bounded prompt execution. Actual scoped grounding and positive/
negative access and measured usage remain acceptance gates. Knowledge inventory has ten Drafts
and no published articles; P6-E08 publication/reader decisions remain separate. No Knowledge
publication, ~150-request/hour claim or simulated Flow fallback is inferred from this build.

## P7-16 — blocked before native ingestion/identity build

CONFIRMED — raw retrieved flag and stream count:

```json
{"enableCustomerDataPlatform":"false"}
[{"total":0}]
```

DataStream object exposure is not an enabled Data Cloud tenant/space. DataSpace was not exposed
in the current object inventory. The historical 10 GB/one-space claim and included credit/quota
limits are not verified runtime entitlements. No ingestion, identity rules, data export or CRM
merge is authorized or executed. Do not create a custom duplicate CRM model to simulate Data Cloud.

Next: owner authorizes enablement/provisioning and confirms space/credits/limits and an approved
synthetic source/identity mapping. Then prepare exact native ingestion/identity metadata against
that real space, obtain data-ingestion approval, and test known match plus false-match denial,
lineage and measured limits. No scheduler or automatic refresh is implied. No Data Cloud metadata
is prepared with invented space/connector IDs.

## P7-18 — licenses exist, enabled site/security model does not

CONFIRMED — raw retrieved flag:

```json
{"enableNetworksEnabled":"false"}
```

Network metadata/object was unavailable; Site count is zero and CustomSite inventory is empty.
Live license counts show Customer Community, Customer Community Plus and Partner Community each
five total/zero used, External Identity nine/zero used. This corrects the old assumption that
External Identity is the only possible entitlement; it does not prove per-object business access.

Next: owner approves Digital Experiences enablement/domain, the minimal suitable external-user
license/profile, one/two existing Contact/Account identities and a login-only sharing model.
Verify each object's license/CRUD/FLS/external sharing plus relationship anchoring before code.
Then prepare the smallest real LWC/Apex seed, obtain deployment/user/site approvals, and prove
own-history/appointment access plus guest/cross-customer denial as actual external users.

Do not grant broad direct Vehicle/Loyalty access, use administrator context as external proof,
choose system-mode access to bypass a license limit, create a new Flow, enable a site or replace
the agreed LWC/Experience architecture with React. Phase 8's eleven blocks remain separate.
No portal source is fabricated before these pre-build security dependencies are resolved.

## Common state

The new draft template is the only current Batch 3 Salesforce metadata approval scope. There is
no live agent, ingestion or portal demo and no fabricated screenshot. Owner disposition/approval
is required for each remaining gate. Batch 1 deferred acceptance and Phase 6 exceptions remain;
neither Batch 1 nor deployed Batch 2 is owner-accepted. See the P7-17 wrapper documentation for
the separately outstanding clean-checkout/full-release gate.
