# Security on rooted devices

The overall security of OpenYOLO on Android is contingent on the security
of the core communication primitives the platform provides. Specifically,
it _must_ be the case that intent results be private, and that targeted
broadcast messages must only be visible to the designated recipient. These
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
should be treated with suspicion when dealing with credential data.
