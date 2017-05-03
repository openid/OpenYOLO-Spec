% title = "OpenYOLO for Android"
% docName = "draft-openyolo-android-03"
% submissionType = "independent"
% category = "exp"
% area = "Internet"
% keyword = ["password", "credential", "security"]
%
% [pi]
% toc = "yes"
% symrefs = "no"
%
% [[author]]
% initials="I."
% surname="McGinniss"
% fullname="Iain McGinniss"
% role="Editor"
% organization = "Google, Inc."
% [author.address]
% email = "iainmcgin@google.com"
% phone = "+1-650-253-0000"
% [author.address.postal]
% street = "1600 Amphitheater Parkway"
% city = "Mountain View"
% region = "California"
% country = "United States of America"
% code = "95134"

.# Abstract

OpenYOLO for Android is a protocol for retrieving, updating and assisting in
the creation of authentication credentials. This document describes the core
concepts of OpenYOLO, and the platform-specific details for implementing the
OpenYOLO protocol on Android.

**What's in a name?**

YOLO stands for "You Only Login Once", which is the internal code-name
for Google's [Smart Lock for Passwords][smart-lock] API on Android. OpenYOLO
is the open standards successor to YOLO, and came to be as a result of an
initial collaboration between Google and [Dashlane](https://www.dashlane.com).
OpenYOLO leverages the lessons learned from YOLO, and also ensures that
implementations of OpenYOLO can compete on a level playing field.

OpenYOLO would not have been likely to succeed without
[AgileBits](https://agilebits.com/),
[Keeper Security](https://keepersecurity.com/)
and [LastPass](https://www.lastpass.com/),
to whom we are grateful for their continued support and engagement.

.# Copyright notice

Copyright (c) 2017 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer,
or other interested party a non-exclusive, royalty free, worldwide copyright
license to reproduce, prepare derivative works from, distribute, perform and
display, this Implementers Draft or Final Specification solely for the purposes
of (i) developing specifications, and (ii) implementing Implementers Drafts and
Final Specifications based on such documents, provided that attribution be made
to the OIDF as the source of the material, but that such attribution does not
indicate an endorsement by the OIDF.

The technology described in this specification was made available from
contributions from various sources, including members of the OpenID Foundation
and others. Although the OpenID Foundation has taken steps to help ensure that
the technology is available for distribution, it takes no position regarding
the validity or scope of any intellectual property or other rights that might
be claimed to pertain to the implementation or use of the technology described
in this specification or the extent to which any license under such rights
might or might not be available; neither does it represent that it has made any
independent effort to identify any such rights. The OpenID Foundation and the
contributors to this specification make no (and hereby expressly disclaim any)
warranties (express, implied, or otherwise), including implied warranties of
merchantability, non-infringement, fitness for a particular purpose, or title,
related to this specification, and the entire risk as to implementing this
specification is assumed by the implementer. The OpenID Intellectual Property
Rights policy requires contributors to offer a patent promise not to assert
certain patent claims against other contributors and against implementers. The
OpenID Foundation invites any interested party to bring to its attention any
copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.

.# Requirements Notation and Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119][rfc2119].

# Introduction

Manually authenticating in an app or site is mentally exhausting. Users are
typically presented with a screen like the following when interacting with
an application or website:

{{artwork/auth-screen.md}}

The user typically has to mentally process three questions in response to such
a page:

1. Do I already have an account for this service?
2. If so, did I use an email address and password, or one of the identity
   provider options?
3. If I used an email address and password, what was the password?

For all but most frequently used apps and websites (henceforth referred
to as _services_), this is a tedious and error-prone process. As of 2016,
users typically interact with around [100 services][dashlane-account-survey].
Many of those services are used less than once a month, for
example to buy flowers or arrange air travel. Switching to a new device is a
particularly painful experience due to the need to re-authenticate with all
used services.

Remembering unique account details for 100+ services is infeasible; the
natural human consequence of this situation is widespread credential reuse
across services. This is a disaster for the user's security - an alternative
approach is needed.

## Password authentication

Password based authentication, despite many attempts to displace it,
remains the most common form of authentication in use today. Password
authentication suffers from three key issues:

- User selected passwords are often _weak_. Most users do not know how to
  produce [high entropy passwords][Yan04]. The basic strategies
  employed involve using combinations of common dictionary words, years and
  names, all of which easily succumb to social engineering and dictionary
  attacks.

- Password credentials are often _transferable_. The limits of humans to
  memorize long strings of random information is [well studied][Adams99];
  the typical user cannot be expected to memorize more than 5 passwords
  for unrelated services. The natural consequence is that users frequently
  reuse their passwords, which when combined with email addresses as
  identifiers, makes the credentials transferable across unrelated services.
  If a password is uncovered for a user on one service, an attacker can simply
  try this credential on other services with a high success rate.

- Password credentials are often _long lived_. There is no intrinsic expiration
  time on a password credential, and password rotation is not uniformly
  enforced across all password using services. If a password is uncovered by an
  attacker, it can be used for a significant period of time, perhaps
  indefinitely.

    Even where a service does enforce password rotation, such as once a year,
  "digit rotation" is commonly employed by users to circumvent this: they
  simply increment a counter at some position in the password, typically at the
  end. This makes guessing future passwords from current passwords particularly
  easy for an attacker.

The problems that passwords cause only get worse as users interact with
more and more services. Yet, password authentication persists:

- Password authentication is familiar to users, and is therefore is often
  their default choice.

- It is considered to be easy to implement, despite the numerous account system
  breaches that demonstrate the opposite.

- It has no dependencies on external entities, like identity providers. The
  stability of the system is entirely under the control of the implementer,
  for better or worse.

It is unlikely that password based authentication can be completely displaced;
as such, any solution in this problem space will have to accommodate password
based authentication.

## Federated authentication

Federated authentication, in the form of [OAuth2][oauth2] and
[OpenID Connect][oidc], solves the problem of account overload by centralizing
authentication for the user with a small number of trusted _identity providers_.
Furthermore, by providing proof of authentication to a service (referred to as
a _relying party_ in this context) in the form of cryptographically signed
[ID tokens][rfc7519], overall security is significantly improved
when compared to password based authentication.

However, the success of federated authentication is still limited - OAuth2 and
OpenID Connect are regarded as difficult to implement, and federated
authentication was unnecessarily tainted by "social login" in the early 2010s.
Federated authentication became associated with unnecessary and invasive
sharing of personal information. This association has largely been undone, but
the perception of privacy invasion lingers.

Furthermore, it is easy for users to forget _which_ identity provider they use,
when multiple options are presented. Services also rarely implement
_account linking_ correctly, where multiple authentication methods are attached
to the same core account. Because of this, making the wrong choice often
leads to a totally different account: for example, choosing Google Sign-in when
the user's account was actually created using Facebook. The inconsistency
and frustration caused by this is often enough to drive users to the
authentication method they know best - email and password authentication, with
a reused password across every service.

## Account recovery based authentication

An equally common method of authentication employed by users is to simply
trigger the _account recovery_ flow every time they need to use the service.
Accounts are typically created with a recovery email address or phone number,
and users exploit this fact to regain access to the account when necessary.
They expect the following flow:

1. An email or SMS message will be sent containing a link to reset the
   password.

2. The user clicks the link to change their password, likely to either their
   current reused password, or something else that they immediately forget.

3. The user is now authenticated. When the session expires or the user changes
   device the process is often repeated.

We shall refer to this method of authentication as "proof of access" -
by demonstrating that a secret can be communicated via some trusted
side-channel, the user can gain access to the account. Some services use
this method explicitly, as the main form of authentication -
[Slack](https://www.slack.com) refers to this as "magic link"
authentication.

Sending an authentication secret (a code or a link) to an email address or
phone number is essentially a form of federated authentication. In comparison to
OpenID Connect, this is a rather absurd and inconvenient, as it requires the
user to manually drive the authentication flow. It is, however, a model of
authentication that users find easy to understand, despite its shortcomings.

If it were possible to provide proof of access to an email address
or phone number directly to a service from an authoritative source, then the
manual verification of access to that email or phone number would be
unnecessary. The most common email providers are _also_ OAuth2 or OpenID
Connect identity providers: Google, Microsoft and Yahoo account for over 90% of
the US market, according to a data analysis conducted by
[MailChimp in 2015][email-market-share]. These providers already have
the ability to assert proof of access in the form of
[ID tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).
Providing an easier mechanism to acquire such ID tokens would simplify
authentication for many services.

## Credential managers

A _credential manager_ is a piece of software that remembers credentials
on behalf of a user. Most credential managers focus on
password based authentication, and offer to generate strong, unique password
for each new service a user interacts with.

The most common credential manager that users encounter is their web browser,
which presents itself via form-fill on authentication pages. Technically
knowledgeable users often also have a standalone credential manager.

Credential managers suffer from the following usability issues, which limit
their appeal:

- When a credential manager is a standalone application, the user must
  manually switch context to find the relevant credential, and
  copy-paste it to the service they are signing in to. Browser extensions
  can make this easier, but are not supported on all platforms, in particular
  on mobile devices.

    Manually copying a password also represents a security risk in itself;
  on some platforms it is possible for other applications installed on the
  device to monitor the clipboard and steal passwords that are copied out of
  the credential manager.

- Where a credential manager is able to integrate with the browser or OS in
  some way, heuristics are often necessary to detect and fill in login forms.
  Such heuristics are fragile to changes in the service, such as when they are
  redesigned or change path within the domain. Heuristics are employed because
  there is rarely any viable alternative: services do not provide sufficient
  information for a credential manager to do a better job.

    This problem is particularly acute when the login system employs an
  _identifier first_ pattern, where collection of the identifier and a password
  are split across separate screens. In such situations, heuristics typically
  fail to detect the relationship between the fields across these separate
  screens.

- Credential managers are often blind to relationships between apps and sites
  that share the same authentication system - saving a credential for one site
  does not automatically make this credential available on other, related sites.

- Credential managers do not assist federated authentication: they cannot
  help the user remember if they signed in to the service using Google or
  Facebook, only whether they filled in an identifier and password.

- Credential managers are unaware of password restrictions in use on the site:
  how long they must be, whether they must include a number or symbol, etc. As
  such, _password generation_ is also heuristic and based on a least common
  denominator schema that is acceptable to the majority of services.

## Solution: Direct communication with a credential manager

If services could directly communicate with the user's preferred credential
manager, manual authentication and its associated problems can completely
disappear. If such a communication channel existed, then
the following operations would be possible:

- Account creation facilitated by the credential manager. The service could
  describe to the credential manager what authentication methods it supports,
  and what password restrictions it has. In response, a credential provider
  could (with or without user assistance) select an email address and generate
  a strong, unique password that is guaranteed to work.

- Automatic retrieval of existing credentials. At the appropriate moment, a
  service could request a credential, and have this automatically returned, or
  returned after some in-context user consent is solicited. This would be a
  marked improvement over the user manually finding and copying the credential,
  and minimizes the opportunity for the credential to be stolen in doing so.

- Maintenance of the credential manager store. When the service modifies an
  account, it can notify the credential manager of account changes. This
  information can be used to keep the credential store fresh.

- "Proof of access" to email addresses and phone numbers (as described
  in the
  [account recovery based authentication](#account-recovery-based-authentication)
  section above) could be directly solicited. While the credential manager might
  not have the authority to generate an ID token for a given email address, it
  could facilitate this process.

OpenYOLO defines a protocol for direct communication between services and
credential managers, in order to enable these operations.

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

# Operations

OpenYOLO defines four core operations:

- _hint retrieval_: Provides basic account information to help create a new
  account.
- _credential retrieval_: Provides access to an existing stored credential for
  the requesting service.
- _credential saving_: Allows a service to store or update a credential in
  a credential provider.
- _credential deletion_: Allows a service to delete a credential which is no
  longer valid.

A provider MAY implement any subset of these operations; none are required.
Each operation is described in more detail in the following sections.

## Hint retrieval

When an service wants to create a new account for the user, they typically
need the following core pieces of information:

- The _authentication method_ that the user prefers to use, drawn from the
  set that the service supports. For instance, a service might allow a user
  to create an account with a phone number, Google Sign-in or Facebook
  Sign-in. If a non-federated authentication method is used, a
  _generated password_ that conforms to the service's password restrictions
  is desirable.

- A unique _identifier_ for the account, which is typically an email address,
  or phone number that would also be used for account recovery. For many
  services, proof of access to this identifier is crucial, and so
  an ID token is also desired to avoid an out-of-context verification.

- A _display name_ and _profile picture_ for the user, in order to personalize
  the service. Where it is possible for a user to have multiple accounts with
  the service, the display name and profile picture help the user to
  distinguish between these accounts.

The OpenYOLO _hint retrieval_ operation allows a service to request this
information from the credential provider. In response, the credential provider
is expected to present a choice of the user's commonly-used identifiers or
federated credentials, enabling a "single tap" account creation experience.
After selection, the provider might return a Credential object representing
the user's selection, optionally including a generated password or ID token
if applicable. A hint MUST NOT be returned automatically by a credential
provider - user interaction is strictly required before any personally
identifying information is returned.

Where a proof of access ID token is desired, a service MUST declare the
_token providers_ that is supports. Additionally, for each supported token
provider, a _client ID_ MAY be required. This is typically a value
generated by the token provider during registration as an OAuth2 client.
Finally, a _nonce_ can be provided that will be included in any generated
ID token, as a protection against replay attacks. Non-standard properties
specific to each token provider MAY be specified via an additional properties
map.

### Hint request message

A hint retrieval request is represented by the following protocol buffer
message:

```protobuf
message HintRetrieveRequest {
    ClientVersion client_version = 1;

    // at least one authMethod required
    repeated AuthenticationMethod auth_methods = 2;

    PasswordSpecification password_spec = 3;
    map<string, TokenRequestInfo> supported_token_providers = 4;
    map<string, bytes> additional_props = 5;
}

message TokenRequestInfo {
    string client_id = 1;
    string nonce = 2;
    map<string, bytes> additional_props = 3;
}
```

A simple hint request could then look like the following:

```json
{
  "auth_methods": [
    "openyolo://email",
    "https://accounts.google.com",
    "https://www.facebook.com"
  ]
}
```

This indicates that the service supports email and password based
authentication, Google Sign-in and Facebook Sign-in. The service has not
declared a password specification, therefore the OpenYOLO default specification
SHOULD be used by the credential provider if necessary. No supported token
providers have been specified, therefore no ID token is desired.

A more complex request, with a custom password specification and two supported
token provider could look like:

```json
{
  "auth_methods": [
    "openyolo://email"
  ],
  "password_spec": {
    "allowed": "0123456789",
    "min_size": 6,
    "max_size": 6
  },
  "supported_token_providers": {
    "https://accounts.google.com": {
      "client_id": "CLIENT.apps.googleusercontent.com",
      "nonce": "asdf123"
    },
    "https://auth.example.com": {
      "client_id": "11451",
      "nonce": "asdf123"
    }
  }
}
```

### Hint response message

A hint retrieval response is represented by the following protocol buffer
message:

```protobuf
message HintRetrieveResult {
  enum ResultCode {
    UNSPECIFIED = 0;
    BAD_REQUEST = 1;
    HINT_SELECTED = 2;
    NO_HINTS_AVAILABLE = 3;
    USER_REQUESTS_MANUAL_AUTH = 4;
    USER_CANCELED = 5;
  }

  // required
  ResultCode result_code = 1;

  Hint hint = 2;
  map<string, bytes> additional_props = 3;
}
```

The result codes are defined as follows:

- `UNSPECIFIED`: The generic catch-all for a request failure. This SHOULD NOT
  be used by providers, unless the other defined response codes do not apply.

- `BAD_REQUEST`: The request sent by the client was malformed or violated some
  security constraint enforced by the provider. This error should be treated
  as permanent; repeating the exact same request should result in the same
  error code response.

- `HINT_SELECTED`: The user selected a hint, which has been returned in the
  hint field of the message.

- `NO_HINTS_AVAILABLE`: No hints are available that match the constraints of the
  request.

- `USER_REQUESTS_MANUAL_AUTH`: The user canceled the selection of a hint in
  a manner that indicates they wish to proceed with authentication, but by
  manually entering their details. Providers SHOULD return this code
  if they display an option like "none of the above" or "use different account"
  and the user selects it.

- `USER_CANCELED`: The user canceled the selection of a hint in a manner that
  indicates they do not wish to authenticate at this time. Providers SHOULD
  return this code if:
  - The user presses the back button on their device
  - The user clicks outside the control area of a modal dialog
  - The user chooses some explicit option like "not now".

An email and password credential hint that could be returned for a requesting
app "com.example.app" could be:

```json
{
  "result_code": "HINT_SELECTED",
  "hint": {
    "id": "jblack@example.com",
    "auth_method": "openyolo://email",
    "display_name": "Jack Black",
    "display_picture_uri": "https://www.robohash.org/dcd65581?set=3",
    "generated_password": "YjW5Zvn3Fc7fY",
    "id_token":
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpX
        VCJ9.eyJzdWIiOiJqZG9lQGdtYWlsLmNv
        bSIsImF1ZCI6Imh0dHBzOi8vbG9naW4uZ
        XhhbXBsZS5jb20iLCJpc3MiOiJodHRwcz
        ovL2F1dGguZXhhbXBsZS5jb20iLCJuYW1
        lIjoiSmFuZSBEb2UifQ.CibuoaNMO-2pR
        QjWUbJMpMLWjKB34AMWCR4pIWD5tnE"
  }
}
```

Alternatively, a federated credential hint for Google Sign-in might look like:

```json
{
  "result_code": "HINT_SELECTED",
  "hint": {
    "id": "jdoe@gmail.com",
    "auth_method": "https://accounts.google.com",
    "display_name": "John Doe"
  }
}
```

### Example hint retrieval scenario

Jane Doe is visiting the travel site `https://adventures.example.com` for the
first time. Upon first page load, the site attempts to retrieve an existing
credential using OpenYOLO, but nothing is saved so it does not interrupt
Jane's flow further at this point.

After browsing a few travel packages, Jane notices a button with
label "save for later", and decides to press it. The service navigates to
an account creation screen, explaining that an account must be created to
save the package. At this point, the service sends a hint retrieval request,
and a hint selector dialog is presented:

```
+------------------------------------+
|                              +---+ |
| Continue With:               | X | |
|                              +---+ |
| +--------------------------------+ |
|                                    |
|  +---+ Jane Doe                    |
|  | O |                             |
|  |/_\| jdoe@gmail.com              |
|  +---+                             |
|        (with generated password)   |
|                                    |
| +--------------------------------+ |
|                                    |
|  +---+ John Doe                    |
|  | O |                             |
|  |/_\| john@example.com            |
|  +---+                             |
|        (with generated password)   |
|                                    |
| +--------------------------------+ |
|                                    |
|  +---+ Jill Doe                    |
|  | O |                             |
+--+---+-----------------------------+
```

Jane selects her most commonly used email address; a password is generated and
a credential returned to the service, and the provider is able to produce
an ID token for the selected email address.

The service utilizes the returned hint to bootstrap the new account, and after
successfully creating the account requests that the credential provider
save the credential. As the credential has not been modified by the site
from the details in the returned hint, it saves the credential automatically.

From Jane's perspective, this all happens from a single click on an account
in a presented dialog. She is now signed in, and the travel package she
selected is now saved to her account so she can return to it later.

## Credential retrieval

Where an existing credential is known for a service, it is often beneficial to
the service and the user for that credential to be retrieved and used for
authentication as early as possible. This allows the service to be appropriately
personalized to the user, such as providing shopping recommendations based on
past purchases. This SHOULD, of course, respect the user's preferences, as
there are many legitimate use cases where a user might wish to browse a service
in a signed-out state.

### Credential request message

A credential retrieval request is represented by the following protocol
buffer message:

```protobuf
message CredentialRetrieveRequest {
    ClientVersion client_version = 1;

    // at least one authMethod required
    repeated AuthenticationMethod auth_methods = 2;

    map<string, TokenRequestInfo> supported_token_providers = 3;
    bool require_user_mediation = 4;
    map<string, bytes> additional_props = 5;
}
```

The service lists the authentication methods that it supports, which are used
to filter the set of credentials that are stored by the credential provider.
Similar to hint requests, the service can also specify its supported token
providers - the return of a valid ID token can provide an additional signal
to the service that this login attempt is legitimate.

To prevent automatic sign-in loops, where a user signs out and is
inadvertently signed back in again automatically by a credential retrieve
request, the `require_user_mediation` flag can be set to true. If absent
from the request message, this is assumed to be false. When true, and
one or more credentials are available, the provider MUST require an explicit
credential selection from the user, even if only one option is available. This
then gives the user the opportunity to more clearly state their intent in an
account-switch scenario, by rejecting the presented credential and entering an
account creation or manual sign-in flow.

In response to a credential request, the credential provider can either:

- directly return a credential for automatic sign-in
- Show a credential picker to the user
- Return a failure result code if no matching credentials are available.

Automatically returning a credential is optional, and if it is a facility
provided by the credential provider, SHOULD be something that the user can
disable. A credential SHOULD NOT be returned by a provider unless it
believes that the credential is a valid, existing credential for the requesting
service.

An example credential retrieval request could look like:

```json
{
  "auth_methods": [
    "openyolo://phone",
    "https://www.facebook.com"
  ]
}
```

### Credential response message

The response to a credential request is represented by the following protocol
buffer message:

```protobuf
message CredentialRetrieveResult {
  enum ResultCode {
    UNSPECIFIED = 0;
    BAD_REQUEST = 1;
    CREDENTIAL_SELECTED = 2;
    NO_CREDENTIALS_AVAILABLE = 3;
    USER_REQUESTS_MANUAL_AUTH = 4;
    CANCEL_AUTH = 5;
  }

  // required
  ResultCode result_code = 1;

  Credential credential = 2;
  map<string, bytes> additional_props = 3;
}
```

The result codes are defined as follows:

- `UNSPECIFIED`: The generic catch-all for a request failure. This SHOULD NOT
  be used by providers, unless the other defined response codes do not apply.

- `BAD_REQUEST`: The request sent by the client was malformed or violated some
  security constraint enforced by the provider. This error should be treated
  as permanent; repeating the exact same request should result in the same
  error code response.

- `CREDENTIAL_SELECTED`: The user selected a hint, which has been returned in
  the hint field of the message.

- `NO_CREDENTIALS_AVAILABLE`: No credentials are available that match the
  constraints of the request.

- `USER_REQUESTS_MANUAL_AUTH`: The user canceled the selection of a hint in
  a manner that indicates they wish to proceed with authentication, but by
  manually entering their details. Providers SHOULD return this code
  if they display an option like "none of the above" or "use different account"
  and the user selects it.

- `USER_CANCELED`: The user canceled the selection of a hint in a manner that
  indicates they do not wish to authenticate at this time. Providers SHOULD
  return this code if:
  - The user presses the back button on their device
  - The user clicks outside the control area of a modal dialog
  - The user chooses some explicit option like "not now".


An example response could therefore look like:

```json
{
  "result_code": "CREDENTIAL_SELECTED",
  "credential": {
    "id": "jdoe",
    "auth_domain": "https://login.example.com",
    "auth_method": "https://www.facebook.com"
  }
}
```

Or, if the user was presented a list of credentials and did not select one:

```json
{
  "result_code": "USER_CANCELED"
}
```

### Example credential retrieval scenario

Jane has just bought a new phone and has just installed the "TechNews" app.
When she opens the app, it immediately sends a credential retrieval request
for email, Google and Facebook stored credentials. Jane frequently used
TechNews on her old phone and had saved his email address and password with
her credential provider. Her credential provider receives the request, and
automatically returns the saved credential to the TechNews app and displays
a notification that it has done so. The TechNews app uses the credential to
sign in, and shows Jane her personalized feed of news.

## Credential saving

Once a user has created an account or successfully signed in using an existing
account, it is beneficial to them for this credential to be saved to their
credential provider. This ensures that when the user changes device, or their
session is invalidated, re-authentication is simplified through the use
of the credential retrieval operation.

In the case where a service saves a credential that is already known, this is
still a useful signal to the credential provider that the saved data is
accurate. Where discrepancies are detected, such as a change in password, this
provides an opportunity to confirm and update the saved data. Credential
providers MAY allow automatic saving of credentials, but it is recommended
to seek explicit confirmation from the user where the credential data is
new or sensitive (i.e. contains a previously unseen identifier or password).

How this confirmation is solicited from the user is outside the scope of this
specification; the reference implementation uses the following confirmation
dialog style design:

```
+------------------------------------+
|                                    |
| Save your password for ExampleApp  |
|         to ExampleProvider?        |
|                                    |
|    +----+ +--------------------+   |
|    | OK | | Never for this app |   |
|    +----+ +--------------------+   |
|                                    |
+------------------------------------+
```

### Save request message

A save credential request is represented by the following protocol buffer
message:

```protobuf
message CredentialSaveRequest {
    ClientVersion client_version = 1;

    // required
    Credential credential = 2;

    map<string, bytes> additional_props = 3;
}
```

### Save response message

```protobuf
message CredentialSaveResult {

  enum ResultCode {
    UNSPECIFIED = 0;
    BAD_REQUEST = 1;
    SAVED = 2;
    PROVIDER_REFUSED = 3;
    USER_CANCELED = 4;
    USER_REFUSED = 5;
  }

  // required
  ResultCode result_code = 1;

  map<string, bytes> additional_props = 2;
}
```

The result codes are defined as follows:

- `UNSPECIFIED`: The generic catch-all for a request failure. This SHOULD NOT
  be used by providers, unless the other defined response codes do not apply.

- `BAD_REQUEST`: The request sent by the client was malformed or violated some
  security constraint enforced by the provider. This error should be treated
  as permanent; repeating the exact same request should result in the same
  error code response.

- `SAVED`: The credential was saved, or an equivalent credential was updated.

- `PROVIDER_REFUSED`: The provider refused to save the credential, due to
  some policy restriction. For example, a provider may refuse to update an
  existing credential if it is stored in a shared keychain. The client
  SHOULD NOT request to save this credential again.

- `USER_CANCELED`: The user dismissed the request to save the credential,
  by either pressing the back button, clicking outside the area of a modal
  dialog, or some other "soft" cancelation that is not an explicit refusal
  to delete the credential. The client MAY request to save this credential
  again at a later time.

- `USER_REFUSED`: The user refused the request to save this credential. The
  client SHOULD NOT request to save this credential again.

## Credential deletion

Stale credentials stored in a credential provider are a source of frustration
for users. Stale credentials are particularly common in browsers that rely on
heuristics to detect password changes and update saved credentials.

When a credential is stale, it only serves as a barrier to
authentication. In most cases, the user will be forced to perform a tedious account recovery process, and if they do not remember to manually delete the
stale credential, will likely be faced with the same issue again in the future.

In order to provide services a way to flag stale credentials to a provider, a
credential deletion operation is defined.
Credential providers SHOULD NOT allow automatic deletion of credentials, as
this would allow misbehaving services to delete valid credentials. Financial
institutions are notorious for these kinds of user-hostile policies, and might
attempt to delete valid credentials as a misguided way to "protect" the user.
As such, credential deletion SHOULD require explicit user confirmation.
Where this is done legitimately, such as after a retrieved credential is
discovered to be invalid or a user deletes their account, the request for
confirmation will not be surprising to the user.

### Delete request message

A credential deletion request is represented by the following protocol buffer
message:

```protobuf
message CredentialDeleteRequest {
    ClientVersion client_version = 1;

    // required
    Credential credential = 2;

    map<string, bytes> additional_props = 3;
}
```

### Delete response message

A credential deletion response is represented by the following protocol buffer
message:

```protobuf
message CredentialDeleteResult {
  enum ResultCode {
    UNSPECIFIED = 0;
    BAD_REQUEST = 1;
    DELETED = 2;
    NO_MATCHING_CREDENTIAL = 3;
    PROVIDER_REFUSED = 4;
    USER_CANCELED = 5;
    USER_REFUSED = 6;
  }

  // required
  ResultCode result_code = 1;

  map<string, bytes> additional_props = 2;
}
```

The result codes are defined as follows:

- `UNSPECIFIED`: The generic catch-all for a request failure. This SHOULD NOT
  be used by providers, unless the other defined response codes do not apply.

- `BAD_REQUEST`: The request sent by the client was malformed or violated some
  security constraint enforced by the provider. This error should be treated
  as permanent; repeating the exact same request should result in the same
  error code response.

- `DELETED`: The credential was deleted.

- `NO_MATCHING_CREDENTIAL`: The credential was not deleted, as there was no
  matching credential to delete.

- `PROVIDER_REFUSED`: The provider refused to delete the provided credential,
  due to some policy restriction it is enforcing. For example, a provider
  could refuse to delete a credential from a shared keychain. The client
  SHOULD NOT request to delete this credential again.

- `USER_CANCELED`: The user dismissed the request to delete the credential,
  by either pressing the back button, clicking outside the area of a modal
  dialog, or some other "soft" cancelation that is not an explicit refusal
  to delete the credential. The client MAY request to delete this credential
  again at a later time.

- `USER_REFUSED`: The user explicitly refused to delete the credential,
  by selecting a "do not delete" (or similarly phrased) option in the
  presented UI. The client SHOULD NOT request to delete this credential again.

# Android specifics

The OpenYOLO protocol on Android is designed to operate on any Android API 15+
device, including devices which do not have Google Play Services available.
OpenYOLO operation requests and responses are handled using two of the core
communication primitives on Android: broadcast messages and activity intents.
API 15+ is specifically REQUIRED in order to be able to "target" broadcast
messages to specific apps, using `Intent.setPackage`. See the
["Security considerations and best practices"][broadcast-security] section of
the [android broadcasts documentation][broadcasts] for more information.

Devices with Google Play Services already have a credential provider available,
in the form of Smart Lock for Passwords. In addition to this, the
user may have installed an additional credential manager. In such a situation
is it common for a user to have credentials split across these two providers;
as such, it is particularly important on Android to be able to query multiple
providers. To service this goal, this specification also defines the
Background Broadcast Query (BBQ) protocol, which is used to perform the initial
step of requesting credentials from installed providers.

Hint, save and delete requests are simpler, as there is no need to interact with
multiple credential providers. For these operations, an Intent is simply
constructed for a credential provider, with the request message carried
as a binary protocol buffer via an intent extra.

## Discovering installed providers

The set of installed credential providers on an Android device can be be
determined using the system
[PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager.html)
query interface. As OpenYOLO providers do not need to support all defined
operations in this spec, discovery is performed on a per-operation basis.

For example, to discover whether a provider exists that supports hint
retrieval, the following package manager query can be used:

```java
Intent hintIntent = new Intent("org.openyolo.hint");
hintIntent.addCategory("org.openyolo");

List<ResolveInfo> resolvedProviders =
    mApplicationContext.getPackageManager()
        .queryIntentActivities(hintIntent, 0);
```

Each OpenYOLO operation is mapped to an activity within the credential provider,
each of which declares an intent filter with the "org.openyolo" category,
and an operation-specific intent filter.

### Preferred credential providers on Android

In the future, Android or Google Play Services may provide a mechanism to
store a user's preferred credential provider. However, in the meantime, a
simple heuristic is specified that will determine the user's preferred
credential provider in most cases:

1. Enumerate all the credential providers installed on the device.
2. If there are no credential providers, or there are any _unknown providers_,
   then there is no preferred provider.
3. If there is exactly one installed known provider, this it is the preferred
   provider.
4. If there is more than one installed known provider, discount any providers
   that are pre-installed on the device. If there is only one remaining provider
   after discounting the pre-installed providers, this is the preferred
   provider.
5. Otherwise, there is no preferred provider.

Where there is no preferred provider, the user MUST be given the opportunity to
explicitly select the provider they wish to use for the current operation.
This minimizes the risk of "security surprise", where the user finds themselves
interacting with an unexpected credential provider.

The heuristic takes into account that pre-installed providers, such as Google's
Smart Lock for Passwords, are not providers the user has made a conscious
choice to use. Therefore, when an additional provider is manually installed, it
is more likely that the user's intent is to use that, rather than the
pre-installed providers.

## Retrieving Hints

Hint requests on Android are dispatched to the credential provider using
an [Intent][android-intent]. If a provider supports hint retrieval, it MUST
declare this on the manifest entry for its hint activity, using the following intent filter:

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

An example hint request could be created and dispatched as follows:

```java
HintRetrieveRequest request = HintRetrieveRequest.newBuilder()
    .addAuthenticationMethod("openyolo://email")
    .build();

Intent hintIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.hint")
    .setCategory("org.openyolo")
    .putExtra("org.openyolo.hint.request", request.toByteArray());

startActivityForResult(hintIntent, RC_HINT);
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
    .setResultCode(NO_HINTS_AVAILABLE)
    .build();
Intent hintResultData = new Intent()
    .putExtra(
        "org.openyolo.hint.result",
        result.toByteArray());

setResult(result.getResultCode(), hintResultData);
```

## Retrieving credentials

OpenYOLO specifies two methods for credential retrieval; one is structurally
very similar to hint requests, and another which allows for credential
requests to be sent to multiple providers in parallel. The parallel request
mechanism is built on top of the "direct request" method, so the direct
request method will be specified first.

Direct credential retrieve requests on Android are dispatched to the credential
provider using an [Intent][android-intent]. If a provider supports credential
retrieval, it MUST declare this on the manifest entry for its retrieve activity,
using the following intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.retrieve"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

### Dispatching a direct retrieve request

In order to make a credential request, the client creates a credential request
message (specified in [SECTION](#credential-request-message)) and encodes it to
its binary protocol buffer form. An activity Intent is then created to send
this to the credential provider. The credential request message MUST be added
to the activity Intent using an extra, named "org.openyolo.credential.request".
This intent is then dispatched by the client using
[startActivityForResult][android-start-activity-for-result].

An example credential request can be created and dispatched as follows:

```java
CredentialRetrieveRequest request =
    CredentialRetrieveRequest.newBuilder()
        .addAuthenticationMethod("openyolo://email")
        .build();

byte[] credentialRequestBytes = request.toByteArray();

Intent hintIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.credential.retrieve")
    .setCategory("org.openyolo")
    .putExtra(
        "org.openyolo.credential.retrieve.request",
        request.toByteArray());

startActivityForResult(hintIntent, RC_RETRIEVE);
```

### Returning a response

The provider can perform any processing and user interaction required to
release a credential. Once complete, the provider creates a retrieve response
message (specified in [SECTION](#credential-response-message)), and passes this
back to the requester via [setResult][android-set-result]. The intent data
returned to the client MUST carry the retrieve result using an extra, named
"org.openyolo.credential.retrieve.result". Additionally, the result code
contained in that credential result MUST match the result code for the
provider activity.

An example credential result could therefore be created and returned with the
following code:

```java
Credential credential = Credential.newBuilder()
    .setId("jdoe@example.com")
    .setAuthDomain("android://sha256-aF...@com.example.app")
    .setAuthMethod("openyolo://email")
    .setPassword("CorrectH0rseBatterySt4ple")
    .build();

CredentialRetrieveResult result =
    CredentialRetrieveResult.newBuilder()
        .setResultCode(CREDENTIAL_SELECTED)
        .setCredential(credential)
        .build();

Intent retrieveResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.retrieve.result",
        result.toByteArray());

setResult(result.getResultCode(), retrieveResultData);
finish();
```

### Parallel credential retrieval

Credential retrieve requests can be sent to multiple providers in parallel,
using the Background Broadcast Query protocol (see [SECTION](#the-background-broadcast-query-protocol-bbq)) designed for this purpose.
If a provider supports direct credential retrieval, it MUST also support
parallel credential retrieval as specified in this section.

Parallel credential retrieval is particularly useful where more than one
provider is installed and actively used by the user on their device. This often
occurs where there is no easy integration for third party password managers
into system services, such as mobile browsers, which do not have a plugin
mechanism. In this scenario, there can be a disjoint disjoint set of
credentials stored in the various providers, so querying them all increases the
probability that a usable credential can be found.

The query data type used for credential requests is "org.openyolo.credential",
with a credential request message (specified in
[SECTION](#credential-request-message)) as the query data. Providers respond to the BBQ query with the following protocol buffer response message:

```protobuf
message CredentialRetrieveBbqResponse {
    bytes retrieve_intent = 1;
    map<string, bytes> additional_props = 2;
}
```

This response MAY carry an intent that can be used to retrieve a
credential from a provider. Providers do not return an intent if they know that
they do not have a credential matching the request. Providers MAY respond
with a retrieve intent even if they do not know that they have a credential
available: providers which use a master password to encrypt their stores which
is not stored to disk may require the user to take an action to unlock the store
before an accurate answer can be determined.

Where multiple providers respond with an intent, the client SHOULD allow
the user to choose which of these providers to proceed with. Once selected,
the intent is dispatched to the provider using
[startActivityForResult][android-start-activity-for-result].

The intent returned via the BBQ response MUST be structurally equivalent
to the intents that a client would construct for direct credential
retrieval, and the activity it is directed to MUST also follow the same
protocol to return results.The provider MAY include additional information in
the retrieve intent returned via BBQ, if convenient.

As the intent returned via BBQ is visible to, and can potentially be modified
by the requesting service, it MUST NOT be blindly trusted by the provider
when used by the requester. Additionally, intents returned via the BBQ
protocol MUST NOT contain any privacy or security sensitive information, such
as pre-fetched credentials. Providers SHOULD implement tamper-detection for the
intent, such that any modification of the data carried by the intent is
rejected.

## Saving credentials

Credential save requests on Android are dispatched to the credential provider
using an [Intent][android-intent]. If a provider supports credential saving,
it MUST declare this on the manifest entry for its retrieve activity,
using the following intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.save"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

### Dispatching a save request

In order to make a save request, the client creates a save request message
(specified in [SECTION](#save-request-message)) and encodes it to its binary
protocol buffer form. An activity Intent is then created to send this to the
credential provider. The save request message _must_ be added to the activity
Intent using an extra, named "org.openyolo.credential.save.request".
This intent is dispatched by the client using
[startActivityForResult][android-start-activity-for-result].

An example save request could be created and dispatched as follows:

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
startActivityForResult(saveIntent, RC_SAVE);
```

### Returning a response

At this point the
provider can perform any processing and user interaction required to save
the credential. Once complete, the provider creates a save response message
(specified in [SECTION](#save-response-message)), and passes this back to the
requester via [setResult][android-set-result]. The intent data returned to the
client MUST carry the save result using an extra, named
"org.openyolo.credential.save.result". Additionally, the result code contained
in that save result MUST match the result code for the provider activity.

An example save result could therefore be sent with the following code:

```java
CredentialSaveResult result = CredentialSaveResult.newBuilder()
    .setResultCode(SAVED)
    .build();

Intent saveResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.save.result",
        result.toByteArray());

setResult(result.getResultCode(), saveResultData);
```

## Deleting credentials

Credential delete requests on Android are dispatched to the credential provider
using an [Intent][android-intent]. If a provider supports credential deletion,
it MUST declare this on the manifest entry for its deletion activity,
using the following intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.credential.delete"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

In order to make a delete request, the client creates a delete request message
(specified in [SECTION](#delete-request-message)) and encodes it to its binary
protocol buffer form. An activity Intent is then created to send this to the
credential provider. The delete request message MUST be added to the activity
Intent using an extra, named "org.openyolo.credential.delete.request".

An example delete request could be created and dispatched as follows:

```java
CredentialDeleteRequest request =
    CredentialDeleteRequest.newBuilder()
        .setCredential(
            Credential.newBuilder()
                .setId("jdoe@example.com")
                .setAuthenticationDomain(/*...*/)
                .setAuthenticationMethod(/*...*/)
                .setPassword("wrongPassword")
                .build())
        .build();

Intent deleteIntent = new Intent()
    .setPackage("com.example.provider");
    .setAction("org.openyolo.credential.delete")
    .setCategory("org.openyolo")
    .putExtra(
        "org.openyolo.credential.delete.request",
        request.toByteArray());

startActivityForResult(deleteIntent, RC_DELETE);
```

This intent is dispatched by the client using
[startActivityForResult][android-start-activity-for-result]. At this point the
provider can perform any processing and user interaction required to delete
the credential. The provider creates a delete response message (specified in
[SECTION](#delete-response-message)), and passes this back to the requester via
[setResult][android-set-result]. The intent data returned to the
client MUST carry the delete result using an extra, named
"org.openyolo.credential.delete.result". Additionally, the result code
contained in that delete result MUST match the result code for the provider activity.

An example save result could therefore be sent with the following code:

```java
CredentialDeleteResult result = CredentialDeleteResult.newBuilder()
    .setResultCode(USER_REFUSED)
    .build();

Intent deleteResultData = new Intent()
    .putExtra(
        "org.openyolo.credential.delete.result",
        result.toByteArray());

setResult(result.getResultCode(), deleteResultData);
```

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
  string data_type = 1;

  // required
  string requesting_app = 2;

  // required
  sfixed64 request_id = 3;

  // required
  sfixed64 response_id = 4;

  bytes query_message = 5;
  map<string, bytes> additional_props = 6;
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
  sfixed64 request_id = 1;

  // required
  sfixed64 response_id = 2;

  bytes response_message = 3;
  map<string, bytes> additional_props = 4;
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

# Security on rooted devices

The overall security of OpenYOLO on Android is contingent on the security
of the core communication primitives the platform provides. Specifically,
it MUST be the case that intent results be private, and that targeted
broadcast messages MUST only be visible to the designated recipient. These
preconditions are also fundamental to Android security in general - if
intent results or targeted broadcast messages can be eavesdropped by attackers,
then no real security exists for inter-process communication.

The BBQ protocol specifically relies on the integrity of the Android broadcast
system  to guarantee the privacy of the messages sent between a requester and a
provider. On a device with a custom Android ROM, it is potentially possible for
a malicious app or system service with root access to read these messages, and
expose plain-text passwords.

Cryptography would provide no additional protection. If an attacker can read
the private messages sent via the broadcast system, this will typically imply
they have access to the memory location of the buffers. If ephemeral
public-private key pairs are used, which don't authenticate either party, a
man-in-the-middle attack is possible.

There is no trusted third party on the device which can sign keys to prove they
are associated to a particular app:

- Key pairs cannot be distributed with the app, as they could be easily
  extracted from the application in advance, or on-demand with
  root access on the device.

- Keys cannot be dynamically signed by a trusted entity on the device (such as
  the platform itself, or Google Play Services) as these exchanges
  would also be susceptible to attack by anything with root access.

As such, we recommend that credential providers warn the user if it can be
detected that they are executing on an untrusted Android build. The option could
be given to enable or disable credential exchange on such devices, with a
warning as to the security risks of doing this. Generally, rooted devices are
very risky to a user's security, so warning users of this fact prior to even
allowing a password manager to be configured on the device is also advisable,
as the following attacks are also potentially viable:

- Directly reading keys and passwords from the memory space of the password
  manager or app
- Scraping the contents of EditText instances for passwords
- Key-logging the user
- Injecting code into the process space of the password manager or app

The authors of this specification have no evidence that the kernel modifications
required to break this protocol exist on real devices or popular distributed
Android ROMs, but they are certainly feasible. As such, all rooted devices
SHOULD be treated with suspicion when dealing with credential data.

[Adams99]: https://doi.org/10.1145/322796.322806
[smart-lock]: https://developers.google.com/identity/smartlock-passwords/android/
[oauth2]: https://tools.ietf.org/html/rfc6749
[oidc]: http://openid.net/specs/openid-connect-core-1_0.html
[dashlane-account-survey]: https://blog.dashlane.com/infographic-online-overload-its-worse-than-you-thought/
[rfc2119]: https://tools.ietf.org/html/rfc2119
[rfc7519]: https://tools.ietf.org/html/rfc7519
[rfc7636]: https://tools.ietf.org/html/rfc7636
[Yan04]: https://doi.org/10.1109/MSP.2004.81
[email-market-share]: https://blog.mailchimp.com/major-email-provider-trends-in-2015-gmail-takes-a-really-big-lead/
[asset-links]: https://developers.google.com/digital-asset-links/
[cancel-result]: https://developer.android.com/reference/android/app/Activity.html#RESULT_CANCELED
[intent-results]: https://developer.android.com/training/basics/intents/result.html
[intent-overview]: https://developer.android.com/guide/components/intents-filters.html
[protobuf]: https://developers.google.com/protocol-buffers
[protobuf-json]: https://developers.google.com/protocol-buffers/docs/proto3#json
[signature-class]: https://developer.android.com/reference/android/content/pm/Signature.html
[android-intent]: https://developer.android.com/reference/android/content/Intent.html

[android-package-manager]: https://developer.android.com/reference/android/content/pm/PackageManager.html "android.content.pm.PackageManager"

[android-start-activity-for-result]: https://developer.android.com/reference/android/app/Activity.html#startActivityForResult%28android.content.Intent,%20int%29

[android-set-result]: https://developer.android.com/reference/android/app/Activity.html#setResult%28int,%20android.content.Intent%29

[broadcasts]: https://developer.android.com/guide/components/broadcasts.html

[broadcast-security]: https://developer.android.com/guide/components/broadcasts.html#security_considerations_and_best_practices

[reverse-domain]: https://en.wikipedia.org/wiki/Reverse_domain_name_notation
