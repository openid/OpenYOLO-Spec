# Definitions

Before providing a high level overview of the OpenYOLO operations, some
terms that will be used throughout the discussion must be defined. Where data
structures are described, this document uses
[Protocol Buffer v3 messages][protobuf] as the definition language.

## Credentials

A _credential_ is a set of properties that are used to help authenticate a user.
Credentials can be _partial_, where they do not provide all
necessary information for authentication.

Credentials in OpenYOLO are composed of the following properties:

- An _authentication domain_, where the credential can be used. The
  authentication domain is often _implicit_, inferred from the origin or
  Android package name of a service. However, all stored credentials must have
  an associated authentication domain - there are no "ephemeral" credentials.

- An _authentication method_, which describes the system used to verify
  the credential.

- An _identifier_ which designates an account in the context of
  both the authentication domain and method. Typically, identifiers are
  email addresses, phone numbers, or some alphanumeric string. Identifiers
  are not always intended to be human readable.

- An optional _display name_, that assists the user in identifying and
  distinguishing credentials. Typically, the display name for a credential is
  the user's real name, or a chosen alias.

- An optional _display picture_, that fufills a similar role to display name.
  Typically, the display picture is either a picture of the user, an avatar that they have chosen, or one they been assigned.

Formally, a credential is structed as follows:

```protobuf
message Credential {
    string id                = 1; // required
    string authDomain        = 2; // required
    string authMethod        = 3; // required
    string displayName       = 4;
    string displayPictureUri = 5;
    string password          = 6;

    repeated KeyValuePair additionalProps = 7;
}
```

As password based credentials as so common, a field is reserved for this use
on Credential messages.

## Credential providers

A _credential provider_ is defined in OpenYOLO to be any application which
provides the required broadcast receivers and activity intent filters to
handle all OpenYOLO operations. Credential providers are typically one of
the following:

- Dedicated apps whose sole purpose is to store and protect credentials a
  user has chosen to store.

- Browsers which save and form-fill credentials. Many sites have dedicated
  Android applications which can benefit from retrieving credentials that are
  already stored in the browser.

- System services such as Smart Lock for Passwords which can store credentials
  for the user in the absence of other installed alternatives.

While any app can become a credential provider by supporting the
required OpenYOLO endpoints, only apps for which credential management is a
clearly declared and visible feature to the user should become credential
providers. [Protecting users](protecting-users.md) describes these criteria
in more detail, and the technical counter-measures that are taken to make it
difficult for inappropriate or malicious apps to be used as credential
providers.

### Known and unknown providers

Given the sensitive nature of the data being exchanged by OpenYOLO, the protocol
will become an obvious target for attackers. Attackers are likely to try and
register themselves as credential providers, and attempt to trick users into
providing credentials to them. Distinguishing legitimate credential
providers from malicious providers is therefore an important aspect of building
trust in the protocol, for both app developers and users.

In order to achieve this, a "known provider" list will be hosted by the
OpenID Foundation. A static version of this list is included in the OpenYOLO
API on each platform, and is automatically updated by client library when
necessary.

An "unknown" provider will still be usable, however the experience will be
deliberately downgraded in order to ensure the user is aware of the risks of
using such a provider. Generally, this will entail asking for consent
to proceed from the user before every OpenYOLO operation. Known providers will
not have this restriction.

Where possible on each supported platform, the user _should_ be able to store
their preferred credential provider. Additional providers _may_ still be used
during credential retrieval, but the preferred provider is exclusively used
for the purposes of saving and generating credentials. See the platform-specific
sections for more details on how this preference is used and modified.

## Authentication domains

An _authentication domain_ is defined in OpenYOLO to be a scope within
which a credential is considered to be usable. Authentication domains are
represented as absolute, hierarchical URIs of form `scheme://authority` -
no path, query or fragment is permitted.

Two forms of authentication domain are defined for OpenYOLO:

- Android authentication domains, of form `android://FINGERPRINT@PACKAGE` where
  `PACKAGE` is the package name of an app and `FINGERPRINT` is a
  Base64, URL-safe encoding of the app's public key (provided by
  the [Signature][signature-class] type in Android). The fingerprint string
  includes both the hash used, and the hash data, e.g.
  `sha512-7fmduHK...`. All OpenYOLO credential providers _must_ support both
  `sha256` and `sha512` for fingerprints.

- Web authentication domains, which match the domain of the site and can have
  either a http or https scheme (e.g. `https://example.com` and
  `http://www.example.com` are valid web authentication domains).

A single _authentication system_, which maintains and validates credentials,
may be represented by multiple distinct authentication domains. For example,
a credential for `android://...@com.example.app` may be usable on
`https://example.com` or `https://www.example.com`, when these three entities
all use the same authentication system.
However, it is important that `android://HASH-A@com.example.app` and
`android://HASH-B@com.example.app` should not be treated as equivalent
_automatically_ - either could represent a compromised, side-loaded variant of
an app that is attempting to steal user credentials.

An authentication domain _equivalence class_ defines the set of authentication
domains across which a given credential can be freely shared. Such equivalence
classes improve the usability of OpenYOLO, but must be carefully defined to
avoid compromising the security of a user's credentials.

OpenYOLO recommends the use of the [Digital Asset Links][asset-links] as a
standard source of app and site relationships. Credential providers _should_
use this information as part of defining the equivalence class over
authentication domains, but they may also use additional information. It
is the responsibility of the credential provider to correctly construct
and enforce the authentication domain equivalence class.

## Authentication methods

An _authentication method_ is a mechanism by which a user credential can be
verified, and is given a unique URI identifier. Any URI of form
`scheme://authority` can be used to describe an authentication method; OpenYOLO
defines some standard URIs for the two most common types of authentication
method:

- Identifier and password based authentication under the direct control of the
  app, where the identifier and password are non-empty strings composed of
  printable ASCII characters. The URI for this authentication method is
  standardized as `openyolo://id-and-password`.

- Federated credentials (e.g. OpenID Connect), where a user identifier is
  passed to an identity provider (that is typically not controlled by the app).
  with some supporting information that identifies the app. The URI
  used to denote authentication with an identity provider is based upon the
  origin to which federated requests are typically sent for that provider.
  For example, the URI that should be used for Google Sign-in accounts is
  `https://accounts.google.com`, while the URI that should be used for
  Facebook Sign-in accounts is `https://www.facebook.com`. Other common
  federated identity provider URIs are defined in the OpenYOLO specification.
  Any authentication mechanism with protocol http or https is assumed to
  represent an federated identity provider.


[asset-links]: https://developers.google.com/digital-asset-links/
[cancel-result]: https://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED
[intent-results]: https://developer.android.com/training/basics/intents/result.html
[intent-overview]: https://developer.android.com/guide/components/intents-filters.html
[protobuf]: https://developers.google.com/protocol-buffers
[signature-class]: https://developer.android.com/reference/android/content/pm/Signature.html
