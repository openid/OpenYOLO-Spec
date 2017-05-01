## The background broadcast query protocol (BBQ)

BBQ is a protocol designed to allow an Android app to request data from multiple _data providers_ on the device, in parallel. OpenYOLO for Android
uses this protocol to facilitate credential retrieve requests
(see [SECTION](#retrieving-credentials)).

BBQ Requests and responses are sent as targeted broadcast messages, with
protocol buffers used to encode the request and response data. The use of
broadcast messages allows implementations to be fully asynchronous, and
protocol buffers allow messages to be compact and efficient, while avoiding
common issues with custom Parcelable types.

### BBQ requests

A broadcast query has the following mandatory properties:

- The data type being requested, described with
  [reverse domain name notation][reverse-domain], as is
  typically used for package names and intent actions in Android.
  For example, `org.openyolo.credential`.
- The package name of the requesting app, e.g. `com.example.app`.
- A randomly generated, 64-bit request ID. This is used to distinguish the
  request from other requests with the same data type that may not have been
  fully resolved.
- A randomly generated, 64-bit response ID. A separate response ID is generated
  for each expected responder, allowing responders to be distinguished and their
  identity to be recovered from the mapping of response ID to package name that
  is created prior to sending the request.

An additional data-type specific message can be carried in the request if
necessary, in the form of a byte-array (typically an encoded protocol buffer).
Additional parameters can also be encoded into the message as
key-value pairs, allowing for extension of the protocol itself.

The request is represented by the following protocol buffer message:

```protobuf
message BroadcastQuery {
  // required
  string dataType = 1;

  // required
  string requestingApp = 2;

  // required
  sfixed64 requestId = 3;

  // required
  sfixed64 responseId = 4;

  bytes queryMessage = 5;
  map<string, bytes> additionalProps = 6;
}
```

#### Accepting BBQ requests

In order for a client to discover a BBQ query handler for a given query type,
the handler MUST declare a broadcast receiver in their manifest as follows:

```xml
<receiver
    android:name="com.example.BbqQueryHandler"
    android:exported="true">
  <intent-filter>
      <action android:name="DATA_TYPE" />
      <category android:name="com.google.bbq" />
  </intent-filter>
</receiver>
```

This declares a BBQ query handler for "DATA_TYPE", which would typically be
substituted for the appropriate query type (e.g. "org.openyolo.credential").
The category "com.google.bbq" MUST be present for the client to
recognize this receiver as a BBQ query handler.

#### Dispatching requests

A request is dispatched as targeted broadcast message, with a separate
message sent to each potential handler. First, the
requester uses the Android [PackageManager][android-package-manager] API to
determine the set of apps which can provide data of the required type:

```java
Intent intent = new Intent(dataType);
intent.addCategory("com.google.bbq.query");
List<ResolveInfo> responderInfos =
    packageManager.queryBroadcastReceivers(intent, 0);
```

A separate request message is created for each potential responder, with a
unique response ID, and sent as a targeted broadcast. The query
protobol buffer message is carried as an intent extra under the name
"com.google.bbq.query.request":

```java
BroadcastQuery query = BroadcastQuery.newBuilder()
    /* ... */
    .setResponseId(idForResponder.get(responder))
    .build();
Intent bbqIntent = new Intent(dataType);
bbqIntent.addCategory("com.google.bbq");
bbqIntent.setPackage(responder);
bbqIntent.setExtra("com.google.bbq.query.request", query.encode());
context.sendBroadcast(bbqIntent);
```

### BBQ responses

A broadcast query response has the following mandatory properties:

- The 64-bit request ID that the response is associated with, copied from the
  request.
- The 64-bit response ID unique to this response, copied from the request.

The response copies the request and response IDs from the request message,
and MAY include a data-type specific response message, if necessary.
The absence of a data-type specific response message is generally interpreted
to mean that the provider is unable to service the request.

The structure of the query response message is therefore as follows:

```protobuf
message BroadcastQueryResponse {
  // required
  sfixed64 requestId = 1;

  // required
  sfixed64 responseId = 2;

  bytes responseMessage = 3;
  map<string, bytes> additionalProps = 4;
}
```

#### Accepting BBQ responses

In order to receive a BBQ query response, the requester MUST dynamically
register a broadcast receiver for an action of form
`DATA_TYPE:REQUEST_ID`, where `DATA_TYPE` is the data type that is being
queried, and `REQUEST_ID` is the zero-padded, upper-case hexadecimal form of
the 64-bit request ID. For example, if the request ID were 51966 in decimal,
the registered broadcast receiver action will be
`org.openyolo.credential:000000000000CAFE`:

```java
IntentFilter filter = new IntentFilter();
filter.addAction("org.openyolo.credential:000000000000CAFE");
filter.addCategory("com.google.bbq");
context.registerReceiver(new BroadcastReciever() { ... }, filter);
```

In order to avoid a race condition, this response handler MUST be registered
prior to dispatching a query.

#### Dispatching BBQ responses

Responses are sent back to the requester from the query handler in the form of
targeted broadcast messages to the dynamically registered action. The intent
describing this response broadcast is constructed such that the action is
set to the dynamically registered broadcast receiver of the client for the
query, and the response protocol buffer message is carried as an extra
with name "com.google.bbq.query.response". For example:

```java
Intent responseBroadcast = new Intent(
    "org.openyolo.credential:000000000000CAFE");
responseBroadcast.addCategory("com.google.bbq");
responseBroadcast.setPackage("com.example.app");
responseBroadcast.putExtra("com.google.bbq.query.response",
        responseMessage);
sendBroadcast(responseBroadcast);
```

### Use of timeouts

In order to avoid waiting indefinitely for responses from faulty or slow
receivers, a timeout SHOULD be used, after which absent responses MUST be
treated as though the provider was unable to service the request. This is
equivalent to a response message from the provider with no data-type specific
message payload. A timeout of at least two seconds SHOULD be used; older
Android devices under memory pressure can take this long to instantiate the
broadcast receiver for the query handler and to allow it to process the
request. Shorter timeouts MAY be used for particularly time sensitive queries,
but with the expectation that providers may randomly fail to respond in time.
