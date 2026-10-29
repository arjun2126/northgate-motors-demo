"""Offline provider contract checks; starts no server and contacts no endpoint."""
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location('vin_mock', Path(__file__).resolve().parents[1] / 'integration/vin_mock_server.py')
mock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mock)
status, body = mock.response_for('/decode/4NDM4NJ96V8L0KGCJ')
assert status == 200 and body['simulation'] is True and body['vin'] == '4NDM4NJ96V8L0KGCJ'
assert set(body) == {'vin', 'make', 'model', 'year', 'bodyStyle', 'simulation'}
assert mock.response_for('/decode/not-a-vin')[0] == 400
assert mock.response_for('/decode/4NDM4NJ96V8L0KGCQ')[0] == 400
assert mock.response_for('/other')[0] == 404
print('PASS: VIN mock success, schema, invalid format/characters and missing route; no network requests.')
