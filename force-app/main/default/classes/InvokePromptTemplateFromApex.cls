/**
* @File Name : InvokePromptTemplateFromApex.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 17, 2025 |   | Initial Version
**/

/**
* @File Name : InvokePromptTemplateFromApex.cls
* @Description : Invokes Case_Summary Prompt Template and returns generated summary
* @Author :
* @Last Modified On : December 17, 2025
**/
public with sharing class InvokePromptTemplateFromApex {

    @AuraEnabled
    public static String generateCaseSummary(Id caseId) {

        // --------- Build input parameter for Case record ----------
        Map<String, Object> caseRecord = new Map<String, Object>{
            'id' => caseId
        };

        ConnectApi.WrappedValue caseWrappedValue = new ConnectApi.WrappedValue();
        caseWrappedValue.value = caseRecord;
		System.debug('caseWrappedValue.value::'+caseWrappedValue.value);

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:Case', caseWrappedValue);

        // --------- Configure Prompt Template execution ----------
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        promptInput.inputParams = inputParams;
        promptInput.isPreview = false;

        promptInput.additionalConfig =
            new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        promptInput.additionalConfig.numGenerations = 1;
        promptInput.additionalConfig.temperature = 0;

        try {
            // --------- Invoke Case_Summary Prompt Template ----------
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Case_Summary', // Developer Name of Prompt Template
                    promptInput
                );

            // --------- Capture output ----------
            String prompt = response.generations[0].text;
			System.debug('prompt ::'+prompt);
            return prompt;

        } catch (Exception e) {
            System.debug('Error invoking Case_Summary prompt: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}