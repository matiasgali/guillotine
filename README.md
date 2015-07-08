jQuery Guillotine Plugin
========================

[![NPM](https://nodei.co/npm/guillotine.png?mini=true)](https://npmjs.org/package/guillotine)

Demo
----
<http://guillotine.js.org>


Description
-----------
Guillotine is a jQuery plugin that allows to **drag**, **zoom** or **rotate**
an image to select a cropping area. Like selecting the display area of a
profile picture or avatar.

* **Responsive:** The window (or selection area) is fully responsive (fluid).
* **Touch support:** Dragging the image also works on touch devices.

*(2.7kb minified and gzipped)*


Setup
-----
1.  Load the required files:
    * *jquery.js*
    * *jquery.guillotine.js*
    * *jquery.guillotine.css*

2.  Set the width of the parent element:
    ```html
    <div id="theparent" style="width: 80%;">
      <img id="thepicture" src="url/to/image">
    </div>
    ```

    The window ("the guillotine") that will wrap around the image when the
    plugin is instantiated is fully responsive (fluid) so it will always take
    all the width left by its parent.

3.  Instantiate the plugin:
    ```javascript
    var picture = $('#thepicture');  // Must be already loaded or cached!
    picture.guillotine({width: 400, height: 300});
    ```

    Here we set the dimensions we want for the cropped image (400x300), which
    are totally independent of the size in which the "guillotine" or "window"
    is actually displayed on screen.

    Even though it's responsive, the data returned always corresponds to the
    predefined dimensions. In this case, it will always get a cropped image of
    400 by 300 pixels.

    **Notice:** Make sure that the target element is ready before instantiating!

    If it's an image, make sure that it is already loaded or cached before
    calling Guillotine, so it can get its dimensions and display it properly.
    You can use the *onload* event, the *complete* property or check that the
    image has a width greater than zero to determine if it's loaded.


4.  Bind actions:
    ```javascript
    $('#rotate-left-button').click(function(){
      picture.guillotine('rotateLeft');
    });

    $('#zoom-in-button').click(function(){
      picture.guillotine('zoomIn');
    });

    ...
    ```

5.  Handle cropping instructions:

    The plugin is not meant to actually crop images but to generate the
    necessary instructions to do so on the server.

    *   You can get the instructions at any point by calling 'getData':
        ```javascript
        data = picture.guillotine('getData');
        // { scale: 1.4, angle: 270, x: 10, y: 20, w: 400, h: 300 }
        ```

        **Important:** You should rotate and scale first, and then apply
        the cropping coordinates to get it right!

    *   Or you can use a callback or a custom event to listen for changes:
        ```javascript
        var otherPicture = $('#other-picture');
        otherPicture.guillotine({eventOnChange: 'guillotinechange'});
        otherPicture.on('guillotinechange', function(ev, data, action){
          // this = current element
          // ev = event object
          // data = { scale: 1.4, angle: 270, x: 10, y: 20, w: 400, h: 300 }
          // action = drag/rot')eLeft/rotateRight/center/fit/zoomIn/zoomOut
          // Save data on hidden inputs...
        });
        ```

        Set the 'onChange' option instead if you prefer to use a callback:
        ```javascript
        otherPicture.guillotine({
          onChange: function(data, action){
            // Do something...
          }
        });
        ```

6.  Enjoy!


API
---
Once instantiated, you can interact with the plugin by passing instructions as strings.
Here is the complete **public API**:

```javascript
// Transformations
// rotateLeft, rotateRight, center, fit, zoomIn, zoomOut
picture.guillotine('zoomOut');
picture.guillotine('rotateRight');
...

// Get current data
// { scale: 1.4, angle: 270, x: 10, y: 20, w: 400, h: 300 }
var data = picture.guillotine('getData');

// Get instance (Guillotine instance)
var guillotine = picture.guillotine('instance');

// Disable/Enable the plugin
picture.guillotine('disable');
picture.guillotine('enable');

// Remove the plugin (reset everything)
picture.guillotine('remove');

```

Optionally, you can set the initial position and state of the image with the
**init** option. It takes a data object similar to the one returned by *getData*.
You may set *angle*, *scale*, *x* and *y*, any other property will be ignored:
```javascript
picture.guillotine({
  width: 400,
  height: 300,
  init: { angle: 90, x: 80 }
});

```

For further info and options dig through the [code base] (src/jquery.guillotine.coffee)
that has a fair share of comments and it's intentionally coded in CoffeScript
to ease out reading and customizing it.


Support
-------
* **Dragging** support for both mouse and touch devices (works on IE8).
* **Rotation** is achieved using CSS3 'transform' property, so it doesn't work
  on IE8, but it's automatically disabled on devices that don't support it.
  In such case *rotateLeft* and *rotateRight* won't perform any action but will
  still trigger the event and/or callback to let you know the user is trying and
  allow you to handle it appropriately.
* **Zoom**, **Fit** and **Center** are handled with absolute positioning,
  they work on IE8.

For a more detailed list of supported browsers and devises check out the
[support page](//github.com/matiasgagliano/guillotine/wiki/Support) on the wiki.

It would be great if you could test it on other browsers and devices and share
your experience on the wiki (or open an issue if it doesn't work properly).


License
-------
Guillotine is dual licensed under the MIT or GPLv3 licenses.
* <http://opensource.org/licenses/MIT>
* <http://opensource.org/licenses/GPL-3.0>


More features
-------------
The plugin aims to have a simple and general API to allow interaction, specific
features and the user interface are left for the developer to implement.
This allows the plugin to be as flexible as possible.

For edge cases is that the [code base](src/jquery.guillotine.coffee)
has been kept as maintainable as possible, in those cases you are free and
encouraged to customize the plugin to suite your needs.


Contributing
------------
See [CONTRIBUTING.md](CONTRIBUTING.md)
