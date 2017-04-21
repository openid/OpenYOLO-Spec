# OpenYOLO on Android

The OpenYOLO protocol on Android is designed to run on any Android API 15+
device, including devices which do not have Google Play Services available.
OpenYOLO operation requests and responses are handled using core communication
primitives on Android: broadcast messages and activity intents.

Devices with Google Play Services already have a credential provider available,
in the form of Google's Smart Lock for Passwords. In addition to this, the
user may have installed an additional credential manager. In such a situation
is it common for a user to have credentials split across these two providers;
as such, it is particularly important on Android to be able to query multiple
providers. To service this goal, this specification also defines the
Background Broadcast Query (BBQ) protocol, which is used to perform the initial
step of requesting credentials from installed providers.

Hint and save requests are simpler, as there is no need to interact with
multiple credential providers. For these operations, an Intent is simply
constructed for a credential provider, with the hint or save request carried
as a binary protocol buffer via an intent extra. This does, however, leave the
problem of deciding _which_ credential provider these requests should be sent
to.

## Discovering installed providers

The set of installed credential providers on an Android device can be be
determined using the system
[PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager.html) query interface. OpenYOLO providers must define an activity for hint retrieval,
which must be listed in the provider app manifest with the following
intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.hint"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

Based on this, all installed credential providers can be located through
the following package manager query:

```java
Intent hintIntent = new Intent("org.openyolo.hint");
saveIntent.addCategory("org.openyolo");

List<ResolveInfo> resolvedProviders =
    mApplicationContext.getPackageManager()
        .queryIntentActivities(saveIntent, 0);
```

## Preferred credential providers on Android

In the future, Android or Google Play Services may directly store a user's
preferred credential provider. However, in the meantime, a simple heuristic
is specified that will determine the user's preferred credential provider
in most cases:

1. Enumerate all the credential providers installed on the device. If there
   are any _unknown providers_, then there is no preferred provider.
2. If there are no _known providers_, there is no preferred provider.
3. If there is exactly one installed provider, and it is known,
   this is the preferred provider.
4. If there are exactly two installed providers, both are known, and one of
   them is Google's Smart Lock for passwords, the preferred provider is the
   non-Google provider.
5. If there are three or more known providers, there is no preferred provider.

Where there is no preferred provider, the user must explicitly select the
provider they wish to use for each hint and credential storage operation.
This minimizes the risk of "security surprise", where the user finds themselves
interacting with an unexpected credential provider.

The heuristic takes into account that Google's Smart Lock for Passwords will
be installed by default on the vast majority of Android devices, and that most
users will not have make a conscious effort to use this credential provider.
When a second credential provider is manually installed, it is likely that the
user's intent is to user that provider rather than the "system default" of
Smart Lock for Passwords.
