# AVTools

AVTools is a command-line tool developed using Swift, designed to perform various operations on audio and video files. It leverages Swift's [ArgumentParser](https://github.com/apple/swift-argument-parser) for handling command-line parsing and [AVFoundation](https://developer.apple.com/documentation/avfoundation/) for processing media tasks.

The AVTools CLI is an educational program created to demonstrate how to utilize AVFoundation capabilities from the terminal. It allows developers to learn how to manipulate audio and video files using Swift and AVFoundation.


## Features

AVTools supports a wide range of operations on audio and video files, including:

- **Converting images to video**
- **Overlaying sound on a video**
- **Overlaying text on a video**
- **Changing the speed of a video**
- **Generating images from a video**
- **Extracting audio from a video**
- **Merging multiple videos**
- **Splitting a video**
- **Extracting video without audio**
- **Rotating a video**
- **Trimming a video**
- **Cropping a video**
- **Overlaying an image on a video**

## Installation

To use AVTools, you need to have Swift installed on your system. Clone the repository and build the project using Swift Package Manager (SPM).

```bash
git clone https://github.com/your-repository/avtools.git
cd avtools
swift build
```

## Usage

After building the project, you can run AVTools from the command line. Here are some examples of how to use the various commands:

### Convert Images to Video

```bash
swift run avtools images-to-video --images-folder ./assets/images --duration 1.5 --output iv2.mov
```

### Overlay Sound

```bash
swift run avtools overlay-sound --input ./assets/video.mov --sound ./assets/bgm.mp3 --output video_with_sound.mov
```

### Overlay Text

```bash
swift run avtools overlay-text --input ./assets/video.mov --output ot3.mov --text 'Hello World' --color '#FF5733FF'
```

### Change Speed

```bash
swift run avtools speed --input ./assets/video.mov --output s1.mov --speed 3.0
```

### Generate Images from Video

```bash
swift run avtools generate-images --input ./assets/video.mov --output images --times 1.0 2.0 3.0
```

### Extract Audio

```bash
swift run avtools extract-audio --input ./assets/video.mov --output only_audio.m4a
```

### Merge Videos

```bash
swift run avtools merge --input ./assets/splits --output merged2.mov
```

### Split Video

```bash
swift run avtools split --input ./assets/video.mov --output splitted_videos --duration 1.0
```

### Extract Video

```bash
swift run avtools extract-video --input ./assets/video.mov --output only_video.mov
```

### Rotate Video

```bash
swift run avtools rotate --input ./assets/video.mov --output rv.mov --angle 180
```

### Trim Video

```bash
swift run avtools trim --input ./assets/video.mov --output t2.mov --start 2 --end 4
```

### Crop Video

```bash
swift run avtools crop --input ./assets/video.mov --output c.mov --crop-rect "0 0 100 100"
```

### Overlay Image

```bash
swift run avtools overlay-image --input ./assets/video.mov --image ./assets/cat.png --start 1.0 --duration 2.0 --output video_with_overlay.mov
```

For more detailed information on each command and its options, refer to the help provided by the tool itself using the `--help` flag.

