Account a = new Account(Name = 'UAT-2026-10-19 ROLLBACK PROBE');
insert a;
System.debug('PROBE_ID=' + a.Id);
throw new IllegalArgumentException('intentional rollback');
