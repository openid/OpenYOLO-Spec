## Saving credentials

Credential save requests on Android are dispatched to the credential provider
using an [Intent][android-intent]. A provider must declare its ability to
save credentials by including an activity in its manifest with the following
intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.save"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

In order to make a save request, the client creates a save request message
(specified in [SECTION](#save-request-message)) and encodes it to its binary
protocol buffer form. An activity Intent is then created to send this to the
credential provider. The save request message _must_ be added to the activity
Intent using an extra, named "org.openyolo.credential.save.request".

An example save request could be constructed as follows:

```java
CredentialSaveRequest request = CredentialSaveRequest.newBuilder()
    .setCredential(Credential.newBuilder()
        .setId("jdoe@example.com")
        .setAuthenticationDomain(
            "android://sha256-...@com.example.app")
        .setAuthenticationMethod(
            "https://auth.example.com")
        .setDisplayName("Jane Doe")
        .build())
    .build();

Intent saveIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.credential.save")
    .setCategory("org.openyolo")
    .putExtra(
        "org.openyolo.credential.save.request",
        request.toByteArray());
```

This intent is dispatched by the client using
[startActivityForResult][android-start-activity-for-result]. At this point the
provider can perform any processing and user interaction required to save
the credential. The provider creates a save response message (specified in
[SECTION](#save-response-message)), and passes this back to the requester via
[setResult][android-set-result]. The intent data returned to the
client _must_ carry the save result using an extra, named
"org.openyolo.credential.save.result". Additionally, the result code contained
in that save result _must_ match the result code for the provider activity.

An example save result could therefore be sent with the following code:

```java
CredentialSaveResult result = CredentialSaveResult.newBuilder()
    .setResultCode(CredentialSaveResult.ResultCode.SUCCESS);
Intent saveResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.save.result",
        result.toByteArray());

setResult(result.getResultCode(), saveResultData);
```
