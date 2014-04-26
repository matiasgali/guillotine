jQuery Guillotine Plugin
========================

Demo
----
<http://matiasgagliano.github.io/guillotine>


Description
-----------
Guillotine is a jQuery plugin meant to implement image cropping allowing users
to select the area they want by dragging (touch support), rotating or zooming
but with a predefined restriction of size and aspect ratio (cropping window).

The most common use case for this type of cropping is when setting the display
area of an avatar image. The main difference with other implementations is that
this one supports rotation.

*(2.8kb minified and gziped)*


Setup
-----
1.  Load the required files (**jquery.js** and **jquery.guillotine.js**).

2.  Instantiate the plugin:
    ```javascript
    var picture = $('#thepicture');  // Must be already loaded or cached!
    picture.guillotine();
    ```

3.  Bind actions:
    ```javascript
    $('#rotate-left-button').click(function(){
      picture.guillotine('rotateLeft');
    });

    $('#zoom-in-button').click(function(){
      picture.guillotine('zoomIn');
    });

    ...
    ```

4.  Handle cropping instructions:

    The plugin is not meant to actually crop images but to generate the
    necessary instructions to do so on the server.

    *   You can get the instructions at any point by calling:
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
          // action = drag/rotateLeft/rotateRight/center/fit/zoomIn/zoomOut
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

5.  Enjoy!


For further info and options dig through the [code base] (src/jquery.guillotine.coffee)
that has a fair share of comments and it's intentionally coded in CoffeScript
to ease out reading and customizing it.


Support
-------
* **Dragging** support for both mouse and touch devices (works on IE8).
* **Rotation** is achieved using CSS3 'transform' property, so it doesn't work
  on IE8, but it's automatically disabled on devices that don't support it.
  The actions *rotateLeft* and *rotateRight* would just return instantly,
  without issuing any error or exception.
* **Zoom**, **Fit** and **Center** are handled with absolute positioning,
  they work on IE8.

The pluging has been tested only on modern versions of Firefox and Chrome
(Linux), IE8 (WinXP) and Firefox mobile and Dolphin Browser (Android 4.0.4).

It would be great if you could test it on other devices and let me know if it
works so I can notify it here.


License
-------
Guillotine is dual licensed under the MIT or GPLv3 licenses.
* <http://opensource.org/licenses/MIT>
* <http://opensource.org/licenses/GPL-3.0>


More features
-------------
The plugin aims to have a simple and general API to allow interaction, specific
features and user interface are left for the developer to implement.
This allows the plugin to be as flexible as possible.

If you find bugs or quirks that are not oddly specific I'll be happy to hear
about them, but for edge cases is that the [code base] (src/jquery.guillotine.coffee)
has been keept as manteinable as possible, in those cases you are free and
encouraged to customize the plugin to suite your needs.
