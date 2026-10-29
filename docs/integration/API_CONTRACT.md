# P7-03/P7-04 — mock VIN preview contract

This is a deterministic simulation, not a manufacturer VIN decoder, a paid service or inventory
enrichment. Existing VinValidator remains the checksum authority. No VIN/model/image/price fields
are written. The client is `VinDecoderService.decode`; the optional local provider is
`scripts/integration/vin_mock_server.py`. No credential metadata, secrets or live endpoint was
created, and no external service was contacted.

## Request

`GET <Named Credential NG_VIN_Mock base URL>/decode/{VIN}` with Accept: application/json.
The client trims/uppercases input, enforces 17 allowed characters and VinValidator checksum,
requires Decode_Inventory_VIN and uses a 5000 ms timeout. No retry or mutation occurs.
Only the VIN is transmitted; no Contact, invoice, financing or consent data is included.

Fictional test VIN: `4NDM4NJ96V8L0KGCJ` (existing repository fixture, not a real vehicle).

## Success response

```json
{"vin":"4NDM4NJ96V8L0KGCJ","make":"Aurelia","model":"Fictional Sedan","year":2026,"bodyStyle":"Sedan","simulation":true}
```

The local provider uses the current year, not a decoded model year; every successful response
is explicitly simulation=true. It checks structural input only; the Salesforce client also checks
the checksum. Make/model/body are fictional fixture values, not authoritative inventory data.
Client requires exact VIN match, simulation=true, nonempty bounded text, integer year 1900 through
current year+2, no unknown JSON fields and response size <=16000 characters.

## Error behavior

| Condition | Provider/client behavior |
|---|---|
| Missing custom permission | Client rejects before HTTP |
| Invalid length/characters/checksum | Client rejects before HTTP |
| Provider route missing | HTTP 404, NOT_FOUND |
| Provider malformed VIN | HTTP 400, INVALID_VIN_FORMAT |
| Non-200 provider response | Client reports only status, never provider body |
| Malformed JSON, wrong VIN, oversized/incomplete/non-simulation response | Generic invalid-response error; no save |
| Missing/unavailable credential, endpoint or timeout | Generic unavailable/timed-out error; no save or automatic retry |

## Local tests and credential gate

```sh
PYTHONDONTWRITEBYTECODE=1 python3 scripts/tests/p7_vin_mock_test.py
```

The provider binds only 127.0.0.1:8080 when explicitly started. Salesforce cannot call a developer
machine's loopback address. A future owner-approved reachable mock host and supported Named/
External Credential/principal configuration are required for a live callout. No tunnel, host,
credential, assignment or remote-site change is authorized by local implementation.

Apex tests cover actual request construction, mock response validation and denied/invalid input;
the request/response boundary is independently testable without configuring credentials. The
full named-credential positive wire path is not claimed verified. The unconfigured alias/transport blocked the
initial integrated positive test; tests were split at that real transport boundary rather than
adding a Test.isRunningTest endpoint bypass or credentials. Provider status/parse errors and
request construction are covered directly. The generic unavailable/timeout handler is exercised,
but a real timeout and positive named-credential transport are not claimed; both await approved
endpoint/credential configuration. Read-only metadata listing confirms NG_VIN_Mock is absent.

Native deployment compilation and test success do not establish real VIN decoding or a working
remote endpoint. Any later persistence/enrichment or production provider needs separate approval.
