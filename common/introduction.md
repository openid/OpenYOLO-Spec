
# Problem: Manual authentication is mentally exhausting

Users are typically presented with a screen like the following when interacting
with services in an application or website:

{{artwork/auth-screen.md}}

The user typically has to answer three questions in response to such a page:

1. Do I already have an account for this service?
2. If so, did I use an email address and password, or one of the identity
   provider options?
3. If I used an email address and password, what was the password?

For all but most frequently used applications and websites (henceforth referred
to as _services_), this is a tedious and error-prone process. As of 2016,
users typically interact with around [100 services][dashlane-account-survey],
and many of those services are used less than once a month, for
example to buy flowers or arrange air travel. Long session durations can help,
but only when the user interacts with the service on a single device.
Purchasing a new device is a particularly painful experience due to the need to
re-authenticate with all used services.

Remembering account details for 100+ services is intractable; the natural human
consequence of this situation is widespread credential reuse across services.
This is a disaster for the user's security; a better solution is required.

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
more and more services. Yet, password authentication persists, because it is
considered to be easy to implement, has no dependencies on external
entities, and is familiar to users. It is unlikely that password based
authentication can be completely displaced; as such, any solution in this
problem space will have to fully accommodate password based authentication.

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

Furthermore, it is easy for users to forget _which_ identity provider they use,
when multiple options are presented. Services also rarely implement
_account linking_ correctly, where multiple authentication methods are linked
to the same core account. Because of this, making the wrong choice often
leads to a totally different account: for example, choosing Google Sign-in when
the user's account was actually created using Facebook. The inconsistency
and frustration caused by this is often enough to drive users to the
authentication method they know best: password authentication, with a reused
password across every service.

## Account recovery based authentication

An equally common method of authentication employed by users is to simply
trigger the _account recovery_ flow every time they need to use the service.
Accounts are typically created with a recovery email address or phone number,
and users exploit this fact to regain access to the account when necessary.
They expect the following flow:

1. An email or SMS message will be sent containing a link to reset the
   password.

2. The user changes the password, likely to either their current reused
   password, or something random that they immediately forget.

3. The user is now authenticated.

We shall refer to this method of authentication as "proof of access" -
by demonstrating that a secret can be retrieved from some communication
side-channel, the user can gain access to an account. Some services use
this method explicitly, as the main form of
authentication. [Slack](https://www.slack.com) calls this "magic link"
authentication.

Sending an authentication secret (a code or a link) to an email address or
phone number is essentially a form of federated authentication, and
the service that manages the email address is effectively the identity provider. In comparison to
OpenID Connect, this is a rather absurd and inconvenient form of authentication,
as it requires the user to manually drive the authentication flow.
It is, however, a model of authentication that users find easy to understand,
and see as privacy-preserving compared to social login.

If it were possible to provide proof of access to an email address
or phone number directly to a service, then the manual verification of access
to that email or phone number would be unnecessary. One may observe that the
most common email providers are _also_ OAuth2 or OpenID Connect identity
providers: Google, Microsoft and Yahoo account for over 90% of the US market,
according to a data analysis conducted by
[MailChimp in 2015][email-market-share]. These providers typically already have
the ability to assert proof of access in the form of
[ID tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).
Providing an easier mechanism to acquire such ID tokens would simplify
authentication for many services.

## Credential managers

A _credential manager_ is a piece of software that remembers credentials
on behalf of a user. Most credential managers focus primarily on
password based authentication, remembering the user's passwords and offering
to generate strong, unique password for each new service a user interacts with.

The most common credential manager that users encounter is their web browser,
which presents itself via form-fill on authentication pages. Technically
knowledgeable users often also use a standalone credential manager applications,
which integrate with browsers via extensions, or via input-method extensions.

Credential managers suffer from some serious usability issues:

- When a credential manager is a standalone application, the user must
  typically manually switch context to find the relevant credential, and
  copy-paste it to the service they are signing in to. Browser extensions
  and input-method extensions can make this easier, but are not supported
  on all platforms, in particular in mobile applications and browsers.

  Manually copying a password also represents a security risk in itself;
  on some platforms it is possible for other applications installed on the
  device to monitor the clipboard and steal passwords that are copied out of
  the credential manager.

- Where a credential is able to integrate with the browser or OS in some way,
  heuristics are often necessary to detect and fill in login forms. Such
  heuristics are fragile to changes in the service, such as when they are
  redesigned or change path within the domain. Heuristics are employed because
  there is rarely any viable alternative: services do not provide sufficient
  information for a credential manager to do a better job.

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

## Solution: Direct communication between services and credential managers

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
  section above) could be directly solicited. While the credential manager may
  not have the authority to generate an ID token for a given email address, it
  could facilitate this process.

OpenYOLO defines a protocol for this communication channel, a
_discovery mechanism_ for the user's credential managers, and a standard API
for the client to use the above operations.
