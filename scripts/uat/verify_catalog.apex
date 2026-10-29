List<QuoteBuilderController.CatalogItem> items = QuoteBuilderController.getCatalog('Vehicle_Trim');
System.debug('CATALOG_COUNT=' + items.size());
Integer shown = 0;
for (QuoteBuilderController.CatalogItem item : items) {
    if (shown < 5) {
        System.debug('ITEM=' + item.productId + '|' + item.name + '|' + item.unitPrice);
        shown++;
    }
}
List<Pricebook2> activeStandard = [SELECT Id, Name, IsStandard, IsActive FROM Pricebook2 WHERE IsStandard = true AND IsActive = true];
System.debug('ACTIVE_STANDARD=' + activeStandard.size() + (activeStandard.isEmpty() ? '' : '|' + activeStandard[0].Id));
