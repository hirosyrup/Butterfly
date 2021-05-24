<p align="center">
<img src="https://user-images.githubusercontent.com/24717967/118624685-5297eb80-b804-11eb-9555-736bdc311e1b.png" alt="app_icon" title="app_icon">
</p>
<p align="center">
<a href="https://github.com/hirosyrup/Butterfly/blob/master/README.md">🇺🇸English</a> / <a href="https://github.com/hirosyrup/Butterfly/blob/master/README-ja.md">🇯🇵Japanese</a>
</p>


# Butterfly

Butterfly is a tool for creating minutes. It has the following features.

* It transcribes the voice for each speaker and save it.
* You can copy the transcribed text to the clipboard or exported as CSV.
* The recorded data is also saved along with it.
* You can preview the audio from any location on the transcribed text.

https://user-images.githubusercontent.com/24717967/118831907-198e7280-b8fb-11eb-86ea-b453e61b1859.mp4

# System requirements

macOS 10.15 or above.

iOS version is coming soon!

# How to install

## Preparation

Use Firebase as your operating infrastructure. The environment must be prepared by the user. Therefore, prepare the following.

* Google account for Firebase registration.
* Install [Firebase CLI](https://firebase.google.com/docs/cli?hl=ja).

## Create a project in Firebase

Follow steps 1-3 in [this article ](https://firebase.google.com/docs/ios/setup?hl=ja) to get GoogleService-Info.plist.

* The project name can be anything.
* It doesn't use Google Analytics, so it can be enabled or disabled.
* Enter 'com.koalab.Butterfly' as the bundle ID when adding an iOS app. You do not need to enter your nickname and App Store ID.
* After downloading the plist file, click Next to skip the remaining steps.

## Project settings

### Authentication settings

Click "Authentication" from the left menu of the Firebase dashboard, and then click "Start" on the screen that appears.

Open the "Sign-in method" tab and open "Email / Password" from the provider to enable it. Leave the email link disabled.

### Firestore settings

Click "Firestore" from the left menu of the Firebase dashboard, and then click "Create Database" on the screen that appears.

Select "Start in production mode" and then select a location closest to your area.

### Deploy security rules and indexes

Clone the source code with git or download it from "[Release](https://github.com/hirosyrup/Butterfly/releases)" and change to the project root directory in your terminal.

Then login to firebase.

```
firebase login
```

Finally, execute the following command and wait for it to complete. It may take a few minutes for the settings to take effect.

```
cd deploy
./deploy.sh your-project-id
```

*Please replace "your-project-id" as it appears on the project setting screen.

<img width="689" alt="" src="https://user-images.githubusercontent.com/24717967/118674536-cf42be00-b834-11eb-9fd0-05ae56b5c4ed.png">

This completes the project settings.
You can use it for a while with a free tier, but if you are about to exceed it, please register for a paid plan (Blaze).
You can check the price [here](https://firebase.google.com/pricing?hl=ja).

## How to install the application

Please download the latest version from [here](https://github.com/hirosyrup/Butterfly/releases).

Unzip the zip file and launch the app. **Butterfly is a status bar resident app.**
It does not appear in the Dock.

*If you get a warning that the developer is unknown and cannot be opened, please allow execution from "Security & Privacy" in "System Preferences".

# How to use the application

## Main window

<img width="320" alt="" src="https://user-images.githubusercontent.com/24717967/118834264-0da3b000-b8fd-11eb-8dd1-e7da4f1277bc.png">

1. Menu
2. Switching workspaces
3. Add new meeting
4. Search by meeting titles
5. Search by date
6. Edit the meeting
7. Archive the meeting
   *When archived, the data itself remains but is hidden from the list.

## User settings

You can open the preferences screen from the menu.

<img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/118833719-a259de00-b8fc-11eb-8391-f1aae7d0aeda.png">

1. Icon image setting. Be sure to use a square image.
2. User name. Press the pencil icon to enter edit mode. It will change to a check icon, so click it to save.
3. Language setting. It be applied when transcribing using Apple's voice recognition engine.
4. It is a function to acquire the voiceprint used for [speaker recognition](#Speaker recognition).

## Workspace settings

<img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/118834176-fd8bd080-b8fc-11eb-8341-83218cc817da.png">

1. Workspace name
2. Selection of members belonging to the workspace. Only members selected here can attend meetings in the workspace.
3. Enable / disable switch of [speaker recognition](#Speaker recognition).

## Meeting window

<img width="320" alt="" src="https://user-images.githubusercontent.com/24717967/118834370-244a0700-b8fd-11eb-8d6d-83dbd2813314.png">

1. The participants of the meeting are displayed. The user who has the meeting window open is marked with a red circle and only that user can accept microphone input.
   Since the microphones of each device are used, when the meeting is held with multiple people in the same room, a voice is picked up from the microphones and the transcribed content is duplicated. Therefore, under such circumstances, it is recommended to use the  [speaker recognition](#Speaker recognition) function.
   Conversely, when meeting in separate locations, such as remote meetings, users who are far apart must always open a window to enable microphone input.
2. It is a button to export the transcribed contents and the audio file.
3. It is a button that opens and closes the list view of the transcribed contents.
4. This is the meeting start button. When you start, transcription and recording will start. The user who presses the start button becomes the host, and only it can end the meeting. At the end, the recorded audio file from start to finish will be uploaded to Firebase storage. Therefore, be sure to remember that the host user terminates it.

# Advanced feature

This section describes optional functions to improve the accuracy of transcription.

## Speaker recognition

When meeting with multiple people in the same room, one person should open the meeting window and use one microphone input to avoid duplicated transcription.
However, since all input voice is recognized as the user of the device, it becomes impossible to determine who spoke.
By using the speaker recognition function, it is possible to distinguish between them. To use the speaker recognition function, it is necessary to take the voiceprint of the users belongs to  the workspace and create a speaker recognition model.

### Preparation

To create a speaker recognition model, use the "Create ML" app that comes with Xcode. Please install Xcode in advance.

### Take the voiceprint

Open the user settings from "Preferences" in the menu and click "Create voice print".
When you press the start button, recording will start as it is, so whatever the content is, **please continue talking for 20 seconds without interruption**.
When you press the start button, a 20 seconds countdown will start, and when it reaches 0, recording will stop and the recorded file will be automatically uploaded to the storage.

Please be aware of the following points to improve the accuracy of speaker recognition. In short, it is easier to improve the accuracy if there is no difference between the recording environment and the actual environment of the meeting.

* Record in the room where you often hold meetings.
* Record using the microphone you use all the time.
* Record with a natural voice when you are always speaking.

### Creating the speaker recognition model

Follow the steps below to perform machine learning and create a speaker recognition model. You will need to recreate the model each time a voiceprint is added.

1. Open the workspace settings from Preferences in the menu, and enable "Enable speaker recognition" on the screen for adding or editing a workspace.

2. Click the "Export a learning data set" button to export the learning data to any location.

3. Launch Create ML via Xcode.

   <img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/119353120-74e6a900-bcdd-11eb-8f45-2008ed0805be.png">

4. Create a project with "Sound Classification".

5. Drag the folder containing the learning audio file output in step 2 to the application window, click the "Train" button, and wait for a while until it is completed.
   <img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/119353901-677dee80-bcde-11eb-8ff9-406d8c3c47f3.png">

6. Open the "Output" tab and click the "Get" button to output the model file to any location.
   <img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/119354114-a7dd6c80-bcde-11eb-9504-4bbd997c38ea.png">

7. Return to the workspace settings in Butterfly Preferences, open the workspace edit screen, click the "Upload ML File" button, and select the model file output in step 6. Click the OK button to upload the model file to the storage and complete the settings. When you start a meeting in the workspace, it will be transcribed with speaker recognition applied.

# License

Butterfly is released under an MIT license.

See [LICENSE](https://github.com/hirosyrup/Butterfly/blob/master/LICENSE) for more information.

Please refer to the following for the license of the library used.

[Firebase](https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE)

[Hydra](https://github.com/malcommac/Hydra/blob/master/LICENSE)

[SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver/blob/master/LICENSE)

[Starscream](https://github.com/daltoniam/Starscream/blob/master/LICENSE)
