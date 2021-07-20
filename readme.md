## PointMatcherRectify
Matching objects using PointMatcher and rectifying image to render object always in same perspective, size and position.

### Description
This Sample is teaching visually significant points on the teach object and using those to find identical objects,
which may also contain changes in size and out-of-plane rotation.
All found objects are rectified such that they appear flat,
unrotated and always at the same position and size, regardless of their actual positions in the input images.

### How to Run
Starting this sample is possible either by running the App (F5) or debugging (F7+F10). 
Setting breakpoint on the first row inside the 'main' function allows debugging step-by-step after 'Engine.OnStarted' event.
Results can be seen in the image viewer on the DevicePage. Restarting the Sample may be necessary to show images after loading the web-page. 
To run this Sample a device with SICK Algorithm API and AppEngine >= V2.8.0 is required. For example SIM4000 with latest firmware. 
Alternatively the Emulator in AppStudio 2.3 or higher can be used.

### More Information
Tutorial "Algorithms - Matching"

### Topics
Algorithm, Image-2D, Matching, Sample, SICK-AppSpace
