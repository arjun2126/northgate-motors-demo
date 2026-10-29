# Phase 6 Knowledge draft pack

P6-15 contains ten original internal article drafts in `P6_ARTICLE_DRAFTS.json`, including
service FAQs, recall, buying, financing, delivery, loyalty and contact preferences. Each draft
includes a stable URL name, summary, body, category and suggested Case use. The JSON remains the
local source; exactly ten derived internal Draft articles and ten category selections now exist
in ng-demo. They are not approved policy, published articles or an access fallback.

## Current verified feature state

The owner confirmed Enable Lightning Knowledge in the browser. Read-only retrieval
`09Saj00000mhMEYEA2` on 2026-10-25 UTC confirms:

```xml
<enableKnowledge>true</enableKnowledge>
<enableLightningKnowledge>true</enableLightningKnowledge>
```

Knowledge__kav, Knowledge__DataCategorySelection, KnowledgeArticle, KnowledgeArticleVersion and
CaseArticle are now available. The earlier Batch 4 disabled-feature finding is historical and
superseded; no additional Knowledge enablement is needed. No setting was changed by this check.

The initial continuation found Title (255), UrlName (255), Summary (1000) and en_US Language,
but no body field or category group. The subsequent authorized deployment now provides Body__c,
the active category group and a new unassigned layout. The original Knowledge Layout is unchanged.
The author-access blocker was resolved by the explicitly approved Body-only permission set
PS_Knowledge_Draft_Author assigned only to the existing administrator. Direct REST describe now
exposes Body__c as createable/updateable. All ten approved Drafts were imported and verified.
CaseArticle creation is exposed by the API;
`enableKnowledgeCaseRL=false` means the Case related-list presentation remains a separate UI
configuration step. Standard Knowledge sharing is enabled and is not changed by this package.

Historical read-only evidence: `evidence/P6/P6_15_KNOWLEDGE_CONTINUATION_2026-10-25.md`.
Current execution/readback: `evidence/P6/PHASE6_FINAL_BLOCKER_REPAIR_2026-10-25.md`.

## Deployed metadata and completed Draft import

`manifest/p6-15-knowledge-prepare.xml` contains exactly three components:

1. `Knowledge__kav.Body__c`: Html/Rich Text Area, 32,768 characters, 20 visible lines.
2. `Northgate_Knowledge`: native active category group, root All; Service, Buying, Financing,
   Ownership and Safety children; KnowledgeArticleVersion usage. No visibility grants.
3. `Knowledge__kav-NG Internal Article Layout`: new unassigned layout with Title, UrlName,
   Summary and Body__c. The current layout is not overwritten or assigned.

Validation `0Afaj00000p27o1CAA` and deployment `0Afaj00000p27rFCAQ` succeeded three/three,
zero errors. NoTestRun was used for this non-Apex package; successful Batch 4 tests were not
repeated. Current readback confirms the field and active categories. No Knowledge settings,
profile, permission set, existing app/page or Case layout was included or assigned.

The administrator's existing Knowledge User/article CRUD was retained. Minimum Body__c Read/Edit
was validated as 0Afaj00000p2Gg1CAE and deployed as 0Afaj00000p2EfqCAE, one/one components.
Only PS_Knowledge_Draft_Author was assigned for authorship; no profile, publication, external
channel or sharing grant. Exactly ten complete Draft articles and ten category selections were
created in one successful all-or-none request. The prior blocked attempt remains historical in
`evidence/P6/P6_15_KNOWLEDGE_EXECUTION_2026-10-25.md`.

## Import complete — do not resubmit

The local-only generator reads the existing pack and prints a REST Composite request. It has
no network client, Salesforce command, file-write operation or publication action:

```sh
python3 scripts/knowledge/prepare_p6_15_import.py
```

The approved request was submitted once to POST `/services/data/v68.0/composite`. It contained 20 subrequests
with `allOrNone=true`: ten Knowledge__kav creates and ten category-selection creates referencing
the just-created version IDs. No updates, deletes, user changes or Case attachments are included.
All twenty subresponses returned HTTP 201/success=true. No failure-path rollback was exercised
or claimed. Receipt: `evidence/P6/P6_15_IMPORT_RECEIPT_2026-10-25.json`. The ten URLs now exist;
do not replay the creation command or create another set under the completed approval.

Exact mapping:

| Draft key | Native field |
|---|---|
| title | Knowledge__kav.Title |
| urlName | Knowledge__kav.UrlName |
| summary | Knowledge__kav.Summary |
| pack language | Knowledge__kav.Language = en_US |
| body | Knowledge__kav.Body__c, HTML-escaped paragraph text |
| category | Knowledge__DataCategorySelection.DataCategoryName |
| categoryGroup | Knowledge__DataCategorySelection.DataCategoryGroupName |

PublishStatus defaults to Draft and is not createable; omit it. IsVisibleInApp is defaulted
and not createable, but describe returns no explicit default value; omit it and verify actual
internal visibility after authorized creation. Explicitly set IsVisibleInPkb,
IsVisibleInCsp and IsVisibleInPrm false. Do not call any publish endpoint. Case-use suggestions
remain in the local pack; they do not create links to arbitrary Cases.

Completed checks:

1. Confirmed target Organization and existing administrator, field access and active categories.
2. Rechecked all ten URLs in en_US Draft/Online/Archived: zero collisions immediately before POST.
3. Submitted exactly ten creates and ten selections once; all twenty responses succeeded.
4. Read back receipt IDs, Title/Summary/Language, full HTML content, Draft status, internal-only
   visibility and exactly one expected category per version. Salesforce normalized apostrophe
   entities from hex to decimal; decoded HTML matches without modifying stored content.
5. Captured both version and master IDs in
   `evidence/P6/P6_15_IMPORT_VERIFICATION_2026-10-25.json`. No matching Online/Archived version exists.

Repeatable verification is read-only:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 scripts/knowledge/verify_p6_15_import.py
```

Any additional creation, update, publication or Case attachment requires its own authorization.

## Case integration and later acceptance

Native category selections use **Knowledge__kav version Id** in ParentId. Native CaseArticle
uses **master KnowledgeArticleId**, referencing Knowledge__ka, not the version Id. Its createable
fields are CaseId, KnowledgeArticleId, ArticleLanguage and ArticleVersionNumber. Any future
attachment must use an explicitly approved accessible Case, master ID and published version;
do not bind current seed/customer Cases during preparation.

After separate UI/configuration approval, enable the Knowledge Case related list if that is
the chosen presentation, or place the native Knowledge search component through App Builder.
Use a fresh settings retrieval before any approved targeted change; do not replace the whole
Knowledge settings object with an old snapshot. Preserve existing service history and SLA UI.
App/page changes or assignments are not part of the three-component package.

Review article policy with the owner before requesting publication. Only after separate
publication/attachment authorization, verify native search and Attach Article as the actual
approved Service user. Read back CaseArticle.CaseId, KnowledgeArticleId, ArticleLanguage and
ArticleVersionNumber and capture browser evidence. Do not infer persona access from admin CRUD.

Knowledge enablement, metadata, author access and approved Draft creation are complete. The
reporting blockers were also resolved after separate owner-approved deployment/access. Current
Phase 6 is OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.
Publication/Case/browser acceptance remains separate. No publication, Case links, page activation
or external visibility expansion occurred. See `evidence/P6/PHASE6_FINAL_BLOCKER_REPAIR_2026-10-25.md`.

Focused offline check (no Batch 4 test rerun):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 scripts/tests/check_p6_15_preparation.py
```
