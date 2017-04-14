## Initiation

Initiating communication between a service and a credential provider involves
the following steps:

1. Opening an iframe for the credential provider
2. Request origin verification
3. Message channel creation

The user's credential provider preference must be stored somewhere, and must
be (indirectly) accessible to a service in order to be useful. For this purpose,
the URL `https://www.accountchooser.com/openyolo-redirect` is used as a
proxy to the user's credential provider: by opening a frame to this URL,
a redirect will occur from that URL to the user's credential provider, or
`https://www.accountchooser.com/openyolo-provider` as the fallback, default
provider.

In order to facilitate origin verification, Some initial parameters are passed:

- An asserted service origin, e.g. "login.example.com". This _must_ match the
  origin of the requesting page, a property which is enforced by subsequent
  stages of the initiation process.

- A connection challenge. Similar to [PKCE][rfc7636], a nonce is generated
  and a hash of this nonce is sent. The original nonce value is later used
  to prove the relationship between the initial request and the channel
  initiator, which can prevent an injected script from hijacking the
  connection.

A typical URL for provider frame creation would therefore look like:

```
https://www.accountchooser.com/openyolo-provider?
    origin=login.example.com&
    nonceHash=sha256-asdfa...
```

### Request origin verification


