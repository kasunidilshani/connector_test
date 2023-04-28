import ballerina/http;
import ballerina/regex;
import ballerina/io;

//Import the SCIM module.
import ballerinax/scim;

configurable string orgName = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string[] scope = [
    "internal_user_mgt_view",
    "internal_user_mgt_list",
    "internal_user_mgt_create",
    "internal_user_mgt_delete",
    "internal_user_mgt_update",
    "internal_user_mgt_delete",
    "internal_group_mgt_view",
    "internal_group_mgt_list",
    "internal_group_mgt_create",
    "internal_group_mgt_delete",
    "internal_group_mgt_update",
    "internal_group_mgt_delete"
];

//Create a SCIM connector configuration
scim:ConnectorConfig scimConfig = {
    orgName: orgName,
    clientId: clientId,
    clientSecret: clientSecret,
    scope: scope
};

//Initialize the SCIM client.
scim:Client scimClient = check new (scimConfig);

type UserCreateRequest record {
    string password;
    string email;
    string name;
};

type UserSearchRequest record {
    string email;
};

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {
    resource function get user() returns scim:UserResource|error {
        string id = "892b2a2f-8b4d-4df6-b414-c7a7479f29c8";
        scim:UserResource|scim:ErrorResponse|error response = scimClient->getUser(id);
        if (response is scim:ErrorResponse) {
            return error(response.detail().toString());
        }
        return response;
    }

    resource function post createUser(@http:Payload UserCreateRequest payload) returns scim:UserResource|error {
        // create user
        scim:UserCreate user = {password: payload.password};
        user.userName = string `DEFAULT/${payload.email}`;
        io:println(user.userName);
        user.name = {formatted: payload.name};
        scim:UserResource response = check scimClient->createUser(user);

        // add created user to the relevant group
        string createdUser = response.id.toString();
        string groupId = "1fd8d238-8128-4386-8b0d-81246c6eb41d";
        if regex:matches(user.userName.toString(), "@stu\\.") {
            groupId = "1fd8d238-8128-4386-8b0d-81246c6eb41d";
        }
        else if regex:matches(user.userName.toString(), "@staff\\.") {
            groupId = "1fd8d238-8128-4386-8b0d-81246c6eb41d";
        }
        scim:GroupPatch Group = {Operations: [{op: "add", value: {members: [{"value": createdUser, "display": user.userName}]}}]};
        scim:GroupResource groupResponse = check scimClient->patchGroup(groupId, Group);
        return response;
    }

    resource function get groupUserCount() returns json|error {
        string staffgroupId = "1fd8d238-8128-4386-8b0d-81246c6eb41d";
        string stugroupId = "1fd8d238-8128-4386-8b0d-81246c6eb41d";
        scim:GroupResource response = check scimClient->getGroup(staffgroupId);
        int staffCount = 0;
        if response.members != () {
            staffCount = (<scim:Member[]>response.members).length();
        }
        int stuCount = 0;
        if response.members != () {
            stuCount = (<scim:Member[]>response.members).length();
        }
        scim:GroupResource response1 = check scimClient->getGroup(stugroupId);
        json output = {staffCount: staffCount, studentCount: stuCount};
        return output;
    }

    resource function post searchProfile(@http:Payload UserSearchRequest payload) returns scim:UserResource[]?|error {
        string userName = string `DEFAULT/${payload.email.toString()}`;
        scim:UserSearch searchData = {filter: string `userName eq ${userName}`};
        scim:UserResponse response = check scimClient->searchUser(searchData);
        return response.Resources;
    }

    resource function delete deleteUser(string email) returns string|error {
        string userName = string `DEFAULT/${email}`;
        scim:UserSearch searchData = {filter: string `userName eq ${userName}`};
        scim:UserResponse response = check scimClient->searchUser(searchData);
        if response.Resources is () {return error ("User not found");}
        string deleteId = <string>(<scim:UserResource[]>response.Resources)[0].id;
        json response1 = check scimClient->deleteUser(deleteId);
        return "User deleted successfully";
    }

}
