## Retrieving Hints

Hint requests on Android are dispatched to the credential provider using
an [Intent][android-intent]. Providers which wish to support hint retrieval
declare this by including an activity in their manifest with the following
intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.hint"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

In order to send a retrieve request, the client creates a hint request message
(specified in [SECTION](#hint-request-message)) and encodes it to its binary
protocol buffer form. An activity intent is then created to send this to the
credential provider, attaching the message bytes using an extra, named
"org.openyolo.hint.request".

An example hint request could be constructed as follows:

```java
HintRetrieveRequest request = HintRetrieveRequest.newBuilder()
    .addAuthenticationMethod("openyolo://email")
    .build();

Intent hintIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.hint")
    .setCategory("org.openyolo")
    .putExtra("org.openyolo.hint.request", request.toByteArray());
```

This intent is dispatched by the client using
[startActivityForResult][android-start-activity-for-result]. At this point the
provider can interact with the user to allow them to select a hint. The
provider creates a hint response message (specified in
[SECTION](#hint-response-message)), and passes this back to the requester via
[setResult][android-set-result]. The intent data returned to the
client carries the hint result message bytes using an extra, named
"org.openyolo.hint.result". Additionally, the result code contained in that
hint result is also used as the result code for the activity when it terminates.

An example hint result could therefore be sent with the following code:

```java
HintRetrieveResult result = HintRetrieveResult.newBuilder()
    .setResultCode(HintRetrieveResult.ResultCode.REJECTED_BY_USER);
Intent hintResultData = new Intent()
    .putExtra(
        "org.openyolo.hint.result",
        result.toByteArray());

setResult(result.getResultCode(), hintResultData);
```
