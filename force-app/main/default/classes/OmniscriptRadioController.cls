global with sharing class OmniscriptRadioController implements System.Callable {

    /**
     * Standard System.Callable entry point required by modern OmniStudio standard runtimes
     */
    global Object call(String action, Map<String, Object> args) {
        // Extract the parameters from the argument map provided by OmniStudio
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');

        // Route the extracted maps to the internal invokeMethod
        return invokeMethod(action, input, output, options);
    }

    /**
     * Internal router to process business logic based on the method name
     */
    private Object invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        System.debug(LoggingLevel.DEBUG, '***input**** ' + input);
        
        try {
            // Check if the method called matches our lookup data source method
            // Note: Using equalsIgnoreCase or exact match depending on your element configuration
            if (methodName.equals('populateCaseOriginPickList')) {
                populateCaseOriginPickList(input, output, options);
                return true;
            }
        } catch (Exception e) {
            System.debug('Error in OmniscriptLookupController: ' + e.getMessage());
        }
        return false;
    }

    /**
     * Method to fetch Case Origin picklist values and format them for OmniStudio Lookup
     */
    private void populateCaseOriginPickList(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        // List to hold the final name-value pairs that OmniStudio expects
        List<Map<String, String>> finalOptionsList = new List<Map<String, String>>();

        // Using Schema describe to get Case Origin picklist entries dynamically
        Schema.DescribeFieldResult fieldResult = Case.Origin.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        // Loop through all picklist entries
        for (Schema.PicklistEntry entry : picklistEntries) {
            // Filter out deactivated picklist values; only process active ones
            if (entry.isActive()) {
                Map<String, String> tempOption = new Map<String, String>();
                
                // OmniStudio lookups require a structural map with 'name' and 'value' keys
                tempOption.put('name', entry.getLabel());
                tempOption.put('value', entry.getValue());
                
                finalOptionsList.add(tempOption);
            }
        }

        // The final list must be assigned to the 'options' key inside the output map
        output.put('options', finalOptionsList);
    }
}