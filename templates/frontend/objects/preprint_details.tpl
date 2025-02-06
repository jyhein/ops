{**
 * templates/frontend/objects/preprint_details.tpl
 *
 * Copyright (c) 2014-2021 Simon Fraser University
 * Copyright (c) 2003-2021 John Willinsky
 * Distributed under the GNU GPL v3. For full terms see the file docs/COPYING.
 *
 * @brief View of an Preprint which displays all details about the preprint.
 *  Expected to be primary object on the page.
 *
 * Many servers will want to add custom data to this object, either through
 * plugins which attach to hooks on the page or by editing the template
 * themselves. In order to facilitate this, a flexible layout markup pattern has
 * been implemented. If followed, plugins and other content can provide markup
 * in a way that will render consistently with other items on the page. This
 * pattern is used in the .main_entry column and the .entry_details column. It
 * consists of the following:
 *
 * <!-- Wrapper class which provides proper spacing between components -->
 * <div class="item">
 *     <!-- Title/value combination -->
 *     <div class="label">Abstract</div>
 *     <div class="value">Value</div>
 * </div>
 *
 * All styling should be applied by class name, so that titles may use heading
 * elements (eg, <h3>) or any element required.
 *
 * <!-- Example: component with multiple title/value combinations -->
 * <div class="item">
 *     <div class="sub_item">
 *         <div class="label">DOI</div>
 *         <div class="value">12345678</div>
 *     </div>
 *     <div class="sub_item">
 *         <div class="label">Published Date</div>
 *         <div class="value">2015-01-01</div>
 *     </div>
 * </div>
 *
 * <!-- Example: component with no title -->
 * <div class="item">
 *     <div class="value">Whatever you'd like</div>
 * </div>
 *
 * Core components are produced manually below, but can also be added via
 * plugins using the hooks provided:
 *
 * @hook Templates::Preprint::Main []
 * @hook Templates::Preprint::Details::Reference [[parsedCitation]]
 * @hook Templates::Preprint::Details []
 *
 * @uses $preprint Preprint This preprint
 * @uses $publication Publication The publication being displayed
 * @uses $firstPublication Publication The first published version of this preprint
 * @uses $currentPublication Publication The most recently published version of this preprint
 * @uses $section Section The server section this preprint is assigned to
 * @uses $categories array Category titles and paths the preprint is assigned to
 * @uses $primaryGalleys array List of preprint galleys that are not supplementary or dependent
 * @uses $supplementaryGalleys array List of preprint galleys that are supplementary
 * @uses $keywords array List of keywords assigned to this preprint
 * @uses $pubIdPlugins Array of pubId plugins which this preprint may be assigned
 * @uses $licenseTerms string License terms.
 * @uses $licenseUrl string URL to license. Only assigned if license should be
 *   included with published submissions.
 * @uses $ccLicenseBadge string An image and text with details about the license
 * @uses $pubLocaleData Array of e.g. publication's locales and metadata field names to show in multiple languages
 *}

{**
 * Filter text content of the metadata shown on the page
 * If adding more filters, see elseif examples below. Filter format with params: e.g. 'default:param'
 * @param string $value, The value to be filtered
 * @param array $filters, E.g. ['escape', 'default:""']
 * @return string, As variable $filteredPubPropValue
 *}
 {function filterPubPropValue}
	{foreach from=$filters item=$filter}
		{if $filter === 'escape'}
			{$value=$value|escape}
		{elseif $filter === 'strip_unsafe_html'}
			{$value=$value|strip_unsafe_html}
		{elseif substr($filter, 0, 7) === 'default'} {* default:param *}
			{$value=$value|default:substr($filter, 8)}
		{/if}
	{/foreach}
	{assign "filteredPubPropValue" value=$value scope="parent" nocache}
{/function}
{**
 * Publication's multilingual data to array for js and page
 * Filters texts using function filterPubPropValue
 * @param string $switcher, Required, Switcher's name
 * @param array $data, Required, E.g. $publication->getTitles('html')
 * @param array $localeOrder, Required, From $pubLocaleData.localeOrder
 * @param array $filters, Optional, E.g. ['escape']
 * @param string $separator, Optional but required to implode array (e.g. keywords)
 * @return array, As varaible $wrappedPubPropData
 *}
{function wrapPubPropData}
	{* Find the default locale from the data *}
	{foreach from=$localeOrder item=$defaultLocale}
		{if isset($data[$defaultLocale])}{break}{/if}
	{/foreach}
	{* Filter the data items using the function filterPubPropValue *}
	{foreach from=$data item=$value key=$locale}
		{* Join array items with separator, e.g. keywords *}
		{if is_array($value)}
			{$value=$separator|join:$value}
		{/if}
		{filterPubPropValue value=$value filters=$filters}
		{$data[$locale]=$filteredPubPropValue}
	{/foreach}
	{$d=['switcher' => $switcher, 'data' => $data, 'defaultLocale' => $defaultLocale]}
	{assign "wrappedPubPropData" value=$d scope="parent" nocache}
{/function}

{* Language switchers' buttons text contents: locale names can be used instead of lang attribute codes by removing the line under this comment. *}
{$pubLocaleData.localeNames = $pubLocaleData.langAttrs}

<article class="obj_preprint_details">

	{* Indicate if this is only a preview *}
	{if $publication->getData('status') !== \PKP\submission\PKPSubmission::STATUS_PUBLISHED}
		<div class="cmp_notification notice">

			{capture assign="submissionUrl"}{url page="dashboard" op="editorial" workflowSubmissionId=$preprint->getId()}{/capture}

			{translate key="submission.viewingPreview" url=$submissionUrl}
		</div>
	{/if}

	{* Notification that this is an old version *}
	{if $currentPublication->getId() !== $publication->getId()}
		<div class="cmp_notification notice">
			{capture assign="latestVersionUrl"}{url page="preprint" op="view" path=$preprint->getBestId()}{/capture}
			{translate key="submission.outdatedVersion"
				datePublished=$publication->getData('datePublished')|date_format:$dateFormatShort
				urlRecentVersion=$latestVersionUrl|escape
			}
		</div>
	{/if}

	{* Crossref requirements: The landing page must link to the AM/VOR when it is made available.*}
	{if $publication->getData('relationStatus') == \APP\publication\Publication::PUBLICATION_RELATION_PUBLISHED}
		<div class="cmp_notification notice">
				{translate key="publication.relation.published"}
				{if $publication->getData('vorDoi')}
					<br />
					{translate key="publication.relation.vorDoi"}
					<span class="value">
						<a href="{$publication->getData('vorDoi')|escape}">
							{$publication->getData('vorDoi')|escape}
						</a>
					</span>
				{/if}
		</div>
	{/if}

	{* Crossref requirements: The landing page must be labeled as not formally published (e.g. “preprint”, “unpublished manuscript”). This label must appear above the scroll. *}
	<span class="preprint_label">{translate key="common.publication"}</span>
	<span class="separator">{translate key="navigation.breadcrumbSeparator"}</span>
	<span class="preprint_version">{translate key="publication.version" version=$publication->getData('version')}</span>

	{** Example usage of the language switcher, title and subtitle
	 * In h1, the attribute data-pkp-switcher-data="title" and, in h2, the attribute data-pkp-switcher-data="subtitle" are used to sync the text content in elements when
	 * the language is switched. 
	 * The attribute data-pkp-switcher="titles" is the container for the switcher's buttons, it needs to match json's switcher-key's value, e.g. {"title":{"switcher":"titles"...
	 * The function wrapPubPropData wraps publication data for the json and the tpl, e.g. $pubLocaleData.title=$wrappedPubPropData,
	 *  $pubLocaleData's title-key needs to match data-pkp-switcher-data'-attribute's value, e.g. data-pkp-switcher-data="title". This is for to sync the data in the correct element.
	 * See all the examples below.
	 * The rest of the work is handled by the js code.
	 *}
	{* Publication title for json *}
	{wrapPubPropData switcher="titles" data=$publication->getTitles('html') localeOrder=$pubLocaleData.localeOrder filters=['strip_unsafe_html']}
	{$pubLocaleData.title=$wrappedPubPropData}
	<h1
		class="page_title"
		data-pkp-switcher-data="title"
		lang="{$pubLocaleData.langAttrs[$pubLocaleData.title.defaultLocale]}"
	>
		{$pubLocaleData.title.data[$pubLocaleData.title.defaultLocale]}
	</h1>

	{if $publication->getSubTitles('html')}
		{* Publication subtitle for json *}
		{wrapPubPropData switcher="titles" data=$publication->getSubTitles('html') localeOrder=$pubLocaleData.localeOrder filters=['strip_unsafe_html']}
		{$pubLocaleData.subtitle=$wrappedPubPropData}
		<h2
			class="subtitle"
			data-pkp-switcher-data="subtitle"
			lang="{$pubLocaleData.langAttrs[$pubLocaleData.subtitle.defaultLocale]}"
		>
			{$pubLocaleData.subtitle.data[$pubLocaleData.subtitle.defaultLocale]}
		</h2>
	{/if}
	{* Title and subtitle common switcher *}
	{if isset($pubLocaleData.opts.title)}
		<span aria-label="{translate key="plugins.themes.default.languageSwitcher.ariaDescription.titles"}" role="none" aria-orientation="horizontal" data-pkp-switcher="titles"></span>
	{/if}

	<div class="row">
		<div class="main_entry">
			{if $publication->getData('authors')}
				<section class="item authors">
					<h2 class="pkp_screen_reader">{translate key="submission.authors"}</h2>
					<ul class="versions authors">
					{foreach from=$publication->getData('authors') item=author}
						<li>
							<span class="name">
								{$author->getFullName()|escape}
								{* Author switcher *}
								{if isset($pubLocaleData.opts.author)}
									<span aria-label="{translate key="plugins.themes.default.languageSwitcher.ariaDescription.author"}" role="none" aria-orientation="horizontal" aria-expanded="false" data-pkp-switcher="author{$author@index}"></span>
								{/if}
							</span>
							{if $author->getData('affiliation')}
								{* Publication author for json *}
								{wrapPubPropData switcher="author{$author@index}" data=$author->getData('affiliation') localeOrder=$pubLocaleData.localeOrder filters=['strip_unsafe_html']}
								{$pubLocaleData["author{$author@index}"]=$wrappedPubPropData}
								<span
									class="affiliation"
									data-pkp-switcher-data="author{$author@index}"
									lang="{$pubLocaleData.langAttrs[$pubLocaleData["author{$author@index}"].defaultLocale]}"
								>
									{$pubLocaleData["author{$author@index}"].data[$pubLocaleData["author{$author@index}"].defaultLocale]}
								</span>
							{/if}
							{if $author->getData('orcid')}
								<span class="orcid">
									{if $author->hasVerifiedOrcid()}
										{$orcidIcon}
									{else}
										{$orcidUnauthenticatedIcon}
									{/if}
									<a href="{$author->getData('orcid')|escape}" target="_blank">
										{$author->getOrcidDisplayValue()|escape}
									</a>
								</span>
							{/if}
						</li>
					{/foreach}
					</ul>
				</section>
			{/if}

			{* DOI *}
			{assign var=doiObject value=$publication->getData('doiObject')}
			{if $doiObject}
				{assign var="doiUrl" value=$doiObject->getData('resolvingUrl')|escape}
				<section class="item doi">
					<h2 class="label">
						{capture assign=translatedDOI}{translate key="doi.readerDisplayName"}{/capture}
						{translate key="semicolon" label=$translatedDOI}
					</h2>
					<span class="value">
 						<a href="{$doiUrl}">
 							{$doiUrl}
 						</a>
 					</span>
				</section>
			{/if}

			{* Keywords *}
			{if $publication->getData('keywords')}
				{* Publication keywords for json *}
				{capture assign=keywordSeparator}{translate key="common.commaListSeparator"}{/capture}
				{wrapPubPropData switcher="keywords" data=$publication->getData('keywords') localeOrder=$pubLocaleData.localeOrder filters=['escape'] separator=$keywordSeparator}
				{$pubLocaleData.keywords=$wrappedPubPropData}
				<section class="item keywords">
					<h2 class="label">
						{capture assign=translatedKeywords}{translate key="common.keywords"}{/capture}
						{translate key="semicolon" label=$translatedKeywords}
					</h2>
					<span>
						<span
							class="value"
							lang="{$pubLocaleData.langAttrs[$pubLocaleData.keywords.defaultLocale]}"
							data-pkp-switcher-data="keywords"
						>
							{$pubLocaleData.keywords.data[$pubLocaleData.keywords.defaultLocale]}
						</span>
						{* Keyword switcher *}
						{if isset($pubLocaleData.opts.keywords)}
							<span aria-label="{translate key="plugins.themes.default.languageSwitcher.ariaDescription.keywords"}" role="none" aria-orientation="horizontal" aria-expanded="false" data-pkp-switcher="keywords"></span>
						{/if}
					</span>
				</section>
			{/if}

			{* Abstract *}
			{if $publication->getData('abstract')}
				{* Publication abstract for json *}
				{wrapPubPropData switcher="abstract" data=$publication->getData('abstract') localeOrder=$pubLocaleData.localeOrder filters=['strip_unsafe_html']}
				{$pubLocaleData.abstract=$wrappedPubPropData}
				<section class="item abstract">
					<div>
						<h2 class="label">
							{translate key="common.abstract"}
						</h2>
						{* Abstract switcher *}
						{if isset($pubLocaleData.opts.abstract)}
							<span aria-label="{translate key="plugins.themes.default.languageSwitcher.ariaDescription.abstract"}" role="none" aria-orientation="horizontal" aria-expanded="false" data-pkp-switcher="abstract"></span>
						{/if}
					</div>
					<div
						data-pkp-switcher-data="abstract"
						lang="{$pubLocaleData.langAttrs[$pubLocaleData.abstract.defaultLocale]}"
					>
						{$pubLocaleData.abstract.data[$pubLocaleData.abstract.defaultLocale]}
					</div>
				</section>
			{/if}

			{call_hook name="Templates::Preprint::Main"}

			{* Usage statistics chart*}
			{if $activeTheme->getOption('displayStats') != 'none'}
				{$activeTheme->displayUsageStatsGraph($preprint->getId())}
				<section class="item downloads_chart">
					<h2 class="label">
						{translate key="plugins.themes.default.displayStats.downloads"}
					</h2>
					<div class="value">
						<canvas class="usageStatsGraph" data-object-type="Submission" data-object-id="{$preprint->getId()|escape}"></canvas>
						<div class="usageStatsUnavailable" data-object-type="Submission" data-object-id="{$preprint->getId()|escape}">
							{translate key="plugins.themes.default.displayStats.noStats"}
						</div>
					</div>
				</section>
			{/if}

			{* Author biographies *}
			{assign var="hasBiographies" value=0}
			{foreach from=$publication->getData('authors') item=author}
				{if $author->getLocalizedData('biography')}
					{assign var="hasBiographies" value=$hasBiographies+1}
				{/if}
			{/foreach}
			{if $hasBiographies}
				<section class="item author_bios">
					<h2 class="label">
						{if $hasBiographies > 1}
							{translate key="submission.authorBiographies"}
						{else}
							{translate key="submission.authorBiography"}
						{/if}
					</h2>
					{foreach from=$publication->getData('authors') item=author}
						{if $author->getLocalizedData('biography')}
							<section class="sub_item">
								<h3 class="label">
									{if $author->getLocalizedData('affiliation')}
										{capture assign="authorName"}{$author->getFullName()|escape}{/capture}
										{capture assign="authorAffiliation"}<span class="affiliation">{$author->getLocalizedData('affiliation')|escape}</span>{/capture}
										{translate key="submission.authorWithAffiliation" name=$authorName affiliation=$authorAffiliation}
									{else}
										{$author->getFullName()|escape}
									{/if}
								</h3>
								<div class="value">
									{$author->getLocalizedData('biography')|strip_unsafe_html}
								</div>
							</section>
						{/if}
					{/foreach}
				</section>
			{/if}

			{* References *}
			{if $parsedCitations || $publication->getData('citationsRaw')}
				<section class="item references">
					<h2 class="label">
						{translate key="submission.citations"}
					</h2>
					<div class="value">
						{if $parsedCitations}
							{foreach from=$parsedCitations item="parsedCitation"}
								<p>{$parsedCitation->getCitationWithLinks()|strip_unsafe_html} {call_hook name="Templates::Preprint::Details::Reference" citation=$parsedCitation}</p>
							{/foreach}
						{else}
							{$publication->getData('citationsRaw')|escape|nl2br}
						{/if}
					</div>
				</section>
			{/if}

		</div><!-- .main_entry -->

		<div class="entry_details">
			{* Preprint cover image *}
			{if $publication->getLocalizedData('coverImage')}
				<div class="item cover_image">
					<div class="sub_item">
							{assign var="coverImage" value=$publication->getLocalizedData('coverImage')}
							<img
								src="{$publication->getLocalizedCoverImageUrl($preprint->getData('contextId'))|escape}"
								alt="{$coverImage.altText|escape|default:''}"
							>
					</div>
				</div>
			{/if}

			{* Preprint Galleys *}
			{if $primaryGalleys}
				<div class="item galleys">
					<h2 class="pkp_screen_reader">
						{translate key="submission.downloads"}
					</h2>
					<ul class="value galleys_links">
						{foreach from=$primaryGalleys item=galley}
							<li>
								{include file="frontend/objects/galley_link.tpl" parent=$preprint publication=$publication galley=$galley}
							</li>
						{/foreach}
					</ul>
				</div>
			{/if}
			{if $supplementaryGalleys}
				<div class="item galleys">
					<h3 class="pkp_screen_reader">
						{translate key="submission.additionalFiles"}
					</h3>
					<ul class="value supplementary_galleys_links">
						{foreach from=$supplementaryGalleys item=galley}
							<li>
								{include file="frontend/objects/galley_link.tpl" parent=$preprint publication=$publication galley=$galley isSupplementary="1"}
							</li>
						{/foreach}
					</ul>
				</div>
			{/if}
			{if $publication->getData('datePublished')}
			<div class="item published">
				<section class="sub_item">
					<h2 class="label">
						{translate key="submissions.published"}
					</h2>
					<div class="value">
						{* If this is the original version *}
						{if $firstPublication->getId() === $publication->getId()}
							<span>{$firstPublication->getData('datePublished')|date_format:$dateFormatShort}</span>
						{* If this is an updated version *}
						{else}
							<span>{translate key="submission.updatedOn" datePublished=$firstPublication->getData('datePublished')|date_format:$dateFormatShort dateUpdated=$publication->getData('datePublished')|date_format:$dateFormatShort}</span>
						{/if}
					</div>
				</section>
				{if count($preprint->getPublishedPublications()) > 1}
					<section class="sub_item versions">
						<h2 class="label">
							{translate key="submission.versions"}
						</h2>
						<ul class="value">
							{foreach from=array_reverse($preprint->getPublishedPublications()) item=iPublication}
								{capture assign="name"}{translate key="submission.versionIdentity" datePublished=$iPublication->getData('datePublished')|date_format:$dateFormatShort version=$iPublication->getData('version')}{/capture}
								<li>
									{if $iPublication->getId() === $publication->getId()}
										{$name}
									{elseif $iPublication->getId() === $currentPublication->getId()}
										<a href="{url page="preprint" op="view" path=$preprint->getBestId()}">{$name}</a>
									{else}
										<a href="{url page="preprint" op="view" path=$preprint->getBestId()|to_array:"version":$iPublication->getId()}">{$name}</a>
									{/if}
								</li>
							{/foreach}
						</ul>
					</section>
				{/if}
			</div>
			{/if}

			{* Categories preprint appears in *}
			<div class="item categories">
				{if $categories}
					<section class="sub_item">
						<h2 class="label">
							{translate key="category.categories"}
						</h2>
						<ul class="value">
							{foreach from=$categories item=category}
								<li class="category_{$category.path}">
									<a href="{url router=PKP\core\PKPApplication::ROUTE_PAGE page="preprints" op="category" path=$category.path|escape}">
										{$category.title|escape}
									</a>
								</li>
							{/foreach}
						</ul>
					</section>
				{/if}
			</div>

			{* How to cite *}
			{if $citation}
				<div class="item citation">
					<section class="sub_item citation_display">
						<h2 class="label">
							{translate key="submission.howToCite"}
						</h2>
						<div class="value">
							<div id="citationOutput" role="region" aria-live="polite">
								{$citation}
							</div>
							<div class="citation_formats">
								<button class="cmp_button citation_formats_button" aria-controls="cslCitationFormats" aria-expanded="false" data-csl-dropdown="true">
									{translate key="submission.howToCite.citationFormats"}
								</button>
								<div id="cslCitationFormats" class="citation_formats_list" aria-hidden="true">
									<ul class="citation_formats_styles">
										{foreach from=$citationStyles item="citationStyle"}
											<li>
												<a
													aria-controls="citationOutput"
													href="{url page="citationstylelanguage" op="get" path=$citationStyle.id params=$citationArgs}"
													data-load-citation
													data-json-href="{url page="citationstylelanguage" op="get" path=$citationStyle.id params=$citationArgsJson}"
												>
													{$citationStyle.title|escape}
												</a>
											</li>
										{/foreach}
									</ul>
									{if count($citationDownloads)}
										<div class="label">
											{translate key="submission.howToCite.downloadCitation"}
										</div>
										<ul class="citation_formats_styles">
											{foreach from=$citationDownloads item="citationDownload"}
												<li>
													<a href="{url page="citationstylelanguage" op="download" path=$citationDownload.id params=$citationArgs}">
														<span class="fa fa-download"></span>
														{$citationDownload.title|escape}
													</a>
												</li>
											{/foreach}
										</ul>
									{/if}
								</div>
							</div>
						</div>
					</section>
				</div>
			{/if}

			{* Data Availability Statement *}
			{if $publication->getLocalizedData('dataAvailability')}
				<section class="item dataAvailability">
					<h2 class="label">{translate key="submission.dataAvailability"}</h2>
					{$publication->getLocalizedData('dataAvailability')|strip_unsafe_html}
				</section>
			{/if}

			{* PubIds (requires plugins) *}
			{foreach from=$pubIdPlugins item=pubIdPlugin}
				{if $pubIdPlugin->getPubIdType() == 'doi'}
					{continue}
				{/if}
				{assign var=pubId value=$preprint->getStoredPubId($pubIdPlugin->getPubIdType())}
				{if $pubId}
					<section class="item pubid">
						<h2 class="label">
							{$pubIdPlugin->getPubIdDisplayType()|escape}
						</h2>
						<div class="value">
							{if $pubIdPlugin->getResolvingURL($currentServer->getId(), $pubId)|escape}
								<a id="pub-id::{$pubIdPlugin->getPubIdType()|escape}" href="{$pubIdPlugin->getResolvingURL($currentServer->getId(), $pubId)|escape}">
									{$pubIdPlugin->getResolvingURL($currentServer->getId(), $pubId)|escape}
								</a>
							{else}
								{$pubId|escape}
							{/if}
						</div>
					</section>
				{/if}
			{/foreach}

			{* Licensing info *}
			{if $currentContext->getLocalizedData('licenseTerms') || $publication->getData('licenseUrl')}
				<div class="item copyright">
					<h2 class="label">
						{translate key="submission.license"}
					</h2>
					{if $publication->getData('licenseUrl')}
						{if $ccLicenseBadge}
							{if $publication->getLocalizedData('copyrightHolder')}
								<p>{translate key="submission.copyrightStatement" copyrightHolder=$publication->getLocalizedData('copyrightHolder') copyrightYear=$publication->getData('copyrightYear')}</p>
							{/if}
							{$ccLicenseBadge}
						{else}
							<a href="{$publication->getData('licenseUrl')|escape}" class="copyright">
								{if $publication->getLocalizedData('copyrightHolder')}
									{translate key="submission.copyrightStatement" copyrightHolder=$publication->getLocalizedData('copyrightHolder') copyrightYear=$publication->getData('copyrightYear')}
								{else}
									{translate key="submission.license"}
								{/if}
							</a>
						{/if}
					{/if}
					{$currentContext->getLocalizedData('licenseTerms')}
				</div>
			{/if}

			{call_hook name="Templates::Preprint::Details"}

		</div><!-- .entry_details -->
	</div><!-- .row -->

</article>

<script type="text/javascript">
	/* Publication multilingual data to json for js
	 * Grave accent (`) had to be encoded, otherwise json parse error
	 */
	{$pubLocaleDataJson=$pubLocaleData|json_encode|replace:'`':'&#96;'|escape:'javascript':'UTF-8'}
	var pubLocaleDataJson = "{$pubLocaleDataJson}";
</script>
