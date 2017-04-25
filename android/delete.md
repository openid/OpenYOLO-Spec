## Deleting credentials

Credential delete requests on Android are dispatched to the credential provider
using an [Intent][android-intent]. A provider must declare its willingness to
delete stored credentials by including an activity in its manifest with the
following intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.delete"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

In order to make a delete request, the client creates a delete request message
(specified in [SECTION](#delete-request-message)) and encodes it to its binary
protocol buffer form. An activity Intent is then created to send this to the
credential provider. The delete request message _must_ be added to the activity
Intent using an extra, named "org.openyolo.credential.delete.request".

An example delete request could be constructed as follows:

```java
CredentialDeleteRequest request =
    CredentialDeleteRequest.newBuilder()
        .setCredential(
            Credential.newBuilder()
                .setId("jdoe@example.com")
                .setAuthenticationDomain(/*...*/)
                .setAuthenticationMethod(/*...*/)
                .setPassword("wrongPassword")
                .build())
        .build();

Intent deleteIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.credential.delete")
    .setCategory("org.openyolo")
    .putExtra(
        "org.openyolo.credential.delete.request",
        request.toByteArray());
```

This intent is dispatched by the client using
[startActivityForResult][android-start-activity-for-result]. At this point the
provider can perform any processing and user interaction required to delete
the credential. The provider creates a delete response message (specified in
[SECTION](#delete-response-message)), and passes this back to the requester via
[setResult][android-set-result]. The intent data returned to the
client _must_ carry the delete result using an extra, named
"org.openyolo.credential.delete.result". Additionally, the result code
contained in that delete result _must_ match the result code for the provider activity.

An example save result could therefore be sent with the following code:

```java
CredentialDeleteResult result = CredentialDeleteResult.newBuilder()
    .setResultCode(CredentialSaveResult.ResultCode.REJECTED);
Intent deleteResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.delete.result",
        result.toByteArray());

setResult(result.getResultCode(), deleteResultData);
```
