
# Why is authentication a hard problem?

The following screen is a common sight when interacting with services in
an application or website:

{{artwork/auth-screen.md}}

A user typically has to answer three questions in response to such a page:

1. Have I already created an account for this service?
2. How did I sign in?
3. If I used a password, what was it?

Answering these questions for all but the most frequently used applications and
websites (henceforth referred to as _services_) is difficult. Users now
typically interact with around [100 apps or sites](@dashlane-account-survey),
and many of those services are used less than once a month, for
example to buy flowers or arrange air travel.

Long session durations can help, but only when the user interacts with the
service on a single device. Purchasing a new device is often a painful
experience due to the need to reauthenticate with all used services.

A _credential manager_ can help deal with account overload. The most common
credential manager that users encounter is the form-fill functionality provided
by most web browsers. However, such credential managers suffer from the
following issues:

- They employ heuristics to detect and fill in login forms. Such heuristics
  are fragile to changes in the page, such as when they are redesigned or
  change path within the domain.

- They are blind to relationships between apps and sites that share the same
  authentication system - saving a credential for one site does not
  automatically make this credential available on other, related sites.

- They are unaware of _federated authentication_: they cannot help the user
  remember if they signed in to the service using Google or Facebook, only
  whether they filled in an identifier and password.

- They are unaware of password restrictions in use on the site: how long they
  must be, whether they must include a number or symbol, etc. As such,
  _password generation_ is also heuristic and based on a least common
  denominator schema that is acceptable to the majority of services.

OpenYOLO addresses these issues by defining a protocol that allows services
to directly communicate with the user's credential manager, so that:

- Account creation can be facilitated by the credential manager, in a manner
  that is aware of the authentication methods supported by the service.

- Existing credentials can be retrieved automatically, or with in-context
  user consent if appropriate.

- The credential store can be automatically maintained in response to the user
  changing password, or deleting accounts.

- Both password based accounts and federated authentication are supported,
  while providing a migration path for services from password to bearer
  token based authentication.

## The problem with passwords

Federated authentication, in the form of [OAuth2](@RFC6749) and
[OpenID Connect](oidc), was intended to solve the problem of account overload
by centralizing authentication for the user with a trusted _identity provider_.
Furthermore, by providing proof of authentication to the
_relying party_ services in the form of cryptographically secure and
targeted bearer tokens and [ID tokens](@RFC7519), overall security was improved.

However, the success of federated authentication in the consumer space is still
limited - OAuth2 and OpenID Connect are regarded as difficult to implement,
and the fate of federated authentication was unnecessarily tainted by
"social login" in the early 2010s. The association of federated authentication
and unnecessary sharing of personal information has largely been undone, but
the perception of privacy invasion lingers. As a result, many users still
prefer to use password authentication over federated authentication.

The continued prevalence of password based authentication combined with
the number of accounts that users have invariably results in security disaster.
Best practice dictates that the user should have a unique password for each
service, and that those passwords be of high entropy -  this is simply
infeasible for humans. There are [are well known](@password-memorability)
limits to our ability to memorize and retain passwords. Without the aid of a
convenient and _omnipresent_ credential manager, easy to remember (and therefore
weak) passwords are used, and reused across multiple accounts.

## Account recovery as federated authentication

When forced to adopt better password hygiene, many users revel and simply
use _account recovery_ as their method of authentication - by proving they have
access to the email address associated to the account, they regain access to
the account. When they are next forced to re-authenticate, they repeat the
same behavior.

This approach is a rather absurd, inconvenient form of federated
authentication, though one that users understand. It is made
even more absurd by the fact that that the majority of internet users receive
email via Google, Microsoft or Yahoo, all of whom are identity providers.
