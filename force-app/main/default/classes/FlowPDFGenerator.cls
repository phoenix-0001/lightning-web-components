public with sharing class FlowPDFGenerator {

    @InvocableMethod(label='Generate PDF from Prompt Response' 
                     description='Generates a simple PDF from a Flex Prompt response and links it to the Lead record.')
    public static List<PDFResponse> generatePDFFromPromptResponse(List<PDFRequest> requests) {
        List<PDFResponse> responses = new List<PDFResponse>();

        for (PDFRequest req : requests) {
            if (String.isBlank(req.promptResponse) || req.leadId == null) {
                responses.add(new PDFResponse(null, 'Lead Id and prompt response are required.'));
                continue;
            }

            try {
                // Keep plain text with line breaks (no HTML escaping)
                String plainResponse = req.promptResponse;

                // Build plain text for PDF
                String textContent = 'Keypoint Strategies for Conversion:\n\n' + plainResponse;

                // Convert text to PDF
                Blob pdfBlob = Blob.toPdf(textContent);

                // Generate PDF file name: Conversion_Strategies_YYYYMMDD.pdf
                String dateSuffix = System.now().format('yyyyMMdd');
                String fileName = 'Conversion_Strategies_' + dateSuffix + '.pdf';

                // Create ContentVersion
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName.replace('.pdf',''); 
                cv.PathOnClient = fileName;
                cv.VersionData = pdfBlob;
                insert cv;

                // Link PDF to Lead using ContentDocumentLink
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                cdl.LinkedEntityId = req.leadId;
                cdl.ShareType = 'V'; // Viewer permission
                cdl.Visibility = 'AllUsers';
                insert cdl;

                responses.add(new PDFResponse(cv.Id, 'PDF generated and linked to Lead successfully.'));
            } catch (Exception ex) {
                responses.add(new PDFResponse(null, 'Error generating PDF: ' + ex.getMessage()));
            }
        }

        return responses;
    }

    // Flow input wrapper
    public class PDFRequest {
        @InvocableVariable(required=true)
        public String promptResponse;

        @InvocableVariable(required=true)
        public Id leadId;
    }

    // Flow output wrapper
    public class PDFResponse {
        @InvocableVariable
        public Id contentVersionId;

        @InvocableVariable
        public String message;

        public PDFResponse(Id cvId, String msg) {
            contentVersionId = cvId;
            message = msg;
        }
    }
}