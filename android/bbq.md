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

### Dispatching requests

A request is dispatched as one or more targeted broadcast intents. First, the
requester uses the Android [PackageManager][android-package-manager] API to
determine the set of apps which can provide data of the required type:

```java
Intent intent = new Intent(dataType);
intent.addCategory(BBQ_CATEGORY);
List<ResolveInfo> responderInfos =
    packageManager.queryBroadcastReceivers(intent, 0);
```

A separate request is created for each potential responder, with a unique
response ID, and sent as a targeted broadcast:

```java
BroadcastQuery query = BroadcastQuery.newBuilder()
    /* ... */
    .setResponseId(idForResponder.get(responder))
    .build();
Intent bbqIntent = new Intent(dataType);
bbqIntent.setPackage(responder);
bbqIntent.setExtra(EXTRA_QUERY_MESSAGE, query.encode());
context.sendBroadcast(bbqIntent);
```

### BBQ responses

A broadcast query response has the following mandatory properties:

- The 64-bit request ID that the response is associated with, copied from the
  request.
- The 64-bit response ID unique to this response, copied from the request.

Query responses are also represented as a protocol buffer messages.
The response copies the request and response IDs from the request message,
and may include a data-type specific response message, if necessary.
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

### Dispatching responses

Responses are sent back to the requester in the form of targeted broadcasts.
The requester dynamically registers a broadcast receiver to capture
responses. The _ACTION_ for the response is the requested data type with the
request ID concatenated in zero-padded hex form, e.g.
"org.openyolo.credential:000000000000CAFE" where "org.openyolo.credential" is
the requested data type and "000000000000CAFE" is the request ID (51966 in
decimal).

```java
IntentFilter filter = new IntentFilter();
filter.addAction(encodeAction(dataType, requestId));
filter.addCategory(BBQ_CATEGORY);
context.registerReceiver(new BroadcastReciever() { ... }, filter);
```

In order to avoid waiting indefinitely for responses from faulty or slow
receivers, a timeout _should_ be used, after which absent responses should be
treated as though the provider was unable to service the request (equivalent to
responding with no data-type specific message payload).

