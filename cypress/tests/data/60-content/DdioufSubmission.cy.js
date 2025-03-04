/**
 * @file cypress/tests/data/60-content/DdioufSubmission.cy.js
 *
 * Copyright (c) 2014-2021 Simon Fraser University
 * Copyright (c) 2000-2021 John Willinsky
 * Distributed under the GNU GPL v3. For full terms see the file docs/COPYING.
 *
 */

describe('Data suite: Ddiouf', function() {
	let submission;

	before(function() {
		const title = 'Genetic transformation of forest trees';
		submission = {
			id: 0,
			section: 'Preprints',
			prefix: '',
			title: title,
			subtitle: '',
			abstract: 'In this review, the recent progress on genetic transformation of forest trees were discussed. Its described also, different applications of genetic engineering for improving forest trees or understanding the mechanisms governing genes expression in woody plants.',
			shortAuthorString: 'Diouf',
			authorNames: ['Diaga Diouf'],
			sectionId: 1,
			assignedAuthorNames: ['Diaga Diouf'],
			files: [
				{
					'file': 'dummy.pdf',
					'fileName': title + '.pdf',
					'mimeType': 'application/pdf',
					'genre': Cypress.env('defaultGenre')
				},
			]
		};
	});

	it('Create a submission', function() {
		cy.register({
			'username': 'ddiouf',
			'givenName': 'Diaga',
			'familyName': 'Diouf',
			'affiliation': 'Alexandria University',
			'country': 'Egypt',
		});

		cy.getCsrfToken();
		cy.window()
			.then(() => {
				return cy.createSubmissionWithApi(submission, this.csrfToken);
			})
			.then(xhr => {
				return cy.submitSubmissionWithApi(submission.id, this.csrfToken);
			});
	});

	it('Declines the submission, reverts the decline, and declines it again', function() {
		cy.findSubmissionAsEditor('dbarnes', null, 'Diouf');
		cy.clickDecision('Decline Submission');
		cy.recordDecisionDecline(['Diaga Diouf']);
		// TODO re-add this check once its determined where to indicate it in new design
		//cy.get('.pkp_workflow_last_decision').contains('Submission declined.');
		cy.openWorkflowMenu('Production');
		cy.clickDecision('Revert Decline');
		cy.recordDecisionRevertDecline(['Diaga Diouf']);
		cy.clickDecision('Decline Submission');
		cy.recordDecisionDecline(['Diaga Diouf']);
	});
});
