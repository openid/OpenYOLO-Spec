## Retrieving credentials

OpenYOLO specifies two methods for credential retrieval; one is structurally
very similar to hint requests, and another which allows for credential
requests to be sent to multiple providers in parallel. The parallel request
mechanism is built on top of the "direct request" method, so the direct
request method will be specified first.

Direct credential retrieve requests on Android are dispatched to the credential
provider using an [Intent][android-intent]. If a provider supports credential
retrieval, it MUST declare this on the manifest entry for its retrieve activity,
using the following intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.retrieve"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

### Dispatching a direct retrieve request

In order to make a credential request, the client creates a credential request
message (specified in [SECTION](#credential-request-message)) and encodes it to
its binary protocol buffer form. An activity Intent is then created to send
this to the credential provider. The credential request message MUST be added
to the activity Intent using an extra, named "org.openyolo.credential.request".
This intent is then dispatched by the client using
[startActivityForResult][android-start-activity-for-result].

An example credential request can be created and dispatched as follows:

```java
CredentialRetrieveRequest request =
    CredentialRetrieveRequest.newBuilder()
        .addAuthenticationMethod("openyolo://email")
        .build();

byte[] credentialRequestBytes = request.toByteArray();

Intent hintIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.credential.retrieve")
    .setCategory("org.openyolo")
    .putExtra(
        "org.openyolo.credential.retrieve.request",
        request.toByteArray());
startActivityForResult(hintIntent, RC_HINT);
```

### Returning a response

The provider can perform any processing and user interaction required to
release a credential. Once complete, the provider creates a retrieve response
message (specified in [SECTION](#credential-response-message)), and passes this
back to the requester via [setResult][android-set-result]. The intent data
returned to the client MUST carry the retrieve result using an extra, named
"org.openyolo.credential.retrieve.result". Additionally, the result code
contained in that credential result MUST match the result code for the
provider activity.

An example credential result could therefore be created and returned with the
following code:

```java
Credential credential = Credential.newBuilder()
    .setId("jdoe@example.com")
    .setAuthDomain("android://sha256-aF...@com.example.app")
    .setAuthMethod("openyolo://email")
    .setPassword("CorrectH0rseBatterySt4ple")
    .build();

CredentialRetrieveResult result =
    CredentialRetrieveResult.newBuilder()
        .setResultCode(CredentialRetrieveResult.ResultCode.SUCCESS)
        .setCredential(credential)
        .build();

Intent retrieveResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.retrieve.result",
        result.toByteArray());

setResult(result.getResultCode(), retrieveResultData);
finish();
```

### Parallel credential retrieval

Credential retrieve requests can be sent to multiple providers in parallel,
using the Background Broadcast Query protocol (see [SECTION](#the-background-broadcast-query-protocol-bbq)) designed for this purpose.
If a provider supports direct credential retrieval, it MUST also support
parallel credential retrieval as specified in this section.

Parallel credential retrieval is particularly useful where more than one
provider is installed and actively used by the user on their device. This often
occurs where there is no easy integration for third party password managers
into system services, such as mobile browsers, which do not have a plugin
mechanism. In this scenario, there can be a disjoint disjoint set of
credentials stored in the various providers, so querying them all increases the
probability that a usable credential can be found.

The query data type used for credential requests is "org.openyolo.credential",
with a credential request message (specified in
[SECTION](#credential-request-message)) as the query data. Providers respond to the BBQ query with the following protocol buffer response message:

```protobuf
message CredentialRetrieveBbqResponse {
    bytes retrieve_intent = 1;
    map<string, bytes> additional_props = 2;
}
```

This response MAY carry an intent that can be used to retrieve a
credential from a provider. Providers do not return an intent if they know that
they do not have a credential matching the request. Providers MAY respond
with a retrieve intent even if they do not know that they have a credential
available: providers which use a master password to encrypt their stores which
is not stored to disk may require the user to take an action to unlock the store
before an accurate answer can be determined.

Where multiple providers respond with an intent, the client SHOULD allow
the user to choose which of these providers to proceed with. Once selected,
the intent is dispatched to the provider using
[startActivityForResult][android-start-activity-for-result].

The intent returned via the BBQ response MUST be structurally equivalent
to the intents that a client would construct for direct credential
retrieval, and the activity it is directed to MUST also follow the same
protocol to return results.The provider MAY include additional information in
the retrieve intent returned via BBQ, if convenient.

As the intent returned via BBQ is visible to, and can potentially be modified
by the requesting service, it MUST NOT be blindly trusted by the provider
when used by the requester. Additionally, intents returned via the BBQ
protocol MUST NOT contain any privacy or security sensitive information, such
as pre-fetched credentials. Providers SHOULD implement tamper-detection for the
intent, such that any modification of the data carried by the intent is
rejected.
