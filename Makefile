
.PHONY: clean all

# default target creates all variants of the spec
render-specs: render-android-spec render-web-spec render-consolidated-spec

render-android-spec: output/android/openyolo-android-spec.html output/android/openyolo-android-spec.txt

render-web-spec: output/web/openyolo-web-spec.html output/web/openyolo-web-spec.txt

render-consolidated-spec: output/consolidated/openyolo-spec.html output/consolidated/openyolo-spec.txt

# everything generated resides under output dir, so delete it to clean
clean:
	rm -rf output

# directory initialization

output:
	mkdir -p output

output/android: output
	mkdir -p output/android

output/web: output
	mkdir -p output/web

output/consolidated: output
	mkdir -p output/consolidated

#
# android spec targets
#
output/android/openyolo-android-spec-xml2rfcv2.xml: android/* artwork/* common/* output/android
	mmark -xml2 -page android/root.md output/android/openyolo-android-spec-xml2rfcv2.xml

output/android/openyolo-android-spec-xml2rfcv3.xml: android/* artwork/* common/* output/android
	mmark -xml -page android/root.md output/android/openyolo-android-spec-xml2rfcv3.xml

output/android/openyolo-android-spec.html: output/android/openyolo-android-spec-xml2rfcv3.xml output/android
	java -cp saxon/saxon9he.jar net.sf.saxon.Transform xml2rfc-toc=yes -s:output/android/openyolo-android-spec-xml2rfcv3.xml -xsl:render.xslt -o:output/android/openyolo-android-spec.html

output/android/openyolo-android-spec.txt: output/android/openyolo-android-spec-xml2rfcv2.xml output/android
	xml2rfc output/android/openyolo-android-spec-xml2rfcv2.xml --text output/android/openyolo-android-spec.txt

#
# web spec targets
#
output/web/openyolo-web-spec-xml2rfcv2.xml: web/* artwork/* common/* output/web
	mmark -xml2 -page web/root.md output/web/openyolo-web-spec-xml2rfcv2.xml

output/web/openyolo-web-spec-xml2rfcv3.xml: web/* artwork/* common/* output/web
	mmark -xml -page web/root.md output/web/openyolo-web-spec-xml2rfcv3.xml

output/web/openyolo-web-spec.html: output/web/openyolo-web-spec-xml2rfcv3.xml output/web
	java -cp saxon/saxon9he.jar net.sf.saxon.Transform xml2rfc-toc=yes -s:output/web/openyolo-web-spec-xml2rfcv3.xml -xsl:render.xslt -o:output/web/openyolo-web-spec.html

output/web/openyolo-web-spec.txt: output/web/openyolo-web-spec-xml2rfcv2.xml output/web
	xml2rfc output/web/openyolo-web-spec-xml2rfcv2.xml --text output/web/openyolo-web-spec.txt

#
# consolidated spec targets
#
output/consolidated/openyolo-spec-xml2rfcv2.xml: consolidated/* artwork/* common/* output/consolidated
	mmark -xml2 -page consolidated/root.md output/consolidated/openyolo-spec-xml2rfcv2.xml

output/consolidated/openyolo-spec-xml2rfcv3.xml: consolidated/* artwork/* common/* output/consolidated
	mmark -xml -page consolidated/root.md output/consolidated/openyolo-spec-xml2rfcv3.xml

output/consolidated/openyolo-spec.html: output/consolidated/openyolo-spec-xml2rfcv3.xml output/consolidated
	java -cp saxon/saxon9he.jar net.sf.saxon.Transform xml2rfc-toc=yes -s:output/consolidated/openyolo-spec-xml2rfcv3.xml -xsl:render.xslt -o:output/consolidated/openyolo-spec.html

output/consolidated/openyolo-spec.txt: output/consolidated/openyolo-spec-xml2rfcv2.xml output/consolidated
	xml2rfc output/consolidated/openyolo-spec-xml2rfcv2.xml --text output/consolidated/openyolo-spec.txt
