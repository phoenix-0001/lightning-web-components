public with sharing class ProductSelectorController {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProducts() {
        return [
            SELECT Id, Name, Description
            FROM Product2
            WHERE IsActive = true
            ORDER BY Name LIMIT 10
        ];
    }
}
