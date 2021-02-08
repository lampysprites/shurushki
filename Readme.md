# Shurushki

A collection of badly maintained scripts for Aseprite with no unified purpose.

## **Installation**
1. Download this repo as a .zip using the "Code" button above. 
1. Change the extension from .zip to .aseprite-extension.
1. Double click it to install. 
1. Alternatively, in Aseprite, got to "Edit > Preferences > Extensions > Add Extension" and select the saved file.
1. Might need to restart Aseprite for menu options to appear.

## **Scripts**

## Export Atlas (`File > Export Atlas`)

Combine multiple sprites to a single texture and generates .json data for the layout. Similar to spritesheet export, but can combine multiple sprites, and each layer and frame is treated separately.
**Requires** Python 3.x to be installed, along with `rectpack` package (can be installed as `python -m pip install rectpack`)

## Highlight Cels (`View > Highlight Cels`)

Makes Timeline a bit easier to navigate by finding and highlighting frames of certain duration. Also allows to highlight cels manually, even though Aseprite now added its own tools for doing so.

## Pattern Select (`Select > Frame Pattern`)

Select frames in a checkered order. Primary use is for dropping the frames from gifs to reduce the size (in that case, don't forget to adjust the framerate afterwards!).

## Time Stretch (`Frame > Time Stretch`)

Speed up/slow down the animation proportionally by scaling frame durations, or adding/removing a constant amount of time to them.

## Move Cels (`Edit > Move Cels`)

Move cels with a formula based on their frame time or frame number. Makes working with movement animations a little easier. 
*Example: setting `x=6 * t` will move the sprite with the speed of 6 pixels per frame. After that, calling with `x=-6 * t` does the same but to the left, thus returns the sprite to marching at place.*

## Noise (`Edit > Noise`)

Fill the canvas with noise using Diamond-Square algorithm.

## Gamma Ramp (`Edit > Gamma Ramp`)

Generates a gamma-interpolated gradient ramp from paint color to bg color. They look more vibrant compared to linear blending. It was created for making fake light textures - the gamma law describes the overlapping lightsources.