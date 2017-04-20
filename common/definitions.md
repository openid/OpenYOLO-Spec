# OpenYOLO concepts and definitions

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

- An optional _display picture_, that fulfills a similar role to display name.
  Typically, the display picture is either a picture of the user, an avatar that they have chosen, or one they been assigned.

- An optional _password_, which is a human-readable secret used to authenticate
  with the service. Specifically, this field _must not_ be used to store
  secrets that a user would not use directly, such as bearer tokens.

- An optional _ID token_, which provides "proof of access" to the identifier
  of the credential such as an email address or phone number.

- An optional additional set of non-standard properties. This provides the
  ability for credential providers to innovate within the constraints of the
  specification, with a view to later standardizing useful properties. Services
  _should not_ rely upon additional properties, as their meaning is unlikely
  to be consistent across credential providers.

Formally, a credential is structured as the following protocol buffer message:

```protobuf
message Credential {
  // required fields:
  string id = 1;
  string authDomain = 2;
  string authMethod = 3;

  // optional fields:
  string displayName = 4;
  string displayPictureUri = 5;
  string password = 6;
  string idToken = 7;
  map<string, bytes> additionalProps = 8;
}
```

As password based credentials as so common, a field is reserved for this use
on Credential messages.

## Credential providers

A _credential provider_ is a _credential manager_ which implements the
OpenYOLO protocol. Credential providers are typically one of
the following:

- A dedicated service whose sole purpose is to store and recall credentials for
  the user.

- A web browser or custom input method, which provides credential management,
  but not as its primary focus.

- An operating system service, such as Smart Lock for Passwords on Android or
  Keychain on iOS.

While any service can become a credential provider by implementing the OpenYOLO
protocol, only services for which credential management is a defined and visible
feature should become credential providers.

### Known, unknown and preferred providers

Given the sensitive nature of the data being exchanged by the OpenYOLO protocol,
it  will become an obvious target for attackers. A likely attack is for a
suspicious service to implement the OpenYOLO protocol and attempt to register
themselves as the user's credential provider. Distinguishing legitimate
credential providers from malicious providers is therefore an important aspect
of building trust in the protocol, for both service maintainers and users.

In order to achieve this, a _known provider_ list will be maintained by the
OpenID Foundation. A static snapshot of this list is included in the OpenYOLO
API on each platform, and is automatically updated by the client library when
necessary.

An _unknown_ provider will still be usable - the intention of the known provider
list is not to strictly whitelist providers, as this would stifle competition.
However, additional user consent will be required upon every interaction with
an unknown provider, to ensure the user is aware of the potential risks.
Known providers will not have this restriction, and legitimate credential
providers will be encouraged to register themselves with the OpenID Foundation
to become known providers.

Additionally, where possible on each supported platform, the user _should_
be able to specify their _preferred_ credential provider. This preferred
provider will be used exclusively for assisted sign-up and credential saving.
For credential retrieval, additional providers _may_ still be used.

## Authentication domains

An _authentication domain_ is defined to be a scope within which a credential
is considered to be usable. Authentication domains are represented as absolute,
hierarchical URIs of form `scheme://authority` - no path, query or fragment is
permitted.

Two forms of authentication domain are defined for OpenYOLO:

- Web authentication domains, which match the domain of the site and can have
  either a http or https scheme (e.g. `https://example.com` and
  `http://www.example.com` are valid web authentication domains). HTTPS is
  _strongly preferred_ for use with OpenYOLO, but HTTP is also supported for
  testing and development purposes.

- Android authentication domains, of form `android://fingerprint@package` where
  `package` is the package name of an app (e.g. com.example.app), and
  `fingerprint` is a Base64, URL-safe encoding of the app's public key
  (provided by the [Signature][signature-class] type in Android). The fingerprint string includes both the hash algorithm used, and the hash data,
  e.g. `sha512-7fmduHK...`. All OpenYOLO credential providers _must_ support
  both `sha256` and `sha512` as hash algorithms for fingerprints, and _may_
  support any other hash algorithm that provides equivalent or better
  security than SHA-256.

An _authentication system_ which validates credentials
may be represented by multiple distinct authentication domains. For example,
a credential for `android://sha256-...@com.example.app` may be usable on
`https://example.com` or `https://www.example.com`, when these three entities
all use the same authentication system.

An authentication domain _equivalence class_ defines the set of authentication
domains associated with a given authentication system, and therefore the
places where credentials can be used safely across domains. Such equivalence
classes improve the usability of OpenYOLO, but must be carefully defined to
avoid compromising the security of a user's credentials - equivalence classes
_must_ explicitly defined by the service and not assumed or heuristically
constructed by the credential provider.

OpenYOLO recommends the use of the [Digital Asset Links][asset-links] as a
standard mechanism to define authentication domain equivalence classes.
Credential providers _should_ use this information as part of defining the
equivalence class over authentication domains. It is the responsibility of the
credential provider to correctly construct and enforce the authentication
domain equivalence class.

## Authentication methods

An _authentication method_ is a mechanism by which a user credential can be
verified, and is given a unique URI identifier. Any URI of form
`scheme://authority` can be used to describe an authentication method. URIs
of this form are used to allow for namespacing of custom authentication methods,
by using a custom (private) scheme. OpenYOLO defines some standard URIs for the
three most common types of authentication methods:

- Email identifier based authentication. This implies that the primary
  identifier of the account (from the user's perspective, at least) is their
  email address. Authentication requires a password or proof of access to
  the stated email address. The URI for this authentication method is
  standardized as `openyolo://email`.

- Phone number based authentication. This implies that the primary identifier
  for the account is a phone number, represented to OpenYOLO in
  [E.164](https://www.itu.int/rec/T-REC-E.164/en) format. Authentication
  requires a password or proof of access to the stated phone number. The URI
  for this authentication method is standardized as `openyolo://phone`.

- User name and password based authentication. This implies that the primary
  identifier is some printable unicode string of characters, and that
  authentication requires a password. The URI for this authentication method is
  standardized as `openyolo://username`.

Where a federated credential from an identity provider is desired,
the canonical domain of that identity provider's authentication endpoints
_should_ be as the authentication method. OpenYOLO considers the _canonical_ domain for an identity provider to be the domain on which that providers' sign in page is located. For example, the URI that should be
used for Google Sign-in is `https://accounts.google.com`, while the URI that
should be used for Facebook Sign-in accounts is `https://www.facebook.com`.

Use of consistent authentication method URIs for identity providers is strongly
recommended, as this helps with hint retrieval - use of federated credentials
on other services can be surfaced more easily when consistent authentication
methods are used.

## Password specifications

services that support password based authentication often impose some
restrictions on what is considered to be a valid and sufficiently secure
password for the service. While the intentions behind these restrictions
are often well-meaning, the inconsistency of these restrictions across different
services is a constant source of frustration for both users and credential managers.

When credential managers attempt to generate passwords for a service, they are
forced to generate using some "lowest common denominator" heuristic
that produces passwords that are broadly supported. As even this can fail, they
often must provide a way for the user to modify these generated passwords to
fit the particular requirements of the service.

A better approach would be for the service to declare its password restrictions
in a format that can be consumed by credential managers. OpenYOLO defines
a simple scheme for this, composed of the following pieces of information:

- The set of allowed characters in a password, which _must_ be a subset of the
  ASCII printable character set.
- The minimum and maximum length of a password.
- Zero or more _required character sets_. A required character set must be
  a subset of the allowed character set, and specify the minimum number of
  characters from this set that must occur in the password. Where multiple
  required character sets are defined, the sets must be disjoint.

This is formally defined by the following protocol buffer messages:

```protobuf
message PasswordSpecification {
  string allowed = 1; // required
  uint32 minSize = 2; // required
  uint32 maxSize = 3; // required
  repeated RequiredCharSet requiredSets = 4;
}

message RequiredCharSet {
  string chars = 1; // required
  uint32 count = 2; // required
}
```

This allows the expression of most password restrictions. As an example,
consider an authentication system that requires passwords be:

- Composed of any ASCII printable characters
- Be between 6 and 128 characters long
- Have at least one upper case character and one number.

This can be defined as follows (with the full contents of the allowed
character set abbreviated):

```json
{
  "allowed": "abcdef...",
  "minSize": 6,
  "maxSize": 128,
  "requiredSets": [
    {
      "chars": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
      "count": 1
    },
    {
      "chars": "1234567890",
      "count": 1
    }
  ]
}
```

Other common forms of credential, such as PIN numbers, can also be easily
defined:

```json
{
  "allowed": "0123456789",
  "minSize": 6,
  "maxSize": 6
}
```

The default password specification used by OpenYOLO, where a provider does
not explicitly specify an alternative, is:

```json
{
  "allowed": "abcdefghijkmnopqrstxyzABCDEFGHJKLMNPQRSTXY3456789",
  "minSize": 12,
  "maxSize": 16,
  "requiredSets": [
    {
      "chars": "abcdefghijkmnopqrstxyz",
      "count": 1
    },
    {
      "chars": "ABCDEFGHJKLMNPQRSTXY",
      "count": 1
    },
    {
      "chars": "3456789",
      "count": 1
    }
  ]
}
```

This produces passwords of length 12 to 16 based on a
"distinguishable" character set. Characters which look similar, such as
l (Lima), I (India) and 1 (one) are omitted so as to avoid transcription errors
should the user ever have to view and copy a generated password manually. It
is designed to be broadly compatible and produce passwords with sufficient
entropy to resist offline attacks, but it is still preferable for services
to declare their own password restrictions.

It is worth noting that this specification does not support the definition of the following types of password restriction:

- Positional restrictions, such as "the first character cannot be a number"
  or "the last two characters cannot be numbers".
- Semantic restrictions, such as "the password cannot contain an english
  word" or "the password cannot contain a year".

Such restrictions are either indicative of some anti-pattern in the underlying
credential store (e.g. the credential is stored in plain text), or are just
too difficult to define a clear specification of expected behavior.


[asset-links]: https://developers.google.com/digital-asset-links/
[cancel-result]: https://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED
[intent-results]: https://developer.android.com/training/basics/intents/result.html
[intent-overview]: https://developer.android.com/guide/components/intents-filters.html
[protobuf]: https://developers.google.com/protocol-buffers
[signature-class]: https://developer.android.com/reference/android/content/pm/Signature.html
