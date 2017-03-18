
.PHONY: clean all

render: output/openyolo-spec-xml2rfcv2.xml output/openyolo-spec-xml2rfcv3.xml output/openyolo-spec.txt output/openyolo-spec.html

clean:
	rm -rf output

output:
	mkdir -p output

output/openyolo-spec-xml2rfcv2.xml: artwork/* android/* web/* *.md output
	mmark -xml2 -page root.md output/openyolo-spec-xml2rfcv2.xml

output/openyolo-spec-xml2rfcv3.xml: artwork/* android/* web/* *.md output
	mmark -xml -page root.md output/openyolo-spec-xml2rfcv3.xml

output/openyolo-spec.html: output/openyolo-spec-xml2rfcv3.xml
	java -cp saxon/saxon9he.jar net.sf.saxon.Transform xml2rfc-toc=yes -s:output/openyolo-spec-xml2rfcv3.xml -xsl:render.xslt -o:output/openyolo-spec.html

output/openyolo-spec.txt: output/openyolo-spec-xml2rfcv2.xml
	xml2rfc output/openyolo-spec-xml2rfcv2.xml --text output/openyolo-spec.txt
