jQuery Guillotine Plugin
========================

Demo
----
<http://matiasgagliano.github.io/guillotine>


Description
-----------
Guillotine is a jQuery plugin meant to implement image cropping.
The developer sets a restriction of width an height and the user can
select the area she wants by rotating, zooming or dragging the image within
a window (restriction).

A common example is selecting the display area of an avatar image, the main
difference with other implementations is that this one supports zoom and rotation.

* **Responsive:** The window (or selection area) is fully responsive (fluid).
* **Touch support:** Dragging the image also works on touch devices.

*(2.9kb minified and gziped)*


Setup
-----
1.  Load the required files (**jquery.js** and **jquery.guillotine.js**).

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

    Here we set the dimentions we want for the cropped image (400x300), which
    are totally independent of the size in wich the "guillotine" or "window"
    is actually displayed on screen.

    Even though it's responsive, the data returned always corresponds to the
    predefined dimentions. In this case will always get a cropped image of
    400 by 300 pixels.

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

6.  Enjoy!


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
your experience so it ends up on the wiki.


License
-------
Guillotine is dual licensed under the MIT or GPLv3 licenses.
* <http://opensource.org/licenses/MIT>
* <http://opensource.org/licenses/GPL-3.0>

If you feel like it, it would be enough compensation to just provide a link to
your implementation to add it on the wiki with other sites, projects or
resources that are succesfully using the plugin.


More features
-------------
The plugin aims to have a simple and general API to allow interaction, specific
features and the user interface are left for the developer to implement.
This allows the plugin to be as flexible as possible.

If you find bugs or quirks that are not oddly specific I'll be happy to hear
about them, but for edge cases is that the [code base] (src/jquery.guillotine.coffee)
has been keept as manteinable as possible, in those cases you are free and
encouraged to customize the plugin to suite your needs.
