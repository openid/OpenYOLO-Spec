# Retrieving credentials

Credential retrieval requests are dispatched using the
[BBQ protocol](bbq-protocol.md) to all credential providers on the device
simultaneously. This is particularly useful for users who have more than one
credential provider, such as Smart Lock for Passwords (present on all devices
with Google apps), and Dashlane, which the user has chosen to install. Such
users are often in a state where disjoint sets of credentials are stored in
each, so querying both increases the chance that a credential can be found.

The BBQ protocol uses [Android broadcast intents][intent-overview] with
recipients specified by package name in order to asynchronously deliver
requests and responses. A retrieval request carries the following information:

- The set of authentication mechanisms that are supported by the requester.

It is recommended that an app send a credential request whenever a user would
typically be required to sign in manually, and _before_ any login UI is shown.
Some intermediate UI (such as a loading screen) can be displayed while waiting
for a response. If a credential is available, the entire manual sign-in flow
can be skipped, resulting in an improved user experience.

Retrieval responses may carry an intent that can be used to retrieve a
credential from a provider. Providers respond with no intent if they know that
they do not have a credential for the provider, or if they refuse to service
the request. Providers _may_ respond with an intent even if they do not know
that they have a credential available: providers which use a master password
to encrypt their stores which is not stored to disk may require the user to
take an action to unlock the store before an accurate answer can be determined.

Where an intent is returned, [startActivityForResult][intent-results] is used
to dispatch it, and the selected credential data (if any) is returned via `onActivityResult`.

## Retrieve request messages

```protobuf
message CredentialRetrieveRequest {
    repeated string       authMethods        = 2; // at least one required
    repeated KeyValuePair additionalParams   = 3;
}
```

The CredentialRetrieveRequest must explicitly specify all credentials qualifiers the client
supports with the exception of the authentication domain which will determined implicitly via the
callers package name.

## Retrieve response messages

```protobuf
message CredentialRetrieveResponse {
    optional bytes        retrieveIntent   = 1; // required
    repeated KeyValuePair additionalParams = 2;
}
```

Providers indicate whether they may be able to provide a credential to the
requester by responding with a message that optionally contains an activity
[Intent][intent-class]
to retrieve the credential. The absence of an intent in the response indicates
that the provider knows that it does not have an available credential, or is
refusing to serve the request.

An activity intent is used for the final stage of retrieving the request to
allow the credential provider to interact with the user in some way before
releasing the credential. Many credential providers will require an unlock code
(a PIN number, password or recognized fingerprint) in order to decrypt and
release the credential, or may simply wish to notify the user that the
credential is being released to avoid surprising the user.

If the requester receives more than one Intent-carrying response, the user
should be prompted to choose between the available options. If no
intent-carrying responses are received, then the requester should proceed to
a manual sign-in.

## Retrieve intent responses

The intent should be dispatched using [startActivityForResult][intent-results],
allowing the response to be delivered to via `onActivityResult`. The provider
can describe two outcomes to this process:

- The operation was canceled (indicated by
  [ACTIVITY_CANCELED][result-canceled]). This can occur as a result of the user
  failing to enter their unlock code correctly, or explicitly canceling the
  flow.
- The operation succeeded (indicated by [ACTIVITY_OK][result-ok]), and a
  credential is carried in the response. The credential is encrypted using the
  shared secret established by the BBQ protocol.

When provided with a credential, the application should immediately attempt to
use this credential, and should do so without requiring any additional user
input (e.g. pressing a "sign in" button).

[intent-class]: https://developer.android.com/reference/android/content/Intent.html
[intent-results]: https://developer.android.com/training/basics/intents/result.html
[result-canceled]: https://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED
[result-ok]: https://developer.android.com/reference/android/app/Activity.html#RESULT_OK
