var assert = require('assert');

describe('The measurement forms', () => {

    before(() => {
        browser.loginAndViewPatientsPage('aya');

        // Following the first patient (child) page.
        browser.element('#patients-table tbody tr td a.child').click();
        browser.waitForVisible('#mother-info');

        // Initially follow the Photo form.
        browser.element('a=Photo').click();
        assert.equal(browser.elements('.pending a').value.length, 5, 'There are five pending activities');
    });

    it('should lead to the Weight form upon saving the Photo form', () => {
        browser.addTestImage('Testfile1');
        browser.element('#save-form').click();
        // The help text of the Weight form.
        browser.waitForVisible("p=Calibrate the scale before taking the first baby's weight. Place baby in harness with no clothes on.");
      assert.equal(browser.elements('.pending a').value.length, 4, 'There are four pending activities');
    });

    it('should lead to the Height form upon saving the Weight form', () => {
        browser.element('#save-form').click();
        // The help text of the Height form.
        browser.waitForVisible("p=Ask the mother to hold the baby’s head at the end of the measuring board. Move the slider to the baby’s heel and pull their leg straight.");
      assert.equal(browser.elements('.pending a').value.length, 3, 'There are three pending activities');
    });

    it('should lead to the MUAC form upon saving the Height form', () => {
        browser.element('#save-form').click();
        // The help text of the MUAC form.
        browser.waitForVisible("p=Make sure to measure at the center of the baby’s upper arm.");
        assert.equal(browser.elements('.pending a').value.length, 2, 'There are two two pending activities');
    });

    it('should lead to the Nutrition Signs form upon saving the MUAC form', () => {
        browser.element('#save-form').click();
        // The help text of the Nutrition Signs form.
        browser.waitForVisible("p=Explain to the mother how to check the malnutrition signs for their own child.");
        assert.equal(browser.elements('.pending a').value.length, 1, 'There is only one pending activity');
    });

    it('Saving the Nutrition Signs should result in zero pending activities', () => {
        browser.element('#save-form').click();

        // Check if all activities disappeared.
        assert.equal(browser.elements('.pending a').value.length, 0, 'There is no pending activity');
    });

});
