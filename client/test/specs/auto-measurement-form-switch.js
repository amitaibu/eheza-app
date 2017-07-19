var assert = require('assert');

describe('Auto transform between measurement forms.', () => {

    before(() => {
        browser.loginAndViewPatientsPage('aya');

        // Following the first patient (child) page.
        browser.element('#patients-table tbody tr td a.child').click();
        browser.waitForVisible('#mother-info');

        // In case the Photo is already completed we should switch to the
        // Completed tab.
        if (!browser.isVisible('a=Photo') && browser.isVisible('#pending-tab.active')) {
            browser.element('#completed-tab').click();
        }
        // Initially follow the Photo form.
        browser.element('a=Photo').click();
    });

    it('Saving the Photo form should lead to the Weight form.', () => {
        browser.element('#save-form').click();
        // The help text of the Weight form.
        browser.waitForVisible("p=Calibrate the scale before taking the first baby's weight. Place baby in harness with no clothes on.");
    });

    it('Saving the Weight form should lead to the Height form.', () => {
        browser.element('#save-form').click();
        // The help text of the Height form.
        browser.waitForVisible("p=Ask the mother to hold the baby’s head at the end of the measuring board. Move the slider to the baby’s heel and pull their leg straight.");
    });

});
