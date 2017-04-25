# Android specifics

The OpenYOLO protocol on Android is designed to operate on any Android API 15+
device, including devices which do not have Google Play Services available.
OpenYOLO operation requests and responses are handled using two of the core
communication primitives on Android: broadcast messages and activity intents.

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
[PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager.html) query interface. For an OpenYOLO provider to be able to provide hints, for
instance, it must define an activity for hint retrieval. This activity is
listed in the provider's manifest, with an OpenYOLO intent filter:

```xml
<intent-filter>
    <action android:name="org.openyolo.hint"/>
    <category android:name="org.openyolo" />
</intent-filter>
```

The client library within a service can then discover all hint providers on the
device via the following package manager query:

```java
Intent hintIntent = new Intent("org.openyolo.hint");
saveIntent.addCategory("org.openyolo");

List<ResolveInfo> resolvedProviders =
    mApplicationContext.getPackageManager()
        .queryIntentActivities(saveIntent, 0);
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

Where there is no preferred provider, the user must explicitly select the
provider they wish to use for each hint and credential storage operation.
This minimizes the risk of "security surprise", where the user finds themselves
interacting with an unexpected credential provider.

The heuristic takes into account that pre-installed providers, such as Google's
Smart Lock for Passwords, are not providers the user has made a conscious
choice to use. Therefore, when an additional provider is manually installed, it
is more likely that the user's intent is to use that, rather than the
pre-installed providers.
