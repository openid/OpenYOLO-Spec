The OpenYOLO protocol is implemented on Web by opening a hidden iframe for
a credential manager, and establishing a message channel with it to exchange
protocol messages. Through this approach, no browser plugins are required, and
the credential provider can be displayed in-context simply by making the
hidden iframe visible.

Securing the OpenYOLO protocol on the web is significantly more difficult than
on Android, but the reward for doing so is ubiquity: OpenYOLO Web can be used
on virtually all platforms, and is a viable approach to authenticating on
iOS through the use of a SFSafariViewController.
