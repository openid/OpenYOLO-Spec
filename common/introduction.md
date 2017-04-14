
# Why is authentication hard?

The following screen is a common sight when interacting with services in
an application or website:

{{artwork/auth-screen.md}}

A user typically has to answer three questions in response to such a page:

1. Have I already created an account for this service?
2. How did I sign in?
3. If I used a password, what was it?

Answering these questions for all but the most frequently used applications and
websites (henceforth referred to as _services_) is difficult. Users now
typically interact with around [100 apps or sites][dashlane-account-survey],
and many of those services are used less than once a month, for
example to buy flowers or arrange air travel.

Long session durations can help, but only when the user interacts with the
service on a single device. Purchasing a new device is a particularly painful
experience due to the need to re-authenticate with all used services. A more
general solution is required.

## Password authentication

Password based authentication, despite multiple attempts to displace it,
remains the most common form of authentication in use today. Password
authentication suffers from three key issues:

- Passwords are often _weak_. Most users do not know how to produce
  [high entropy passwords][Yan04]. The basic strategies
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

The problems that passwords cause can only get worse, as users interact with
more and more services.

## Federated authentication

Federated authentication, in the form of [OAuth2][oauth2] and
[OpenID Connect][oidc], solves the problem of account overload by centralizing
authentication for the user with a small number of trusted _identity providers_.
Furthermore, by providing proof of authentication to a service (referred to as
a _relying party_ in this context) in the form of short lived bearer tokens and
cryptographically signed [ID tokens][rfc7519], overall security is
significantly improved over password based authentication.

However, the success of federated authentication in the consumer space is still
limited - OAuth2 and OpenID Connect are regarded as difficult to implement,
and federated authentication was unnecessarily tainted by "social login" in the
early 2010s. Federated authentication was associated with unnecessary and
invasive sharing of personal information. This association has largely been
undone, but the perception of privacy invasion lingers. As a result, many users
still prefer to use password authentication over federated authentication -
they feel more in control of their personal information by explicitly entering
what they wish to share during account creation.

As such, in the short term federated authentication cannot be considered to be
the solution to the problems with password authentication. An alternative
solution that can work with the status quo is required.

## Credential managers

A _credential manager_ can mitigate the worst properties of passwords, by
removing the burden of memorization from the user. A credential manager can
generate strong, unique password for each service a user interacts with.
Credential managers can even take on the role of rotating passwords, so that
passwords become shorter lived.

The most common credential manager that users encounter is the form-fill
functionality provided by most web browsers. Technically knowledgeable users
often also use a standalone credential manager application, which stores their
passwords and other sensitive information in a strong cryptographic store.

Credential managers, as currently employed, still suffer from some serious
usability issues:

- When a credential manager is a standalone application, the user must
  typically switch to the password manager, find the relevant credential, and
  copy it manually into the service they are signing in to. This is easier
  with desktop browsers, where a browser plugin can allow a credential manager
  to automatically fill the password, or display it in a more convenient
  location for the user to copy. However, not all browsers support plugins, and
  in particular mobile Safari and Chrome do not allow them.

  Manually copying a password also represents a security risk in itself; it is
  possible for other applications installed on the device to monitor the
  clipboard and steal passwords that are copied out of the credential manager.

- Heuristics are necessary to detect and fill in login forms. Such heuristics
  are fragile to changes in the service, such as when they are redesigned or
  change path within the domain. Heuristics are employed because there is
  rarely any viable alternative: services do not provide sufficient information
  for a credential manager to do a better job.

  This problem is particularly acute when the login system employs an
  _identifier first_ pattern, where collection of the identifier and a password
  are split across multiple stages. In such situations, heuristics typically
  fail to detect the relationship between the disparate forms.

- Credential managers are blind to relationships between apps and sites that
  share the same authentication system - saving a credential for one site does
  not automatically make this credential available on other, related sites.

- Credential managers are unaware of _federated authentication_: they cannot
  help the user remember if they signed in to the service using Google or
  Facebook, only whether they filled in an identifier and password.

- Credential managers are unaware of password restrictions in use on the site:
  how long they must be, whether they must include a number or symbol, etc. As
  such, _password generation_ is also heuristic and based on a least common
  denominator schema that is acceptable to the majority of services.

Finally, many users are just simply unaware of what a credential manager is,
where to get one, or how to use them, which has limited the impact of
credential managers significantly.

## Account recovery based authentication

Without a credential manager, when users are faced with a login page for an
infrequently used service, many simply resort to _account recovery_ as their
primary method of authentication. The account is initially created with an
email address or phone number that the user has access to. When authentication
is next required, the user just selects the "I forgot my password" option, and
expects the following flow:

1. An email will be sent containing a link to reset the password.

2. The user changes the password, likely to either their current reused
   password, or something random.

3. The user authenticates with the changed password.

In effect, all that is required is that they prove they have access to the
email address associated with their account. Knowing that this is possible,
many users won't even attempt to remember their passwords for these sites.

Some services even use this method explicitly as the main form of
authentication: [Slack](https://www.slack.com) calls this "magic link"
authentication, and sending authorization codes to a phone is essentially
the same.

When considered in isolation, this approach is a rather absurd, inconvenient
form of federated authentication. It is, however, easy for users to understand.
The service that manages the email address is effectively the identity provider,
and the "bearer token" is the email sent for account recovery.

One may also observe that the most common email providers are _also_ OAuth2 or
OpenID Connect identity providers: Google, Microsoft and Yahoo account for over
90% of the US market, according to a data analysis conducted by
[MailChimp in 2015][email-market-share].

If it were possible to provide "proof of access" to an email address directly
to a service, sending the email itself would be unnecessary. This is what
the proposed OpenID Fast Identity Verification flow does, by providing an
ID token for an asserted email address, if the user currently has access.

## Communication: the missing puzzle piece

One fundamental barrier to progress in improving both account security and
the authentication user experience is that services and credential managers
cannot talk to each other. If such a communication channel existed, then
the following operations would be possible:

- Account creation facilitated by the credential manager. The service could
  describe to the credential manager what authentication methods it supports,
  and what password restrictions it has. In response, a credential provider
  could (with or without user assistance) select an email address and generate
  a strong, unique password that is guaranteed to work.

- Retrieval of existing credentials. At the appropriate moment, a service could
  request a credential, and have this automatically returned, or returned
  after some in-context user consent is solicited. This would be a marked
  improvement over the user manually finding and copying the credential, and
  minimizes the opportunity for the credential to be stolen in doing so.

- Maintenance of the credential manager store. When the service modifies an
  account, it can notify the credential manager of account changes. This
  information can be used to keep the credential store fresh.

- "Proof of access" to email addresses and phone numbers could be directly
  solicited. While the credential manager may not have the authority to generate
  an ID token for a given email address, it could act as a conduit to acquiring
  such a token.

Defining a protocol for this communication channel is exactly what OpenYOLO
aims to achieve. Furthermore, a _default_ credential manager will be provided
by the OpenID Foundation, with a limited set of functionality that still
provides significant benefit to users who do not have a credential manager of
their own.
