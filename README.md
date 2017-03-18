# OpenYOLO Specification

This repository contains the draft OpenYOLO Specification, which standardizes
the protocol and platform specifics of direct communication between _services_
(apps and sites) and _credential providers_.

This specification is currently a _draft_ and _rapidly changing_ - please do not
rely upon any aspect of it for your own services. If you wish to ask questions
about the specification or collaborate on its definition, please join the
[Account Chooser and OpenYOLO Working Group](http://openid.net/wg/ac/) and
post to its
[mailing list](http://groups.google.com/group/oidf-account-chooser-list).

## Contributions

All contributors to this specification must sign the
[OpenID Intellectual Property and Contribution Agreements](http://openid.net/intellectual-property/). Spec changes should typically
be discussed on the [Account Chooser and OpenYOLO](http://openid.net/wg/ac/)
working group before specification change pull requests are produced.

## Producing a finalized document

The following tools are required:

- [mmark](https://github.com/miekg/mmark), which translates the Markdown
  source to XML2RFC v2 and v3 XML.

- [xml2rfc v2](https://xml2rfc.tools.ietf.org/), which produces the standard
  RFC ASCII text output.

- A [Java runtime](https://java.com/download), and
  [Saxon 9 HE](https://sourceforge.net/projects/saxon/files/Saxon-HE/), which
  produces the HTML output version of the document.

Once installed, the `render.sh` script can be run to produce plain text (RFC
style) and HTML outputs.

### Installing mmark

On Mac OS, mmark can be installed using homebrew: `brew install mmark`.
Otherwise, on all platforms the tool can be built
[from source](https://github.com/miekg/mmark#usage).

### Installing xml2rfc v2

On all platforms, xml2rfc can be installed using
[pip](https://pypi.python.org/pypi/xml2rfc): `pip install xml2rfc`.

### Installing Saxon

Download [Saxon 9 HE](https://sourceforge.net/projects/saxon/files/Saxon-HE/),
and unzip the files into a "saxon" subfolder of your checkout (this is ignored
by git). In particular, `saxon/saxon9he.jar` must exist.
