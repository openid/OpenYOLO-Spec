# OpenYOLO concepts and definitions

Before providing a high level overview of the OpenYOLO operations, some
terms that will be used throughout the specification must be defined. Where
data structures are described, this document uses
[protocol buffer v3 messages][protobuf] as the definition language. Where
specific instances of these messages are presented, the
[Protocol Buffer v3 JSON encoding][protobuf-json] is used.

## Credentials

A _credential_ is a set of properties that are used to help authenticate a user.
Credentials can be _partial_, where they do not provide all
necessary information for authentication.

Credentials in OpenYOLO are composed of the following properties:

- An _authentication domain_, where the credential was saved.
  All credentials MUST have an associated authentication domain. A credential
  MAY be usable on other authentication domains. Authentication domains are
  described in more detail in [SECTION](#authentication-domains).

- An _authentication method_, which describes the system used to verify
  the credential. All credentials MUST have an associated authentication
  method. Authentication methods are described in more detail in
  [SECTION](#authentication-methods).

- An _identifier_, which designates an account in the context of
  both the authentication domain and method. All credentials MUST have an
  identifier. Typically, identifiers are
  email addresses, phone numbers, or some printable unicode string. Identifiers
  are typically human readable and distinguishable, but this is not a
  requirement.

- An optional _display name_, that assists the user in identifying and
  distinguishing credentials. Typically, the display name for a credential is
  the user's real name, or a chosen alias.

- An optional _display picture_, that fulfills a similar role to display name.
  Typically, the display picture is either a picture of the user, an avatar that they have chosen, or one they been assigned.

- An optional _password_, which is a human-readable secret used to authenticate
  with the service. Specifically, this field MUST NOT be used to store
  secrets that a user would not use directly, such as bearer tokens.

- An optional _ID token_, which provides "proof of access" to the identifier
  of the credential such as an email address or phone number.

- An optional set of non-standard properties. This provides the
  ability for credential providers to innovate within the constraints of the
  specification, with a view to later standardizing useful properties. Services
  SHOULD NOT rely upon additional properties, as their meaning is unlikely
  to be consistent across credential providers.

A credential is represented by the following protocol buffer message:

```protobuf
message Credential {
  // required
  string id = 1;

  // required
  AuthenticationDomain auth_domain = 2;

  // required
  AuthenticationMethod auth_method = 3;

  string display_name = 4;
  string display_picture_uri = 5;
  string password = 6;
  string id_token = 7;
  map<string, bytes> additional_props = 8;
}
```

For example, an email and password credential could look like:

```json
{
  "id": "jdoe@example.com",
  "auth_domain": {
    "uri": "https://www.example.com"
  },
  "auth_method": {
    "uri": "openyolo://email"
  },
  "display_name": "Jane Doe",
  "display_picture_uri": "https://www.robohash.org/jdoe",
  "password": "RiverClyde7"
}
```

### Hints

Hints are a variant of credentials that are tailored to account discovery
and new account creation. They are represented by a separate protocol buffer
message from credentials, in order to allow for future extension that might
diverge from the definition of credentials. Hints are represented by the
following protocol buffer message:

```protobuf
message Hint {
  // required
  string id = 1;

  // required
  AuthenticationMethod auth_method = 3;

  string display_name = 4;
  string display_picture_uri = 5;
  string generated_password = 6;
  string id_token = 7;
  map<string, bytes> additional_props = 8;
}
```

The two main differences from credentials are that noo authentication domain is
declared, and that the `password` field is renamed to `generated_password`, to
express its intent more clearly.

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

### Known, unknown and preferred providers

Given the sensitive nature of the data being exchanged by the OpenYOLO protocol,
it will become a target for attackers. A likely attack is for a
suspicious service to implement the OpenYOLO protocol and attempt to register
themselves as the user's credential provider. Distinguishing legitimate
credential providers from malicious providers is therefore an important aspect
of building trust in the protocol, for both service maintainers and users.

In order to achieve this, a _known provider_ list will be maintained by the
OpenID Foundation. A static snapshot of this list is included in the OpenYOLO
API on each platform, and will be automatically updated by the client library
when necessary.

An _unknown_ provider will still be usable - the intention of the known provider
list is not to strictly whitelist providers, as this would stifle competition.
However, additional user consent will be required upon every interaction with
an unknown provider, to ensure the user is aware of the potential risks.
Known providers will not have this restriction, and legitimate credential
providers will be encouraged to register themselves with the OpenID Foundation
to become known providers.

Where possible on each supported platform, the user SHOULD
be able to specify their _preferred_ credential provider. This preferred
provider will be used exclusively for assisted sign-up and credential saving.
For credential retrieval, additional providers MAY still be used.

## Token providers

A _token provider_ is a service that is able to issue an authoritative
"proof of access" ID token for an identifier. For example, Google is the
token provider for all "gmail.com" email addresses, while Microsoft is the
token provider for all "live.com" email addresses.

Token providers are identified by their canonical token-issuing domain,
which hosts the token endpoint that provides ID tokens. In the case of Google,
this is `https://accounts.google.com`.

Token providers can be authoritative for a large set of domains or numbers, and
there is not often an easy way to determine in advance the token provider for a
given domain. OpenYOLO does yet not attempt to solve this particular problem.

## Authentication domains

An _authentication domain_ is defined to be a scope within which a credential
is considered to be usable. Authentication domains are represented as absolute,
hierarchical URIs of form `scheme://authority` - no path, query or fragment is
permitted.

In protocol buffer form, an authentication domain is represented by the
following message:

```protobuf
message AuthenticationDomain {
  // required
  string uri = 1;
}
```

The URI is encapsulated in a message to allow for future extensibility of
the concept of an authentication domain, without altering the structure of
containing messages.

Two forms of authentication domain are presently defined:

- Web authentication domains, which match the domain of the site and can have
  either a http or https scheme (e.g. `https://example.com` and
  `http://www.example.com` are valid web authentication domains). HTTPS is
  _strongly preferred_ for use with OpenYOLO, but HTTP is also supported for
  testing and development purposes.

- Android authentication domains, of form `android://fingerprint@package` where
  `package` is the package name of an app (e.g. com.example.app), and
  `fingerprint` is a Base64, URL-safe encoding of the app's public key
  (provided by the [Signature][signature-class] type in Android). The fingerprint string includes both the hash algorithm used, and the hash data,
  e.g. `sha512-7fmduHK...`. All OpenYOLO credential providers MUST support
  both `sha256` and `sha512` as hash algorithms for fingerprints, and MAY
  support any other hash algorithm that provides equivalent or better
  security than SHA-256.

An _authentication system_ which validates credentials
MAY be represented by multiple distinct authentication domains. For example,
a credential for `android://sha256-...@com.example.app` might be usable on
`https://example.com` or `https://www.example.com`, when these three entities
all use the same authentication system.

An authentication domain _equivalence class_ defines the set of authentication
domains associated with a given authentication system, and therefore the
places where credentials can be used safely across domains. Such equivalence
classes improve the usability of OpenYOLO, but must be carefully defined to
avoid compromising the security of a user's credentials. Equivalence classes
SHOULD be explicitly defined by the service that owns the associated domains
and apps, and SHOULD NOT be assumed or heuristically constructed by the
credential provider.

OpenYOLO recommends the use of the [Digital Asset Links][asset-links] as a
standard mechanism to define authentication domain equivalence classes.
Credential providers SHOULD use this information as part of defining the
equivalence class over authentication domains. It is the responsibility of the
credential provider to correctly construct and utilize the authentication
domain equivalence class.

## Authentication methods

An _authentication method_ is a mechanism by which a user credential can be
verified, and is given a unique URI identifier. Any URI of form
`scheme://authority` can be used to describe an authentication method. URIs
of this form are used to allow for namespacing of custom authentication methods,
by using a custom (private) scheme.

In protocol buffer form, authentication methods are represented by the
following message:

```protobuf
message AuthenticationMethod {
    // required
    string uri = 1;
}
```

The URI is encapsulated in a message to allow for future extensibility of
the concept of an authentication method, without altering the structure of
containing messages.

OpenYOLO defines some standard URIs for the three most common types of
authentication methods:

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
the canonical domain of that identity provider SHOULD be used as the
authentication method. The _canonical_ domain for an identity provider is
the domain that hosts the provider's sign in page. For example, the URI that
should be used for Google Sign-in is `https://accounts.google.com`, while the
URI that should be used for Facebook Sign-in accounts is
`https://www.facebook.com`.

Use of consistent authentication method URIs for identity providers is strongly
recommended, as this helps with hint retrieval - use of federated credentials
on other services can be surfaced more easily when consistent authentication
methods are used.

## Password specifications

services that support password based authentication often impose
restrictions on what is considered to be a valid password for the service.
While the intentions behind these restrictions are often well-meaning, the
inconsistency of these restrictions across different services is a source of
frustration for both users and credential managers.

When credential managers attempt to generate passwords for a service, they are
forced to use a "lowest common denominator" heuristic that produces broadly
supported passwords. Even this can fail, requiring the user to modify the
generated password.

A better approach is for the service to declare its password restrictions
in a format that can be consumed by credential managers. OpenYOLO defines
a simple scheme for this, composed of the following pieces of information:

- The set of allowed characters in a password, which MUST be a subset of the
  ASCII printable character set.
- The minimum and maximum length of a password.
- Zero or more _required character sets_. A required character set MUST be
  a subset of the allowed character set, and specify the minimum number of
  characters from this set that must occur in the password. Where multiple
  required character sets are defined, the sets MUST be disjoint.

This is represented by the following protocol buffer message:

```protobuf
message PasswordSpecification {
  // required
  string allowed = 1;

  // required
  uint32 min_size = 2;

  // required
  uint32 max_size = 3;

  repeated RequiredCharSet required_sets = 4;
}

message RequiredCharSet {
  // required
  string chars = 1;

  // required
  uint32 count = 2;
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
  "min_size": 6,
  "max_size": 128,
  "required_sets": [
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
  "min_size": 6,
  "max_size": 6
}
```

The default password specification used by OpenYOLO, where a provider does
not explicitly specify an alternative, is:

```json
{
  "allowed": "abcdefghijkmnopqrstxyzABCDEFGHJKLMNPQRSTXY3456789",
  "min_size": 12,
  "max_size": 16,
  "required_sets": [
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

## Client versions

OpenYOLO client libraries will typically be compiled in to service
implementations, and therefore cannot be changed without releasing a new
version of the service that client devices must download. Bugs are inevitable,
and where these bugs impact the security of the client it is important to
have a mechanism to protect services from the exploitation of these bugs.

In order to facilitate this, requests sent from a service to a credential
provider SHOULD carry a _client version_ descriptor, which is typically
compiled into the OpenYOLO client library they are using. This allows a
credential provider to identify services which are using an exploitable version
of the client library, and to reject requests from these clients.

In OpenYOLO, a client version is composed of:

- A _vendor_ string, which identifies the author of the client. For the
  official client libraries shipped by the OpenID Foundation, this will be
  "openid.net".

- A major, minor and patch version number. Each are non-negative numbers
  and typically represented in the human-readable form "X.Y.Z", and follow
  the general principles of [Semantic Versioning](http://semver.org/).

In order to prevent trivial modification of the client version, it SHOULD
be statically compiled in to the client library. There is no way to guarantee
that the client version cannot be tampered with by an attacker, however; as
such, client versions SHOULD NOT be interpreted as authoritative, and
SHOULD NOT be used for purposes other than blacklisting of known problematic
client versions only.

In protocol buffer form, a client version is represented by the
following message:

```protobuf
message ClientVersion {
  // required
  string vendor = 1;

  // required
  uint32 major = 3;

  // required
  uint32 minor = 4;

  // required
  uint32 patch = 5;
}
```

An example client version could look like:

```json
{
  "vendor": "openid.net",
  "major": 1,
  "minor": 0,
  "patch": 12
}
```

[asset-links]: https://developers.google.com/digital-asset-links/
[cancel-result]: https://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED
[intent-results]: https://developer.android.com/training/basics/intents/result.html
[intent-overview]: https://developer.android.com/guide/components/intents-filters.html
[protobuf]: https://developers.google.com/protocol-buffers
[protobuf-json]: https://developers.google.com/protocol-buffers/docs/proto3#json
[signature-class]: https://developer.android.com/reference/android/content/pm/Signature.html
