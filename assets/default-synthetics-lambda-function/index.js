/* This default synthetic action is copied from the AWS Console as the default
 * NodeJS example. The script has been modified to take a URL paramter via an
 * environment variable for ease of deploying the code with terraform.
 */

const { URL } = require('url');
const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();
const syntheticsLogHelper = require('SyntheticsLogHelper');
 
const checkPage = async function () {

    // check if the URL environment variable is set
    if (!("URL" in process.env)) {
       throw new Error("Missing URL environment variable!");
    }
 
    let url = process.env.URL
    
    syntheticsConfiguration.disableStepScreenshots();
    syntheticsConfiguration.setConfig({
       continueOnStepFailure: true,
       includeRequestHeaders: true, // Enable if headers should be displayed in HAR
       includeResponseHeaders: true, // Enable if headers should be displayed in HAR
       restrictedHeaders: [], // Value of these headers will be redacted from logs and reports
       restrictedUrlParameters: [] // Values of these url parameters will be redacted from logs and reports
    });
    
    let page = await synthetics.getPage();
    
    await loadUrl(page, url);
};

// Reset the page in-between
const resetPage = async function(page) {
    try {
        await page.goto('about:blank',{waitUntil: ['load', 'networkidle0'], timeout: 30000} );
    } catch(ex) {
        synthetics.addExecutionError('Unable to open a blank page ', ex);
    }
}
 
const loadUrl = async function (page, url) {
    let stepName = null;
    let domcontentloaded = false;
 
    try {
        stepName = new URL(url).hostname;
    } catch (error) {
        const errorString = `Error parsing url: ${url}.  ${error}`;
        log.error(errorString);
        /* If we fail to parse the URL, don't emit a metric with a stepName based on it.
           It may not be a legal CloudWatch metric dimension name and we may not have an alarms
           setup on the malformed URL stepName.  Instead, fail this step which will
           show up in the logs and will fail the overall canary and alarm on the overall canary
           success rate.
        */
        throw error;
    }
    
    await synthetics.executeStep(stepName, async function () {
        const sanitizedUrl = syntheticsLogHelper.getSanitizedUrl(url);
        const response = await page.goto(url, { waitUntil: ['domcontentloaded'], timeout: 30000});
        if (response) {
            domcontentloaded = true;
            const status = response.status();
            const statusText = response.statusText();
 
            logResponseString = `Response from url: ${sanitizedUrl}  Status: ${status}  Status Text: ${statusText}`;

            // If the response status code is not a 2xx success code
            if (response.status() < 200 || response.status() > 299) {
                throw `Failed to load url: ${sanitizedUrl} ${response.status()} ${response.statusText()}`;
            }
        } else {
            const logNoResponseString = `No response returned for url: ${sanitizedUrl}`;
            log.error(logNoResponseString);
            throw new Error(logNoResponseString);
        }
    });
};

exports.handler = async () => {
    return await checkPage();
};
