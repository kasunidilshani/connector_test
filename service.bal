import ballerina/http;
import ballerinax/scim;

configurable string orgName = ?;
configurable string clientId = ?;
configurable string clientSecret= ?;
configurable string[] scope= ["internal_user_mgt_view","internal_user_mgt_list", "internal_user_mgt_create", "internal_user_mgt_delete", "internal_user_mgt_update", "internal_user_mgt_delete",
    "internal_group_mgt_view", "internal_group_mgt_list", "internal_group_mgt_create", "internal_group_mgt_delete", "internal_group_mgt_update", "internal_group_mgt_delete"];

scim:ConnectorConfig scimConfig = {
        orgName: orgName,
        clientId: clientId,
        clientSecret: clientSecret,
        scope: scope
    };

scim:Client scimClient = check new(scimConfig);

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {
    // Create a new SCIM client.
    resource function get user() returns scim:UserResource|error {
        // Send a response back to the caller.
        string id = "892b2a2f-8b4d-4df6-b414-c7a7479f29c8";
        scim:UserResource response = check scimClient->getUser(id);
        return response;
    }
}
