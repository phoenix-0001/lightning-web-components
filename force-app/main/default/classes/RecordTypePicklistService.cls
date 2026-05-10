/**
 * @description  Spring '26 Feature — Record-Type-Aware Picklist Values via Connect API
 *
 *               Uses the new ConnectApi.RecordUi.getPicklistValuesByRecordType()
 *               method introduced in API v66.0 (Spring '26) to retrieve picklist
 *               values that are valid for a given record type.
 *
 *               This replaces the legacy pattern of making HTTP callouts to the
 *               UI API endpoint (/ui-api/object-info/{objectApiName}/picklist-values/{recordTypeId}).
 *
 * @author       Pari
 * @date         2026-05-01
 * @apiVersion   66.0
 */
public with sharing class RecordTypePicklistService {

    // ─── Wrapper: lightweight structure returned to LWC / Flow callers ───
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isDefaultValue;

        public PicklistOption(String label, String value, Boolean isDefaultValue) {
            this.label          = label;
            this.value          = value;
            this.isDefaultValue = isDefaultValue;
        }
    }

    // ─── Wrapper: groups options by field API name ───
    public class FieldPicklistResult {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public List<PicklistOption> options;

        public FieldPicklistResult(String fieldApiName, List<PicklistOption> options) {
            this.fieldApiName = fieldApiName;
            this.options      = options;
        }
    }

    /**
     * @description  Retrieve picklist values for ALL picklist fields on an object,
     *               filtered by the specified Record Type.
     * @param        objectApiName  API name of the sObject  (e.g. 'Account')
     * @param        recordTypeId   18-char Record Type Id
     * @return       Map of field API name → list of PicklistOption wrappers
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<PicklistOption>> getPicklistValuesByRecordType(
        String objectApiName,
        String recordTypeId
    ) {
        // Validate inputs
        if (String.isBlank(objectApiName) || String.isBlank(recordTypeId)) {
            throw new AuraHandledException(
                'Both objectApiName and recordTypeId are required.'
            );
        }

        Map<String, List<PicklistOption>> result = new Map<String, List<PicklistOption>>();

        // ── Spring '26: Native Connect API call (API v66.0+) ──
        ConnectApi.PicklistValuesCollection pvc =
            ConnectApi.RecordUi.getPicklistValuesByRecordType(objectApiName, recordTypeId);

        if (pvc == null || pvc.picklistFieldValues == null) {
            return result;
        }

        // Iterate over every picklist field returned for this record type
        for (String fieldApiName : pvc.picklistFieldValues.keySet()) {
            ConnectApi.PicklistValues fieldValues =
                pvc.picklistFieldValues.get(fieldApiName);

            List<PicklistOption> options = new List<PicklistOption>();

            if (fieldValues != null && fieldValues.values != null) {
                // defaultValue lives on the parent PicklistValues object
                ConnectApi.PicklistValue defaultPv = fieldValues.defaultValue;
                String defaultVal = (defaultPv != null) ? defaultPv.value : null;

                for (ConnectApi.PicklistValue pv : fieldValues.values) {
                    Boolean isDefault = (defaultVal != null && defaultVal == pv.value);
                    options.add(
                        new PicklistOption(pv.label, pv.value, isDefault)
                    );
                }
            }

            result.put(fieldApiName, options);
        }

        return result;
    }

    /**
     * @description  Retrieve picklist values for a SINGLE field on an object,
     *               filtered by the specified Record Type.
     * @param        objectApiName  API name of the sObject
     * @param        recordTypeId   18-char Record Type Id
     * @param        fieldApiName   API name of the picklist field (e.g. 'Industry')
     * @return       List of PicklistOption wrappers for the requested field
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPicklistValuesForField(
        String objectApiName,
        String recordTypeId,
        String fieldApiName
    ) {
        if (String.isBlank(fieldApiName)) {
            throw new AuraHandledException('fieldApiName is required.');
        }

        Map<String, List<PicklistOption>> allValues =
            getPicklistValuesByRecordType(objectApiName, recordTypeId);

        if (allValues.containsKey(fieldApiName)) {
            return allValues.get(fieldApiName);
        }

        // Field not found — return empty list rather than null
        return new List<PicklistOption>();
    }

    /**
     * @description  Retrieve picklist values using the Record Type Developer Name
     *               instead of the Record Type Id.
     * @param        objectApiName        API name of the sObject
     * @param        recordTypeDeveloperName  Developer name of the Record Type
     * @return       Map of field API name → list of PicklistOption wrappers
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<PicklistOption>> getPicklistValuesByRecordTypeName(
        String objectApiName,
        String recordTypeDeveloperName
    ) {
        if (String.isBlank(objectApiName) || String.isBlank(recordTypeDeveloperName)) {
            throw new AuraHandledException(
                'Both objectApiName and recordTypeDeveloperName are required.'
            );
        }

        // Resolve Developer Name → Record Type Id
        Schema.DescribeSObjectResult objDescribe =
            Schema.getGlobalDescribe().get(objectApiName).getDescribe();

        Schema.RecordTypeInfo rtInfo =
            objDescribe.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName);

        if (rtInfo == null) {
            throw new AuraHandledException(
                'Record Type "' + recordTypeDeveloperName + '" not found on ' + objectApiName
            );
        }

        return getPicklistValuesByRecordType(objectApiName, rtInfo.getRecordTypeId());
    }

    /**
     * @description  Return structured results that include both the field name and
     *               its options — useful for Lightning Data Table or Flow collections.
     * @param        objectApiName  API name of the sObject
     * @param        recordTypeId   18-char Record Type Id
     * @return       List of FieldPicklistResult wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldPicklistResult> getStructuredPicklistValues(
        String objectApiName,
        String recordTypeId
    ) {
        Map<String, List<PicklistOption>> valuesMap =
            getPicklistValuesByRecordType(objectApiName, recordTypeId);

        List<FieldPicklistResult> results = new List<FieldPicklistResult>();
        for (String field : valuesMap.keySet()) {
            results.add(new FieldPicklistResult(field, valuesMap.get(field)));
        }

        return results;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Lead-specific convenience methods (used by leadSourceByRecordType LWC)
    // ═══════════════════════════════════════════════════════════════════════

    // ─── Wrapper for Record Type info ───
    public class RecordTypeOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public RecordTypeOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    /**
     * @description  Get all available Lead record types for the running user.
     * @return       List of RecordTypeOption wrappers (label + Id)
     */
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeOption> getLeadRecordTypes() {
        List<RecordTypeOption> options = new List<RecordTypeOption>();

        Schema.DescribeSObjectResult leadDescribe = Lead.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtInfos = leadDescribe.getRecordTypeInfosByName();

        for (String rtName : rtInfos.keySet()) {
            Schema.RecordTypeInfo info = rtInfos.get(rtName);
            // Only include record types available to the current user (skip Master)
            if (info.isAvailable() && !info.isMaster()) {
                options.add(new RecordTypeOption(info.getName(), info.getRecordTypeId()));
            }
        }

        return options;
    }

    /**
     * @description  Get LeadSource picklist values for a specific Lead Record Type
     *               using the Spring '26 ConnectApi.RecordUi method.
     * @param        recordTypeId  18-char Record Type Id of the Lead record type
     * @return       List of PicklistOption wrappers for the LeadSource field
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getLeadSourceByRecordType(String recordTypeId) {
        if (String.isBlank(recordTypeId)) {
            throw new AuraHandledException('recordTypeId is required.');
        }

        // ── Spring '26: Native Connect API call (API v66.0+) ──
        ConnectApi.PicklistValuesCollection pvc =
            ConnectApi.RecordUi.getPicklistValuesByRecordType('Lead', recordTypeId);

        List<PicklistOption> options = new List<PicklistOption>();

        if (pvc != null && pvc.picklistFieldValues != null) {
            ConnectApi.PicklistValues leadSourceValues =
                pvc.picklistFieldValues.get('LeadSource');

            if (leadSourceValues != null && leadSourceValues.values != null) {
                // defaultValue lives on the parent PicklistValues object
                ConnectApi.PicklistValue defaultPv = leadSourceValues.defaultValue;
                String defaultVal = (defaultPv != null) ? defaultPv.value : null;

                for (ConnectApi.PicklistValue pv : leadSourceValues.values) {
                    Boolean isDefault = (defaultVal != null && defaultVal == pv.value);
                    options.add(
                        new PicklistOption(pv.label, pv.value, isDefault)
                    );
                }
            }
        }

        return options;
    }

    /**
     * @description  Create a Lead record with the specified field values.
     * @param        firstName       First name of the Lead
     * @param        lastName        Last name of the Lead (required)
     * @param        company         Company name (required)
     * @param        email           Email address
     * @param        phone           Phone number
     * @param        leadSource      LeadSource picklist value
     * @param        recordTypeId    Record Type Id to assign
     * @return       The Id of the newly created Lead
     */
    @AuraEnabled
    public static Id createLead(
        String firstName,
        String lastName,
        String company,
        String email,
        String phone,
        String leadSource,
        String recordTypeId
    ) {
        // Validate required fields
        if (String.isBlank(lastName)) {
            throw new AuraHandledException('Last Name is required.');
        }
        if (String.isBlank(company)) {
            throw new AuraHandledException('Company is required.');
        }
        if (String.isBlank(recordTypeId)) {
            throw new AuraHandledException('Record Type is required.');
        }

        Lead newLead = new Lead(
            FirstName    = firstName,
            LastName     = lastName,
            Company      = company,
            Email        = email,
            Phone        = phone,
            LeadSource   = leadSource,
            RecordTypeId = recordTypeId
        );

        try {
            insert newLead;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }

        return newLead.Id;
    }
}
