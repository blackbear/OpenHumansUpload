# OpenHumansUpload

##What is it?
OpenHumansUpload is two things. Firstly, it is an open source (MIT License) iOS application designed to upload data snapshots of HealthKit data to the Open Humans project.

Secondly, it contains a stand-alone class (`OH_OAuth2`) that can be used by other iOS applications to authenticate and received access tokens for Open Humans.

## Using the `OH_OAuth2` Class

1. Include the `OH_OAuth2.swift`, `OhSettings-example.plist` and `close-button.png` files in your project.
2. Add the following call to your AppDelegate's `openURL` method:

    ```
    if (OH_OAuth2.sharedInstance().parseLaunchURL(url)) {
        return true;
    }
    ```
3. Take the file `OhSettings-example.plist` and rename it to `OhSettings.plist`. Edit the file and set the values to your Open Humans client id, client secret, master token, and a URL schema to launch your app.
4. Edit your project info and add a URL Type whose scheme matches the scheme you entered in step 3. It should also match the scheme you set for your Redirect URL when you created your Open Humans project.
5. In your code, when you want to authenticate a user with Open Humans and get an Access Key, make sure that your `ViewController` implements the `OHOAuth2Client` protocol (notably, the methods `authenticateSucceeded`, `authenticateFailed` and `authenticateCanceled`. In your `viewDidLoad`, subscribe to OH_OAuth2 events by doing

	```
	OH_OAuth2.sharedInstance().subscribeToEvents(self)
	```
	
6. In your `viewDidUnload` or `deinit`, call:

	```
	OH_OAuth2.sharedInstance().subscribeToEvents(self)
	```
7. When appropriate, call:

	```
	OH_OAuth2.sharedInstance().authenticateOAuth2(self)
	```
This will check to see if there is a cached refresh token, and use that to authenticate the user with the app. If it succeeds in refreshing the token, it will call the `authenticateSucceeded` method with the access token. If it fails to refresh, it will call clear the cached token and call `authenticateFailed`. If there is no cached token, it will bring up a modal web view which will let the user log into the Open Humans website. It will call `authenticateSucceeded`, `authenticateFailed` and `authenticateCanceled` depending on the result.