/**
 * @description  Apex REST resource to create Lead records via an external HTTP POST.
 *               Endpoint: /services/apexrest/leads
 *
 * Sample request body (JSON):
 * {
 *   "firstName"   : "John",
 *   "lastName"    : "Doe",
 *   "email"       : "john.doe@example.com",
 *   "phone"       : "555-123-4567",
 *   "company"     : "Acme Corp",
 *   "title"       : "VP of Sales",
 *   "leadSource"  : "Web",
 *   "industry"    : "Technology",
 *   "street"      : "123 Main St",
 *   "city"        : "San Francisco",
 *   "state"       : "CA",
 *   "postalCode"  : "94105",
 *   "country"     : "US",
 *   "website"     : "https://acme.com",
 *   "description" : "Interested in enterprise plan"
 * }
 *
 * @author  Auto-generated
 */
@RestResource(urlMapping='/mcp/leads/*')
global with sharing class LeadRestService {

    // ── Wrapper for the inbound request ──────────────────────────────────
    global class LeadRequest {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String company;
        public String title;
        public String leadSource;
        public String industry;
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String website;
        public String description;
    }

    // ── Wrapper for the outbound response ────────────────────────────────
    global class LeadResponse {
        public Boolean  success;
        public String   leadId;
        public String   message;

        public LeadResponse(Boolean success, String leadId, String message) {
            this.success = success;
            this.leadId  = leadId;
            this.message = message;
        }
    }

    // ── POST: Create a new Lead ──────────────────────────────────────────
    @HttpPost
    global static LeadResponse createLead() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Deserialize request body into wrapper
            LeadRequest payload = (LeadRequest) JSON.deserialize(
                req.requestBody.toString(),
                LeadRequest.class
            );

            // ── Validate required fields ─────────────────────────────────
            List<String> errors = new List<String>();
            if (String.isBlank(payload.lastName)) {
                errors.add('lastName is required.');
            }
            if (String.isBlank(payload.company)) {
                errors.add('company is required.');
            }
            if (!errors.isEmpty()) {
                res.statusCode = 400;
                return new LeadResponse(
                    false,
                    null,
                    'Validation failed: ' + String.join(errors, ' ')
                );
            }

            // ── Map payload to Lead sObject ──────────────────────────────
            Lead newLead       = new Lead();
            newLead.FirstName  = payload.firstName;
            newLead.LastName   = payload.lastName;
            newLead.Email      = payload.email;
            newLead.Phone      = payload.phone;
            newLead.Company    = payload.company;
            newLead.Title      = payload.title;
            newLead.LeadSource = payload.leadSource;
            newLead.Industry   = payload.industry;
            newLead.Street     = payload.street;
            newLead.City       = payload.city;
            newLead.State      = payload.state;
            newLead.PostalCode = payload.postalCode;
            newLead.Country    = payload.country;
            newLead.Website    = payload.website;
            newLead.Description = payload.description;

            insert newLead;

            res.statusCode = 201;
            return new LeadResponse(
                true,
                newLead.Id,
                'Lead created successfully.'
            );

        } catch (JSONException je) {
            res.statusCode = 400;
            return new LeadResponse(
                false,
                null,
                'Invalid JSON: ' + je.getMessage()
            );
        } catch (DmlException de) {
            res.statusCode = 500;
            return new LeadResponse(
                false,
                null,
                'DML Error: ' + de.getMessage()
            );
        } catch (Exception ex) {
            res.statusCode = 500;
            return new LeadResponse(
                false,
                null,
                'Unexpected error: ' + ex.getMessage()
            );
        }
    }
}
