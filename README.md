# OpenHumansUpload

##What is it?
OpenHumansUpload is two things. Firstly, it is an open source (MIT License) iOS application designed to upload data snapshots of HealthKit data to the Open Humans project.

Secondly, it contains a stand-alone class (`OH_OAuth2`) that can be used by other iOS applications to authenticate and received access tokens for Open Humans.

## Using the `OH_OAuth2` Class

1. Include the `OH_OAuth2.swift` file in your project.
2. Add the following call to your AppDelegate's `openURL` method:

    ```
    if (OH_OAuth2.sharedInstance().parseLaunchURL(url)) {
        return true;
    }
    ```
3. Take the file 
