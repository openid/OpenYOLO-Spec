## Retrieving Hints

If no existing credentials can be retrieved from a credential provider,
then OpenYOLO provides a fall-back mechanism that can be used to help in
creating a new account. This mechanism will typically allow a new user
account to be created without the need to manually enter any information.

First, the app must provide a descriptor of the types of credentials that
it can support. This is done by providing a list of one or more
supported authentication methods. If password authentication is supported,
then a _password specification_ can optionally be provided that describes
the set of passwords that the app supports.

This descriptor can then be sent to a credential provider using the OpenYOLO
API in order to derive a credential hint. If a default credential provider can
be determined by the OpenYOLO API, then it will construct an intent to send the
descriptor to this provider and return it for the app to dispatch when ready.
Similarly, if only one credential provider is available on the device and it is
a "known" provider, then an intent to directly interact with that provider will
be constructed and returned. See [Protecting users](protecting-users.md) for
details on default and known providers.

If no default provider is found or multiple providers exist, an intent
is constructed for a dialog that will allow the user to choose a provider,
after which an intent will be dispatched to that provider containing the
descriptor.

The flow for creating a credential hint based on the descriptor is under the
control of the provider, and not part of this specification. A hint constructed
by the provider is returned to the app via the intent data carried by
`onActivityResult`.
