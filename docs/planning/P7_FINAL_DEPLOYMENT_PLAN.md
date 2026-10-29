# Phase 7 final deployment and Phase 8 handoff plan

Owner authorizes only the already validated Batch 3 one-Draft-prompt scope and Batch 4
photo-header/page scope in ng-demo `00Daj00001Ae3iWEAR`. No prompt/page activation, settings,
permissions, users, territory/Account associations, business-data writes or Git release actions.
Phase 8 preparation is documentation only; no Phase 8 implementation or deployment.

1. Confirm exact manifests and saved source hashes. Capture read-only Vehicle object/all-app
   assignment metadata, six relevant settings, permissions/user-role mappings, existing trigger
   hashes and ID/modification-time fingerprints of current project business records. Store only
   fingerprints/counts for business data, not customer fields. Retrieval stays outside force-app.
2. Try each explicitly named Quick Deploy once; only an explicit CannotQuickDeployError permits
   the owner-authorized standard NoTestRun deployment of the same manifest. Stop on any actual
   deployment failure; never expand scope or repair unrelated metadata. Batch 3 must succeed first.
3. Retrieve deployed definitions read-only. Verify Draft/inactive prompt, header/page existence,
   unchanged Vehicle assignments/settings/permissions/data fingerprints and Planning territory.
   Do not execute the prompt, assign/activate pages or rerun previous tests.
4. Record all 23 Phase 7 block states and carried acceptance exceptions separately from deployed
   metadata. Capture Git working-tree/staging/HEAD and read-only remote main comparison without
   fetch, stage, commit or push. Do not declare Phase 7 owner acceptance or a clean release.
5. Read all eleven Phase 8 requirements and propose three dependency-correct implementation
   blocks with explicit identity/license/sharing/enablement decisions. P7-18 is not an existing
   portal seed; document that starting dependency rather than assuming a site exists.

Files: fixed deployment/readback helper under scripts/tests; sanitized receipts under evidence/P7;
closeout/Phase 8 preparation under docs/planning; current handoff/backlog/README status updates.
