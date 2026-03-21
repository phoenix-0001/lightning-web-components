public with sharing class DynamicPicklistController {

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(Id recordId) {

        if (recordId == null) {
            return new List<String>();
        }

        Opportunity opp = [
            SELECT Category_Lists__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (String.isBlank(opp.Category_Lists__c)) {
            return new List<String>();
        }

        // Split comma-separated values
        List<String> values = opp.Category_Lists__c.split(',');
		System.debug('values==>'+values);
        // Trim spaces
        List<String> trimmedValues = new List<String>();
        for (String val : values) {
            trimmedValues.add(val.trim());
        }

        return trimmedValues;
    }
}