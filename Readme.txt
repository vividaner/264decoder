H.264 decoder demo

[Problem]

Write a sample mp4 player for Android or iOS that accepts two mp4 files (with h264 video) as input and displays the video layers after blending.

Add UI knobs to switch between blending modes. Ensure the video decode is hardware accelerated and blending is performed on the GPU.

[Implementation]
This 264 decoder is implemented on iOS platform based on FFmpeg open resource. The H.264 decoder library for iOS is built using the FFmpeg source code. So far, a simple video player is implemented in iOS simulator. One H.264 bitstream can be decoded and displayed in UI window.  


[Usage]
1. Modify the bitstream file name for display:
The input file to the decoder is 264 bitstream file. 
In the file “H264ViewController.m”，
NSString *FilePath = [bundlePath stringByAppendingPathComponent:@"176x144.264"];
the name of bitstream file for display should be written in the code as the “***.264”. The bitstream file should also be added in the resources list of the project. 

2. Build and Run:
After modification of the file name, build and run the project. The UI simulator will run. Click the “play” button and the video will display. 

[Future improvement]
This problem is challenging for me, since I am not familiar with the iOS development. Although I enjoy working on this problem, some requirements are not achieved in this version. I would like to keep improving the project functions as follows:
1. Implement the two videos display and enable the blending mode.
2. Improve the UI function, enable the users to open the video file in UI window directly.
3. Improve the system performance using the hardware acceleration.   

