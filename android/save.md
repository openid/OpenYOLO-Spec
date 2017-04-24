# Saving credentials

When a user successfully authenticates with an app, either manually or via
the OpenYOLO retrieve or assisted sign-up flows, this credential should be
saved for future use. Manually saving credentials to a provider is frustrating
and error-prone - the user must manually switch to the credential provider,
and follow the provider-specific flow to manually enter their credential again
for storage, with the possibility of typographical errors.

A significantly better user experience can be provided if the credential can
be saved in-context, just after it has been verified by an app. OpenYOLO
provides the mechanism to achieve this.

After a credential has been verified by an app, it should construct a
representation of the credential to be saved by a credential provider. This
can then be sent to be stored using the OpenYOLO aPI.

If a preferred credential provider can be determined by the OpenYOLO API, then
it will construct an intent to send the save request to the provider,
carrying the plain-text credential data in an intent extra. Similarly, if
only one credential provider is available on the device and it is a "known"
provider, the intent to directly interact with that provider will be
constructed. See [Protecting users](protecting-users.md) for details on
default and known providers.

If no preferred provider is found, an intent is constructed for a dialog that
will allow the user to choose a provider, after which an intent will be
dispatched to that provider containing the credential.

The flow for saving the credential past this point is under the control of
the provider, and not part of this specification. The outcome of the save
operation (success or failure) is communicated back to the app via a result
code to `onActivityResult`.

## Supporting save

In order to save a credential, the OpenYOLO client must first query the system
for the preferred credential provider, or any available providers which
support saving a credential. This involves a [Package Manager][pm-api] API
call to find activities with action `org.openyolo.save` and category
`org.openyolo`.

It is anticipated that some credential providers will only be able to store
id-and-password based credentials, while others may support federated
credentials. Such providers can be distinguished by requiring that providers
declare their supported set of authentication methods via an intent filter,
with a data URI filter based on the authentication method URI.

For a credential provider which only supports id-and-password based credentials,
this would look as follows:

```xml
<activity
    android:name="com.example.provider.SaveCredentialActivity"
    android:theme="@style/AppTheme.Dialog"
    android:exported="true"
    android:excludeFromRecents="true">
  <intent-filter>
    <action android:name="org.openyolo.save"/>
    <category android:name="org.openyolo" />
  </intent-filter>
</activity>
```

If a provider supports saving credentials for multiple authentication methods,
then multiple data filters can be specified. If the data filter is omitted,
this indicates the provider supports saving all credentials, regardless of
authentication type.

Given a credential object to be saved, the system can be queried to
find all password managers which support saving this credential:

```java
Intent saveIntent = new Intent("org.openyolo.save");
saveIntent.addCategory("org.openyolo");

// set the authentication type as a data parameter
saveIntent.setData(Uri.parse("openyolo://id-and-password"));

List<ResolveInfo> supportingProviders =
    getPackageManager().queryIntentActivities(saveIntent, 0);
```

This list should be presented to the user, in order to allow them to select
which provider they wish to save the credential to.

## Filtering the provider list

The list of credential providers returned by querying the package manager
may include unsafe options - it is important to further filter this list based
on the following criteria:

1. If the user has a preferred credential provider defined in the Google Play
   Services managed settings, and this credential provider
   is in the list, it should be used directly.

1. If the user has a whitelist of credential providers defined in the
   Google Play Services managed settings, the dialog presented to the user
   for save should be restricted to these options.

1. If Google Play Services is unavailable, all options should be displayed
   such that known providers are clearly distinguished from unknown providers.
   Selecting an unknown provider should require a second confirmation, to avoid
   the user accidentally interacting with an unknown provider by tapping on the
   wrong area of the screen.

[Protecting the user from malicious providers](protecting-users.md) provides
more information on how the Google Play Services settings and the known
providers list are defined.

## Behavior of the save intent

The behavior of the activity or activities that implement the save flow
is beyond the scope of this specification. However,. if a saved credential
matches an existing credential by identifier and authentication method, and
authentication domain, the credential provider should allow this to be
automatically saved where possible. This will allow apps to easily update
credentials in response to password change events.

To mitigate potential attempts to spoof a credential provider's UI, it is
also recommended that a method of pushing the request to a full screen version
of the provider is made available. This will allow security-conscious users
to determine that it is really the credential provider they are interacting
with, and not some attempt to phish their master password.

## Save response

The save response, returned to the app via `onActivityResult`, can be one of
two values:

1. `RESULT_OK`, if the credential is successfully saved.
2. `RESULT_CANCELLED`, if the credential was not saved for any reason. No
   further details need to be provided to the calling application, as the
   application is unlikely to be able to take any remedial action.

[pm-api]: https://developer.android.com/reference/android/content/pm/PackageManager.html "android.content.pm.PackageManager"
