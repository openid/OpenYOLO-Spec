<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="2.0"

               xmlns:date="http://exslt.org/dates-and-times"
                xmlns:ed="http://greenbytes.de/2002/rfcedit"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:myns="mailto:julian.reschke@greenbytes.de?subject=rcf2629.xslt"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:saxon-old="http://icl.com/saxon"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:x="http://purl.org/net/xml2rfc/ext"
                xmlns:xi="http://www.w3.org/2001/XInclude"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"

                exclude-result-prefixes="date ed exslt msxsl myns rdf saxon saxon-old svg x xi xhtml"
                >

  <xsl:import href="https://greenbytes.de/tech/webdav/rfc2629.xslt"/>

  <xsl:template match="front">
    <xsl:call-template name="check-no-text-content"/>
    <header>
      <div id="{$anchor-pref}title">
        <!-- main title -->
        <h1><xsl:apply-templates select="title"/></h1>
        <xsl:if test="/rfc/@docName">
          <xsl:variable name="docname" select="/rfc/@docName"/>
          <xsl:choose>
            <xsl:when test="$rfcno!=''">
              <xsl:call-template name="warning">
                <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' is ignored because an RFC number is specified as well.</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <div class="filename"><xsl:value-of select="$docname"/></div>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:variable name="docname-noext">
            <xsl:choose>
              <xsl:when test="contains($docname,'.')">
                <xsl:call-template name="warning">
                  <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' should contain the base name, not the filename (thus no file extension).</xsl:with-param>
                </xsl:call-template>
                <xsl:value-of select="substring-before($docname,'.')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$docname"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <!-- more name checks -->
          <xsl:variable name="offending" select="translate($docname,concat($lcase,$digits,'-.'),'')"/>
          <xsl:if test="$offending != ''">
            <xsl:call-template name="warning">
              <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' should not contain the character '<xsl:value-of select="substring($offending,1,1)"/>'.</xsl:with-param>
            </xsl:call-template>
          </xsl:if>

          <xsl:if test="contains($docname,'--')">
            <xsl:call-template name="warning">
              <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' should not contain the character sequence '--'.</xsl:with-param>
            </xsl:call-template>
          </xsl:if>

          <xsl:if test="not(starts-with($docname,'draft-'))">
            <xsl:call-template name="warning">
              <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' should start with 'draft-'.</xsl:with-param>
            </xsl:call-template>
          </xsl:if>

          <!-- sequence number -->
          <xsl:variable name="seq">
            <xsl:choose>
              <xsl:when test="substring($docname-noext,string-length($docname-noext) + 1 - string-length('-latest'))='-latest'">latest</xsl:when>
              <xsl:when test="substring($docname-noext,string-length($docname-noext) - 2, 1)='-'"><xsl:value-of select="substring($docname-noext,string-length($docname-noext)-1)"/></xsl:when>
              <xsl:otherwise/>
            </xsl:choose>
          </xsl:variable>

          <xsl:if test="$seq='' or ($seq!='latest' and translate($seq,$digits,'')!='')">
            <xsl:call-template name="warning">
              <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>' should end with a two-digit sequence number or 'latest'.</xsl:with-param>
            </xsl:call-template>
          </xsl:if>

          <xsl:if test="string-length($docname)-string-length($seq) > 50">
            <xsl:call-template name="warning">
              <xsl:with-param name="msg">The @docName attribute '<xsl:value-of select="$docname"/>', excluding sequence number, should have less than 50 characters.</xsl:with-param>
            </xsl:call-template>
          </xsl:if>

        </xsl:if>
      </div>

      <div class="authors">
        <xsl:for-each select="author">
          <xsl:variable name="initials">
            <xsl:call-template name="format-initials"/>
          </xsl:variable>
          <xsl:variable name="truncated-initials">
            <xsl:call-template name="truncate-initials">
              <xsl:with-param name="initials" select="$initials"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="org">
            <xsl:choose>
              <xsl:when test="organization/@abbrev"><xsl:value-of select="organization/@abbrev" /></xsl:when>
              <xsl:otherwise><xsl:value-of select="organization" /></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:if test="@surname">
            <div class="author">
              <div class="author-name">
                <xsl:value-of select="$truncated-initials"/>
                <xsl:if test="$truncated-initials!=''">
                  <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="@surname" />
                <xsl:if test="@asciiInitials!='' or @asciiSurname!=''">
                  <xsl:text> (</xsl:text>
                    <xsl:value-of select="@asciiInitials"/>
                    <xsl:if test="@asciiInitials!='' and @asciiSurname!=''"> </xsl:if>
                    <xsl:value-of select="@asciiSurname"/>
                  <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:if test="@role">
                  <xsl:choose>
                    <xsl:when test="@role='editor'">
                      <xsl:text>, Editor</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>, </xsl:text><xsl:value-of select="@role" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
              </div>
              <div class="org">
                <xsl:value-of select="$org"/>
                <xsl:if test="organization/@ascii">
                  <xsl:value-of select="concat(' (',organization/@ascii,')')"/>
                </xsl:if>
              </div>
            </div>
          </xsl:if>
        </xsl:for-each>
      </div>

            <xsl:if test="$xml2rfc-topblock!='no'">
        <!-- insert the collected information -->
        <dl id="identifiers">
          <div>
            <dt>Stream</dt>
            <dd class="workgroup">
              <xsl:choose>
                <xsl:when test="/rfc/@number and $header-format='2010' and $submissionType='independent'">
                  <xsl:text>Independent Submission</xsl:text>
                </xsl:when>
                <xsl:when test="/rfc/@number and $header-format='2010' and $submissionType='IETF'">
                  <xsl:text>Internet Engineering Task Force (IETF)</xsl:text>
                </xsl:when>
                <xsl:when test="/rfc/@number and $header-format='2010' and $submissionType='IRTF'">
                  <xsl:text>Internet Research Task Force (IRTF)</xsl:text>
                </xsl:when>
                <xsl:when test="/rfc/@number and $header-format='2010' and $submissionType='IAB'">
                  <xsl:text>Internet Architecture Board (IAB)</xsl:text>
                </xsl:when>
                <xsl:when test="/rfc/front/workgroup and (not(/rfc/@number) or /rfc/@number='')">
                  <xsl:choose>
                    <xsl:when test="starts-with(/rfc/@docName,'draft-ietf-') and $submissionType='IETF'"/>
                    <xsl:when test="starts-with(/rfc/@docName,'draft-irft-') and $submissionType='IRTF'"/>
                    <xsl:otherwise>
                      <xsl:call-template name="info">
                        <xsl:with-param name="msg">The /rfc/front/workgroup should only be used for Working/Research Group drafts</xsl:with-param>
                      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:for-each select="/rfc/front/workgroup">
                    <xsl:variable name="v" select="normalize-space(.)"/>
                    <xsl:variable name="tmp" select="translate($v, $ucase, $lcase)"/>
                    <xsl:if test="contains($tmp,' research group') or contains($tmp,' working group')">
                      <xsl:call-template name="info">
                        <xsl:with-param name="msg">No need to include 'Working Group' or 'Research Group' postfix in /rfc/front/workgroup value '<xsl:value-of select="$v"/>'</xsl:with-param>
                      </xsl:call-template>
                    </xsl:if>
                    <xsl:variable name="h">
                      <!-- when a single name, append WG/RG postfix automatically -->
                      <xsl:choose>
                        <xsl:when test="not(contains($v, ' ')) and starts-with(/rfc/@docName,'draft-ietf-') and $submissionType='IETF'">
                          <xsl:value-of select="concat($v, ' Working Group')"/>
                        </xsl:when>
                        <xsl:when test="not(contains($v, ' ')) and starts-with(/rfc/@docName,'draft-irtf-') and $submissionType='IRTF'">
                          <xsl:value-of select="concat($v, ' Research Group')"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="$v"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="$h"/>
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:if test="starts-with(/rfc/@docName,'draft-ietf-') and not(/rfc/front/workgroup)">
                    <xsl:call-template name="info">
                      <xsl:with-param name="msg">WG submissions should include a /rfc/front/workgroup element</xsl:with-param>
                    </xsl:call-template>
                  </xsl:if>
                  <xsl:text>Network Working Group</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </dd>
          </div>

          <xsl:if test="/rfc/@number">
            <div>
              <dt>RFC</dt>
              <dd><xsl:value-of select="/rfc/@number"/></dd>
            </div>
          </xsl:if>

          <div>
            <dt>Category</dt>
            <dd><xsl:call-template name="get-category-long"/></dd>
          </div>

          <div>
            <dt>Published</dt>
            <dd>
              <xsl:value-of select="$xml2rfc-ext-pub-month"/>&#160;<xsl:value-of select="$xml2rfc-ext-pub-day"/>, <xsl:value-of select="$xml2rfc-ext-pub-year"/>
            </dd>
          </div>

          <xsl:if test="/rfc/@ipr and not(/rfc/@number)">
            <div>
              <dt>Expires</dt>
              <dd><xsl:call-template name="expirydate" /></dd>
            </div>
          </xsl:if>
        </dl>
      </xsl:if>

    </header>

    <xsl:apply-templates select="abstract" />

    <xsl:if test="$xml2rfc-toc='yes'">
      <xsl:apply-templates select="/" mode="toc" />
      <xsl:call-template name="insertTocAppendix" />
    </xsl:if>

    <!-- insert notice about update -->
    <xsl:if test="$published-as-rfc">
      <p class="{$css-publishedasrfc}">
        <b>Note:</b> a later version of this document has been published as <a href="{$published-as-rfc/@href}"><xsl:value-of select="$published-as-rfc/@title"/></a>.
      </p>
    </xsl:if>

    <!-- check for conforming ipr attribute -->
    <xsl:choose>
      <xsl:when test="not(/rfc/@ipr)">
        <xsl:if test="not(/rfc/@number) and $xml2rfc-private=''">
          <xsl:call-template name="error">
            <xsl:with-param name="msg">Either /rfc/@ipr or /rfc/@number is required</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="/rfc/@ipr = 'full2026'" />
      <xsl:when test="/rfc/@ipr = 'noDerivativeWorks'" />
      <xsl:when test="/rfc/@ipr = 'noDerivativeWorksNow'" />
      <xsl:when test="/rfc/@ipr = 'none'" />
      <xsl:when test="/rfc/@ipr = 'full3667'" />
      <xsl:when test="/rfc/@ipr = 'noModification3667'" />
      <xsl:when test="/rfc/@ipr = 'noDerivatives3667'" />
      <xsl:when test="/rfc/@ipr = 'full3978'" />
      <xsl:when test="/rfc/@ipr = 'noModification3978'" />
      <xsl:when test="/rfc/@ipr = 'noDerivatives3978'" />
      <xsl:when test="/rfc/@ipr = 'trust200811'" />
      <xsl:when test="/rfc/@ipr = 'noModificationTrust200811'" />
      <xsl:when test="/rfc/@ipr = 'noDerivativesTrust200811'" />
      <xsl:when test="/rfc/@ipr = 'trust200902'" />
      <xsl:when test="/rfc/@ipr = 'noModificationTrust200902'" />
      <xsl:when test="/rfc/@ipr = 'noDerivativesTrust200902'" />
      <xsl:when test="/rfc/@ipr = 'pre5378Trust200902'" />
      <xsl:otherwise>
        <xsl:call-template name="error">
          <xsl:with-param name="msg" select="concat('Unknown value for /rfc/@ipr: ', /rfc/@ipr)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:call-template name="insert-errata">
      <xsl:with-param name="section" select="'boilerplate'"/>
    </xsl:call-template>

    <xsl:if test="not($abstract-first)">
      <xsl:if test="$xml2rfc-private=''">
        <xsl:call-template name="emit-ietf-preamble">
          <xsl:with-param name="notes" select="$notes-in-boilerplate|$edited-notes-in-boilerplate"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>

    <xsl:if test="$notes-follow-abstract">
      <xsl:apply-templates select="$notes-not-in-boilerplate|$edited-notes-not-in-boilerplate" />
    </xsl:if>

    <xsl:if test="$abstract-first">
      <xsl:if test="$xml2rfc-private=''">
        <xsl:call-template name="emit-ietf-preamble">
          <xsl:with-param name="notes" select="$notes-in-boilerplate|$edited-notes-in-boilerplate"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>

    <xsl:if test="not($notes-follow-abstract)">
      <xsl:apply-templates select="$notes-not-in-boilerplate|$edited-notes-not-in-boilerplate" />
    </xsl:if>

  </xsl:template>

  <xsl:param name="xml2rfc-ext-styles">ff-noto fft-sans-serif ffb-sans-serif</xsl:param>

  <!--
  OpenID color scheme:

  Orange: #f38019
  Light Gray: #aeafb3
  Gray: #7c7d80
  Dark Gray: #5a5a5a

  Background: #fafafa
  -->

  <xsl:template name="insertCss">
    <link rel="shortcut icon" type="image/png" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAADnUExURf////r6+r+/v/f39/3nzrS0tP7+/rOzs/iTHvmnR+vr6/j4+LW1tebm5urq6tvb2/z8/Lm5uc7OztnZ2fDw8MHBweTk5P/59Li4uLe3t7y8vLa2tv39/b29vdDQ0PjkzL6+vsO+ucPDw8vLy+/v7+Dg4PiWI/q6bvmoSeLi4v7z5vHx8fn5+fvBfv7x4tfX1/v7++7u7ujo6NPT08XFxeXl5fzUpuPj497e3sLCwru7u/mcMfvlzfzmzvzNl//79tLS0tra2szMzOnp6c3Nzdzc3PDq5d3d3fmbL+Hh4eDSw8bGxtXV1TGsX/AAAAD6SURBVDjLY2CgAdDCL62nroFPWlxXjYMTnwIWDo5Br4DZFqSAWwCrJCOvgwK7PEgBP6uSDx+6tICjNDsQQBSAWKK8DIZCCHkxKZCgpJMNSAGfLIjDasIuCJfXB4koOcvAHMnlwmMlCVTDBpVXBUpLW7Ah+ULEEqSFnRsiz8UKZBshe5NbDmwLuzZEgTKQKYweDsymxqKsEL+wSQAV6GALKANGMKUClGfCF5IihBSwCQJVMOOLCyFsjkQGYG+K4YtNTaACHnc2PNENjh4FXgHc6cEcHFk83l44E4yMKyi42BU5OKzNcKQmRk85JnZFDzt7fEmS0U2c+lkZAOAoE2iFNzVGAAAAAElFTkSuQmCC"></link>
    <meta name="theme-color" content="#f38019" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style type="text/css">
    @import url('https://fonts.googleapis.com/css?family=Noto+Sans:r,b,i,bi');
    @import url('https://fonts.googleapis.com/css?family=Roboto+Mono:r,b,i,bi');

    body {
      background-color: #fafafa;
      color: #5a5a5a;
      font-family: 'Noto Sans', sans-serif;
      font-size: 12pt;
      margin: 1em;
      overflow-wrap: break-word;
    }

    body > * {
      max-width: 50em;
      margin: auto;
      overflow-x: hidden;
    }

    #identifiers {
      margin: 8pt 0;
    }

    #identifiers > div {
    }

    #identifiers dt {
      display: inline;
      float: none;
      font-style: italic;
      vertical-align: top;
    }

    #identifiers dt:after {
      content: ": ";
      vertical-align: top;
    }

    #identifiers dd {
      display: inline;
      margin: 0;
    }

    .authors {
      display: block;
      text-align: center;
      margin-top: 0.5em;
    }

    .authors .author {
      display: inline-block;
      margin-right: 1.5em;
    }

    .authors .org {
      font-style: italic;
    }

    a {
      text-decoration: none;
      color: #f38019
    }

    a.smpl {
      color: black;
    }

    a:hover {
      text-decoration: underline;
    }

    a:active {
      text-decoration: underline;
    }

    address {
      margin-top: 1em;
      margin-left: 2em;
      font-style: normal;
    }

    <xsl:if test="//x:blockquote|//blockquote">
    blockquote {
      border-style: solid;
      border-color: gray;
      border-width: 0 0 0 .25em;
      font-style: italic;
      margin: 2em auto;
      padding-left: 0.5em;
    }
    </xsl:if>

    samp, span.tt, code, pre {
      font-family: 'Roboto Mono', monospace;
    }

    <xsl:if test="//xhtml:p">
    br.p {
      line-height: 150%;
    }
    </xsl:if>

    cite {
      font-style: normal;
    }

    dl > dt {
      float: left;
      margin-right: 1em;
    }
    dl.nohang > dt {
      float: none;
    }
    dl > dd {
      margin-bottom: .5em;
    }
    dl.compact > dd {
      margin-bottom: .0em;
    }
    dl > dd > dl {
      margin-top: 0.5em;
    }
    ul.empty {<!-- spacing between two entries in definition lists -->
      list-style-type: none;
    }
    ul.empty li {
      margin-top: .5em;
    }
    dl p {
      margin-left: 0em;
    }
    dl.<xsl:value-of select="$css-reference"/> > dt {
      font-weight: bold;
    }

    h1 {
      color: #f38019;
      font-size: 150%;
      line-height: 18pt;
      font-weight: bold;
      text-align: center;
      margin-top: 8pt;
      margin-bottom: 0pt;
    }
    h2 {
      font-size: 130%;
      line-height: 21pt;
      page-break-after: avoid;
    }
    h2.np {
      page-break-before: always;
    }
    h3 {
      font-size: 120%;
      line-height: 15pt;
      page-break-after: avoid;
    }
    h4 {
      font-size: 110%;
      page-break-after: avoid;
    }
    h5, h6 {
      page-break-after: avoid;
    }
    h1 a, h2 a, h3 a, h4 a, h5 a, h6 a {
      color: black;
    }

    ol.la {
      list-style-type: lower-alpha;
    }
    ol.ua {
      list-style-type: upper-alpha;
    }
    ol p {
      margin-left: 0em;
    }
    <xsl:if test="//xhtml:q">
    q {
      font-style: italic;
    }
    </xsl:if>

    pre {
      font-size: 11pt;
      background-color: #E0E0E0;
      padding: .25em;
      page-break-inside: avoid;
      overflow-x: auto;
    }

    <xsl:if test="//artwork[@x:is-code-component='yes']"><!-- support "<CODE BEGINS>" and "<CODE ENDS>" markers-->
    pre.ccmarker {
      background-color: white;
      color: gray;
    }
    pre.ccmarker > span {
      font-size: small;
    }
    pre.cct {
      margin-bottom: -1em;
    }
    pre.ccb {
      margin-top: -1em;
    }
    </xsl:if>

    pre.text2 {
      border-style: dotted;
      border-width: 1px;
      background-color: #E0E0E0;
    }
    pre.inline {
      background-color: white;
      padding: 0em;
      page-break-inside: auto;
      <xsl:if test="$prettyprint-script!=''">
      border: none !important;
      </xsl:if>
    }
    pre.text {
      border-style: dotted;
      border-width: 1px;
      background-color: #fafafa;
    }
    pre.drawing {
      border-style: solid;
      border-width: 1px;
      background-color: #fafafa;
      padding: 2em;
    }

    <xsl:if test="//x:q">
    q {
      font-style: italic;
    }
    </xsl:if>

    <xsl:if test="//x:sup|sup">
    sup {
      font-size: 60%;
    }
    </xsl:if>

    <xsl:if test="sub">
    sub {
      font-size: 60%;
    }</xsl:if>

    <xsl:if test="//texttable|//table">
    table.<xsl:value-of select="$css-tt"/> {
      border-collapse: collapse;
      border-color: gray;
      border-spacing: 0;
      vertical-align: top;
    }
    table.<xsl:value-of select="$css-tt"/> th {
      border-color: gray;
      padding: 3px;
    }
    table.<xsl:value-of select="$css-tt"/> td {
      border-color: gray;
      padding: 3px;
    }
    table.all {
      border-style: solid;
      border-width: 2px;
    }
    table.full {
      border-style: solid;
      border-width: 2px;
    }
    table.<xsl:value-of select="$css-tt"/> td {
      vertical-align: top;
    }
    table.all td {
      border-style: solid;
      border-width: 1px;
    }
    table.full td {
      border-style: none solid;
      border-width: 1px;
    }
    table.<xsl:value-of select="$css-tt"/> th {
      vertical-align: top;
    }
    table.all th {
      border-style: solid;
      border-width: 1px;
    }
    table.full th {
      border-style: solid;
      border-width: 1px 1px 2px 1px;
    }
    table.headers th {
      border-style: none none solid none;
      border-width: 2px;
    }
    table.<xsl:value-of select="$css-tleft"/> {
      margin-right: auto;
    }
    table.<xsl:value-of select="$css-tright"/> {
      margin-left: auto;
    }
    table.<xsl:value-of select="$css-tcenter"/> {
      margin-left: auto;
      margin-right: auto;
    }
    caption {
      caption-side: bottom;
      font-weight: bold;
      font-size: 10pt;
      margin-top: .5em;
    }

    <xsl:if test="//table">
    tr p {
      margin-left: 0em;
    }
    tr pre {
      margin-left: 1em;
    }
    tr ol {
      margin-left: 1em;
    }
    tr ul {
      margin-left: 1em;
    }
    tr dl {
      margin-left: 1em;
    }
    </xsl:if>

    </xsl:if>

    table.<xsl:value-of select="$css-header"/> {
      border-spacing: 1px;
      width: 95%;
      font-size: 11pt;
      color: white;
    }
    td.top {
      vertical-align: top;
    }
    td.topnowrap {
      vertical-align: top;
      white-space: nowrap;
    }
    table.<xsl:value-of select="$css-header"/> td {
      background-color: #7c7d80;
      width: 50%;
      padding: 2px 8px;
    }

    <xsl:if test="/rfc/@obsoletes | /rfc/@updates">
    table.<xsl:value-of select="$css-header"/> a {
      color: white;
    }
    </xsl:if>

    ul.toc, ul.toc ul {
      list-style: none;
      padding-left: 0em;
    }

    ul.toc li {
      line-height: 150%;
      font-weight: bold;
      margin-left: 0em;
    }

    ul.toc li li {
      line-height: normal;
      font-weight: normal;
      font-size: 11pt;
      margin-left: 0em;
    }

    ul.toc a {
      color: #f38019;
    }

    li.excluded {
      font-size: 0pt;
    }
    ul p {
      margin-left: 0em;
    }
    .filename, h1, h2, h3, h4 {
      font-family: <xsl:value-of select="$xml2rfc-ext-ff-title"/>;
    }

    <xsl:if test="$has-index">
    ul.ind, ul.ind ul {
      list-style: none;
      padding-left: 0em;
      page-break-before: avoid;
    }
    ul.ind li {
      font-weight: bold;
      line-height: 200%;
      margin-left: 0em;
    }
    ul.ind li li {
      font-weight: normal;
      line-height: 150%;
      margin-left: 0em;
    }

    .avoidbreakinside {
      page-break-inside: avoid;
    }
    .avoidbreakafter {
      page-break-after: avoid;
    }
    </xsl:if>

    <xsl:if test="//*[@removeInRFC='true']">
    .rfcEditorRemove {
      font-style: italic;
    }
    </xsl:if>

    <xsl:if test="//x:bcp14|//bcp14">
    .bcp14 {
      font-style: normal;
      text-transform: lowercase;
      font-variant: small-caps;
    }
    </xsl:if>

    <xsl:if test="//x:blockquote|//blockquote">
    blockquote > * .bcp14 {
      font-style: italic;
    }</xsl:if>

    .comment {
      background-color: yellow;
    }

    <xsl:if test="$xml2rfc-editing='yes'">
    .editingmark {
      background-color: khaki;
    }
    </xsl:if>

    .center {
      text-align: center;
    }

    .<xsl:value-of select="$css-error"/> {
      color: red;
      font-style: italic;
      font-weight: bold;
    }
    .figure {
      font-weight: bold;
      text-align: center;
      font-size: 10pt;
    }
    .filename {
      color: #5a5a5a;
      font-size: 112%;
      font-weight: bold;
      line-height: 21pt;
      text-align: center;
      margin-top: 0.25em;
    }
    .fn {
      font-weight: bold;
    }
    .<xsl:value-of select="$css-left"/> {
      text-align: left;
    }
    .<xsl:value-of select="$css-right"/> {
      text-align: right;
    }
    .warning {
      font-size: 130%;
      background-color: yellow;
    }

    <xsl:if test="$xml2rfc-ext-paragraph-links='yes'">
    .self {
        color: #999999;
        margin-left: .3em;
        text-decoration: none;
        visibility: hidden;
        -webkit-user-select: none;<!-- not std CSS yet-->
        -moz-user-select: none;
        -ms-user-select: none;
    }
    .self:hover {
        text-decoration: none;
    }
    p:hover .self {
        visibility: visible;
    }
    </xsl:if>

    <xsl:if test="$has-edits">del {
      color: red;
      text-decoration: line-through;
    }
    .del {
      color: red;
      text-decoration: line-through;
    }
    ins {
      color: green;
      text-decoration: underline;
    }
    .ins {
      color: green;
      text-decoration: underline;
    }
    div.issuepointer {
      float: left;
    }
    </xsl:if>

    <xsl:if test="//ed:issue">
    table.openissue {
      background-color: khaki;
      border-width: thin;
      border-style: solid;
      border-color: black;
    }
    table.closedissue {
      background-color: white;
      border-width: thin;
      border-style: solid;
      border-color: gray;
      color: gray;
    }
    thead th {
      text-align: left;
    }
    .bg-issue {
      border: solid;
      border-width: 1px;
      font-size: 8pt;
    }
    .closed-issue {
      border: solid;
      border-width: thin;
      background-color: lime;
      font-size: smaller;
      font-weight: bold;
    }
    .open-issue {
      border: solid;
      border-width: thin;
      background-color: red;
      font-size: smaller;
      font-weight: bold;
    }
    .editor-issue {
      border: solid;
      border-width: thin;
      background-color: yellow;
      font-size: smaller;
      font-weight: bold;
    }
    </xsl:if>

    <xsl:if test="$xml2rfc-ext-refresh-from!=''">.refreshxmlerror {
      position: fixed;
      top: 1%;
      right: 1%;
      padding: 5px 5px;
      color: yellow;
      background: black;
    }
    .refreshbrowsererror {
      position: fixed;
      top: 1%;
      left: 1%;
      padding: 5px 5px;
      color: red;
      background: black;
    }
    </xsl:if>

    <xsl:if test="/rfc/x:feedback">
    .<xsl:value-of select="$css-feedback"/> {
      position: fixed;
      bottom: 1%;
      right: 1%;
      padding: 3px 5px;
      color: white;
      border-radius: 5px;
      background: #006400;
      border: 1px solid silver;
      -webkit-user-select: none;<!-- not std CSS yet-->
      -moz-user-select: none;
      -ms-user-select: none;
    }
    .<xsl:value-of select="$css-fbbutton"/> {
      margin-left: 1em;
      color: #303030;
      font-size: small;
      font-weight: normal;
      background: #d0d000;
      padding: 1px 4px;
      border: 1px solid silver;
      border-radius: 5px;
      -webkit-user-select: none;<!-- not std CSS yet-->
      -moz-user-select: none;
      -ms-user-select: none;
    }
    </xsl:if>

    <xsl:if test="$xml2rfc-ext-justification='always'">
    dd, li, p {
      text-align: justify;
    }
    </xsl:if>

    <xsl:if test="$xml2rfc-ext-insert-metadata='yes' and $rfcno!=''">
    .<xsl:value-of select="$css-docstatus"/> {
      border: 1px solid black;
      display: none;
      float: right;
      margin: 2em;
      padding: 1em;
      -webkit-user-select: none;<!-- not std CSS yet-->
      -moz-user-select: none;
      -ms-user-select: none;
    }
    </xsl:if>

    <xsl:if test="$errata-parsed">
    .<xsl:value-of select="$css-erratum"/> {
      border: 1px solid orangered;
      border-left: 0.75em solid orangered;
      float: right;
      padding: 0.5em;
      -webkit-user-select: none;<!-- not std CSS yet-->
      -moz-user-select: none;
      -ms-user-select: none;
    }
    </xsl:if>

    <xsl:if test="$published-as-rfc">
    .<xsl:value-of select="$css-publishedasrfc"/> {
      background-color: yellow;
      color: green;
      font-size: 14pt;
      text-align: center;
    }
    </xsl:if>

    @media screen {
      pre.text, pre.text2 {
        width: 69em;
      }
    }

    @media print {
      .<xsl:value-of select="$css-noprint"/> {
        display: none;
      }

      a {
        color: black;
        text-decoration: none;
      }

      table.<xsl:value-of select="$css-header"/> {
        width: 90%;
      }

      td.<xsl:value-of select="$css-header"/> {
        width: 50%;
        color: black;
        background-color: white;
        vertical-align: top;
        font-size: 110%;
      }

      ul.toc a:last-child::after {
        content: leader('.') target-counter(attr(href), page);
      }

      ul.ind li li a {<!-- links in the leaf nodes of the index should go to page numbers -->
        content: target-counter(attr(href), page);
      }

      pre {
        font-size: 10pt;
      }

      .print2col {
        column-count: 2;
        -moz-column-count: 2;<!-- for Firefox -->
        column-fill: auto;<!-- for PrinceXML -->
      }

    <xsl:if test="$xml2rfc-ext-justification='print'">
      dd, li, p {
        text-align: justify;
      }
    </xsl:if>
    }

    @page<xsl:if test="$xml2rfc-ext-duplex='yes'">:right</xsl:if> {
      @top-left {
          content: "<xsl:call-template name="get-header-left"/>";
      }
      @top-right {
          content: "<xsl:call-template name="get-header-right"/>";
      }
      @top-center {
          content: "<xsl:call-template name="get-header-center"/>";
      }
      @bottom-left {
          content: "<xsl:call-template name="get-author-summary"/>";
      }
      @bottom-center {
          content: "<xsl:call-template name="get-bottom-center"/>";
      }
      @bottom-right {
          content: "[Page " counter(page) "]";
      }
    }<xsl:if test="$xml2rfc-ext-duplex='yes'">
    @page:left {
      @top-left {
          content: "<xsl:call-template name="get-header-right"/>";
      }
      @top-right {
          content: "<xsl:call-template name="get-header-left"/>";
      }
      @top-center {
          content: "<xsl:call-template name="get-header-center"/>";
      }
      @bottom-left {
          content: "[Page " counter(page) "]";
      }
      @bottom-center {
          content: "<xsl:call-template name="get-bottom-center"/>";
      }
      @bottom-right {
          content: "<xsl:call-template name="get-author-summary"/>";
      }
    }
    </xsl:if>
    @page:first {
        @top-left {
          content: normal;
        }
        @top-right {
          content: normal;
        }
        @top-center {
          content: normal;
        }
    }

    @media only screen and (max-device-width: 480px) {
      p {
        text-align: justify;
        text-justify: distribute;
        -webkit-hyphens: auto;
      }

      pre {
        font-size: 9pt;
      }

      table.<xsl:value-of select="$css-header"/> {
        display: block;
        border-spacing: 1px;
        font-size: 11pt;
        color: white;
      }

      table.<xsl:value-of select="$css-header"/> tbody {
        display: flex;
        flex-direction: column;
      }

      table.<xsl:value-of select="$css-header"/> tr {
        display: run-in;
      }

      table.<xsl:value-of select="$css-header"/> td {
        display: block;
        background-color: #7c7d80;
        width: auto;
      }

      table.<xsl:value-of select="$css-header"/> td.left {
        order: 0;
      }

      table.<xsl:value-of select="$css-header"/> td.right {
        order: 1;
      }
    }
    </style>
  </xsl:template>
</xsl:transform>