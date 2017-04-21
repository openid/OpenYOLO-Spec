# Operations

OpenYOLO defines three core operations:

- _hint retrieval_: Provides basic account information to help create a new
  account.
- _credential retrieval_: Provides access to an existing stored credential for
  the requesting service.
- _credential storage_: Allows a service to store or update credentials in
  the credential provider in response to account creation or update events.

These are described in more detail in the following sections.

## Hint retrieval

When an service wants to create a new account for the user, they typically
need the following core pieces of information:

- The _authentication method_ that the user prefers to use, drawn from the
  set that the service supports. For instance, a service may allow a user
  to create an account with a phone number, Google Sign-in or Facebook
  Sign-in. If a non-federated authentication method is used, a
  _generated password_ that conforms to the service's password restrictions
  is desirable.

- A unique _identifier_ for the account, which is typically an email address,
  or phone number that would also be used for account recovery. For many
  services, proof of access to this identifier is crucial, and so
  a proof of access ID token is also desired.

- A _display name_ and _profile picture_ for the user, in order to personalize
  the service. Where it is possible for a user to have multiple accounts with
  the service, the

The OpenYOLO _hint retrieval_ operation allows a service to request this
information from the credential provider. In response, the credential provider
is expected to present a choice of the user's commonly-used identifiers or
federated credentials, enabling a "single tap" account creation experience.
After selection, the provider should return a Credential object representing
the user's selection, optionally including a generated password or ID token
if applicable. A hint _must not_ be returned automatically by a credential
provider - user interaction is strictly required before any personally
identifying information is returned.

The user interface specifics of how a credential provider presents this
choice to the user is out of the scope of this specification; the reference
implementation uses the following "hint selector" dialog design:

```
+------------------------------------+
|                              +---+ |
| Continue With:               | X | |
|                              +---+ |
| +--------------------------------+ |
|                                    |
|  +---+ John Doe                    |
|  | O |                             |
|  |/_\| jdoe@gmail.com              |
|  +---+                             |
|        (via Google Sign-in)        |
|                                    |
| +--------------------------------+ |
|                                    |
|  +---+ Jack Black                  |
|  | O |                             |
|  |/_\| jblack@example.com          |
|  +---+                             |
|        (with generated password)   |
|                                    |
| +--------------------------------+ |
|                                    |
|  +---+ Jane Doe                    |
|  | O |                             |
+--+---+-----------------------------+
```

A hint retrieval request is expressed formally by the following protocol buffer
message:

```protobuf
message HintRetrieveRequest {
  // at least one required
  repeated string authMethods = 1;

  PasswordSpecification passwordSpec = 3;
  map<string, bytes> additionalProps = 4;
}
```

This allows the service to express the authentication methods it supports,
and optionally provide the password specification to be used for password
generation. Lightweight extensibility is supported through the
additionalProps map, allowing the service to communicate non-standard
request properties that a user's credential provider may be able to utilize.
The semantics of such additional properties are outwith the scope of this
specification.

Consider the following hint retrieve request:

```json
{
  "authMethods": [
    "openyolo://email",
    "https://accounts.google.com",
    "https://www.facebook.com"
  ]
}
```

This indicates that the site supports email and password based authentication,
Google Sign-in and Facebook Sign-in. The service has not declared a
password specification, therefore the OpenYOLO default specification should
be used by the credential provider if necessary.

An email and password credential hint that may be returned for a requesting app "com.example.app" may look like:

```json
{
  "id": "jblack@example.com",
  "authDomain": "android://sha256-...@com.example.app",
  "authMethod": "openyolo://email",
  "displayName": "Jack Black",
  "displayPictureUri": "https://www.robohash.org/dcd65581?set=3",
  "password": "YjW5Zvn3Fc7fY"
}
```

Alternatively, a federated credential hint for Google Sign-in returned to
a requesting site `https://login.example.com` may look like:

```json
{
  "id": "jdoe@gmail.com",
  "authDomain": "android://sha256-...@com.example.app",
  "authMethod": "https://accounts.google.com",
  "displayName": "John Doe",
  "idToken": "..."
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
and a hint selector dialog is presented. Jane selects her most commonly used
email address; a password is generated and a credential returned to the service,
but the provider is not able to produce an ID token for the selected email
address.

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
past purchases. This should, of course, respect the user's preferences, as
there are many legitimate use cases where a user may wish to browse a service
in a signed-out state even when a saved credential is known.

A credential retrieval request is represented by the following protocol
buffer message:

```protobuf
message CredentialRetrieveRequest {
  // at least one required
  repeated string authMethods = 1;
  map<string, bytes> additionalProps = 2;
}
```

The service lists the authentication methods that it supports, which are used
to filter the set of credentials that are stored by the credential provider.
In response to this request, the credential provider can either:

- directly return a credential for automatic sign-in
- Show a credential picker to the user
- Return nothing if no matching credentials are available

Automatically returning a credential is optional, and if it is a facility
provided by the credential provider, _must_ be something that the user can
disable. A credential should only be returned by a provider if it believes that
the credential is a valid, existing credential for the requesting service.

Credential retrieval implementations _must not_ attempt to generate new
credentials during this flow - this is the responsibility of the hint retrieval
operation, and it is expected that the operations will be used at different
times by the service.

The user interface for selecting existing credentials is out of scope for this
specification; the reference implementation uses the following
"credential picker" design:

```
+------------------------------------+
|                              +---+ |
| Sign in to ExampleApp with:  | X | |
|                              +---+ |
| +--------------------------------+ |
|                                    |
|  +---+ John Doe                    |
|  | O |                             |
|  |/_\| jdoe@gmail.com              |
|  +---+                             |
|        (via Google Sign-in)        |
|                                    |
| +--------------------------------+ |
|                                    |
|  +---+ Jane Doe                    |
|  | O |                             |
|  |/_\| jdoe@example.com            |
|  +---+                             |
|        (with password)             |
|                                    |
| +--------------------------------+ |
|                                    |
|        None of the above           |
|                                    |
+------------------------------------+
```

An example credential retrieval request for the site `https://www.example.com`
could look like:

```json
{
  "authMethods": [
    "openyolo://phone",
    "https://www.facebook.com"
  ]
}
```

In response, a credential provider could automatically return a Facebook
credential like:

```json
{
  "id": "jdoe",
  "authMethod": "https://www.facebook.com"
}
```

### Example credential retrieval scenario

Jane Doe has just bought a new phone and has just installed the "TechNews" app.
When she opens the app, it immediately sends a credential retrieval request
for email, Google and Facebook stored credentials. Jane frequently used
TechNews on her old phone and had saved her email address and password with
her credential provider. Her credential provider receives the request, and
automatically returns the saved credential to the TechNews app and displays
a notification that it has done so. The TechNews app uses the credential to
sign in, and shows Jane her personalized feed of news.

## Credential storage

TODO
