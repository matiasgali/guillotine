###
 * jQuery Guillotine Plugin v1.1.0
 * http://matiasgagliano.github.com/guillotine/
 *
 * Copyright 2014, Matías Gagliano.
 * Dual licensed under the MIT or GPLv3 licenses.
 * http://opensource.org/licenses/MIT
 * http://opensource.org/licenses/GPL-3.0
 *
###
"use strict"

# ______________________________
#
#           Constants
# ______________________________
#
$ = jQuery
pluginName = 'guillotine'
scope = 'guillotine'

events =
  start: "MSPointerDown.#{scope} touchstart.#{scope} mousedown.#{scope}"
  move:  "MSPointerMove.#{scope} touchmove.#{scope} mousemove.#{scope}"
  stop:  "MSPointerUp.#{scope} touchend.#{scope} mouseup.#{scope}"

defaults =
  width: 400
  height: 300
  zoomStep: 0.1
  eventOnChange: null
    # Event to be triggered after each change (drag, rotate, etc.).
    # E.g. 'transform.guillotine' or 'guillotinechange'
    # The event handler function gets the same arguments and scope as the callback.
    # E.g. (ev, data, action) -> // Do something...
  onChange: null
    # Callback function to be called after each change (drag, rotate, etc.)
    # E.g. (data, action) -> if action == 'rotateLeft' then log(data.angle)
    # 'this' = current element
    # 'data' = { scale: 1.4, angle: 270, x: 10, y: 20, w: 400, h: 300 }
    # 'action' = drag/rotateLeft/rotateRight/center/fit/zoomIn/zoomOut



# ______________________________
#
#             Helpers
# ______________________________
#

# isTouch()
#   Is the event a touch event?
isTouch = (e) -> e.type.search('touch') > -1


# isPointerEventCompatible()
#   Is the device pointer event compatible?
#   (typically means a touch Win8 device)
isPointerEventCompatible = -> ('MSPointerEvent' in window)


# validEvent(event)
#   Whether the event is a valid action to start dragging or not.
#   Override the function so it checks display type only the first time.
validEvent = (e) ->
  if isPointerEventCompatible() or !isTouch(e)
    # Left click only
    validEvent = (e) -> e.which? and e.which is 1
  else
    # Single touch only
    validEvent = -> e.originalEvent?.touches?.length == 1
  validEvent(e)


# getCursorPosition(event)
#   Get the position of the cursor when the event is triggered.
#   Override the function so it checks display type only the first time.
getCursorPosition = (e) ->
  if isPointerEventCompatible() or !isTouch(e)
    getCursorPosition = (e) ->
      { x: e.pageX, y: e.pageY }
  else
    getCursorPosition = (e) ->
      e = e.originalEvent.touches[0]
      { x: e.pageX, y: e.pageY }
  getCursorPosition(e)


# canTransform()
#   Whether CSS3 'transform' is supported or not.
#   Override the function so it checks support just once.
canTransform = ->
  hasTransform = false
  prefixes = 'webkit,Moz,O,ms,Khtml'.split(',')
  tests = { transform: 'transform' }
  for prefix in prefixes
    tests[prefix+'Transform'] = "-#{prefix.toLowerCase()}-transform"

  # Create a helper element and add it to the body to get the computed style.
  helper = document.createElement('img')
  document.body.insertBefore(helper, null)

  for test,prop of tests
    continue if helper.style[test] is undefined
    helper.style[test] = 'rotate(90deg)'
    value = window.getComputedStyle(helper).getPropertyValue(prop)
    if value? and value.length and value isnt 'none'
      hasTransform = true; break

  document.body.removeChild(helper)
  if hasTransform
    canTransform = -> true
  else
    canTransform = -> false
  canTransform()


# hardwareAccelerate(element)
#   Force CSS3 hardware acceleration.
hardwareAccelerate = (el) ->
  $(el).css
    '-webkit-perspective':          1000
    'perspective':                  1000
    '-webkit-backface-visibility':  'hidden'
    'backface-visibility':          'hidden'


# ______________________________
#
#        The "Guillotine"
# ______________________________
#
class Guillotine
  constructor: (element, options) ->
    # Build options
    # The data attribute override options, and options override defaults.
    # ( data-guillotine='{"width": 640, "height": 480}' )
    @op = $.extend true, {}, defaults, options, $(element).data(pluginName)

    # Cache
    @enabled = true
    @zoomInFactor = 1 + @op.zoomStep
    @zoomOutFactor = 1 / @zoomInFactor
    [@width, @height, @left, @top, @angle] = [0, 0, 0, 0, 0]

    # Transformation instructions
    @data = {scale: 1, angle: 0, x: 0, y: 0, w: @op.width, h: @op.height}

    # Markup
    @_wrap(element)
    @_fit() and @_center() if @width < 1 or @height < 1
    hardwareAccelerate(@$el)

    # Events
    @$el.on events.start, @_start


  # _____ Private _____
  #

  # Wrap element with the necesary markup
  _wrap: (element) =>
    el = $(element)

    # Get image's real dimensions
    if el.prop('tagName') is 'IMG'
      # Helper image (full size image)
      # Assumes the target image already existed and that it's cached.
      # It's up to the user to instantiate the plugin after the target is loaded.
      img = document.createElement('img')
      img.setAttribute('src', el.attr('src'))
      # Notice: width and height properties hold the dimensions even
      # though the image hasn't been rendered or appended to the DOM.
      [width, height] = [img.width, img.height]
    else
      # In case of mad experiments (SVGs, canvas, etc.).
      [width, height] = [el.width(), el.height()]

    # Canvas
    ## Fullsize image dimensions relative to the restrictions.
    [@width, @height] = [width/@op.width, height/@op.height]
    canvas = $('<div>').addClass('guillotine-canvas')
    canvas.css width: @width*100+'%', height: @height*100+'%', top: 0, left: 0
    canvas = el.wrap(canvas).parent()

    # Guillotine (window)
    ## Responsive with fixed aspect ratio.
    ## ('padding-top' as a percentage refers to the WIDTH of the containing block)
    paddingTop = @op.height/@op.width * 100 + '%'
    guillotine = $('<div>').addClass('guillotine-window')
    guillotine.css width: '100%', height: 'auto', 'padding-top': paddingTop
    guillotine = canvas.wrap(guillotine).parent()

    # Cache (DOM objects and their jQuery equivalents)
    @$el = el; @el = el[0]
    @$canvas = canvas; @canvas = canvas[0]
    @$gllt = guillotine; @gllt = guillotine[0]
    @$document = $(element.ownerDocument)


  # Back to original state
  _unwrap: =>
    @$el.removeAttr 'style'
    @$el.insertBefore @gllt
    @$gllt.remove()


  _start: (e) =>
    return unless @enabled and validEvent(e)
    e.preventDefault()
    e.stopImmediatePropagation()
    @p = getCursorPosition(e)         # Cursor position before moving (dragging)
    @_bind()


  _bind: =>
    @$document.on events.move, @_drag
    @$document.on events.stop, @_unbind


  _unbind: (e) =>
    @$document.off events.move, @_drag
    @$document.off events.stop, @_unbind  # Unbind this very function (handler)
    @_trigger('drag') if e?


  # Trigger event and/or call callback function
  _trigger: (action) =>
    @$el.trigger @op.eventOnChange, [@data, action] if @op.eventOnChange?
    @op.onChange.call(@el, @data, action) if typeof @op.onChange is 'function'


  _drag: (e) =>
    e.preventDefault()
    e.stopImmediatePropagation()

    p = getCursorPosition(e)           # Cursor position after moving
    dx = p.x - @p.x                    # Difference (cursor movement) on X axes
    dy = p.y - @p.y                    # Difference (cursor movement) on Y axes
    @p = p                             # Update cursor position

    # When dragging it isn't crucial to avoid every malformed 'top' or 'left'
    # styles caused by scientific notation on @left or @top.
    # Not using 'toFixed' here to make dragging as fast as possible.

    if dx != 0
      dx = dx / @gllt.clientWidth      # dx relative to the width of the window
      if dx > 0                        # If moving right
        dx = -@left if dx > -@left
      else                             # If moving left (dx < 0)
        right = -(@width+@left-1)      # Right margin (%)
        dx = right if dx < right
      @left += dx
      @canvas.style.left = @left * 100 + '%'
      @data.x = Math.round -@left * @op.width

    if dy != 0
      dy = dy / @gllt.clientHeight     # dy relative to the height of the window
      if dy > 0                        # If moving down
        dy = -@top if dy > -@top
      else                             # If moving up (dy < 0)
        bottom = -(@height+@top-1)     # Bottom margin (%)
        dy = bottom if dy < bottom
      @top += dy
      @canvas.style.top = @top * 100 + '%'
      @data.y = Math.round -@top * @op.height


  _zoom: (factor) =>
    return if factor <= 0 or factor == 1
    [w, h] = [@width, @height]

    # Zoom
    if w * factor > 1 and h * factor > 1
      @width *= factor
      @height *= factor
      # (use toFixed to prevent scientific notation on the strings)
      @canvas.style.width = (@width * 100).toFixed(2) + '%'
      @canvas.style.height = (@height * 100).toFixed(2) + '%'
      @data.scale *= factor
    else
      @_fit()
      factor = @width / w

    # Keep same center when possible
    @left -= w*(factor-1)/2                             # Same horizontal center
    @left  = 1 - @width       if @left + @width < 1     # Keep on right edge
    @left  = 0                if @left > 0              # Keep on left edge
    @top  -= h*(factor-1)/2                             # Same vertical center
    @top   = 1 - @height      if @top + @height < 1     # Keep on bottom edge
    @top   = 0                if @top > 0               # Keep on top edge

    # (use toFixed to prevent scientific notation on the strings)
    @canvas.style.left = (@left * 100).toFixed(2) + '%'
    @canvas.style.top = (@top * 100).toFixed(2) + '%'
    @data.x = Math.round -@left * @op.width
    @data.y = Math.round -@top * @op.height


  # Adjast the element (canvas) to the edges of the window keeping aspect ratio.
  _fit: =>
    prevWidth = @width
    relativeRatio = @height / @width
    if relativeRatio > 1                      # => canvasH/canvasW > glltH/glltW
      @width = 1
      @height = relativeRatio
    else
      @width = 1 / relativeRatio
      @height = 1
    # (use toFixed to prevent scientific notation on the strings)
    @canvas.style.width = (@width * 100).toFixed(2) + '%'
    @canvas.style.height = (@height * 100).toFixed(2) + '%'
    @data.scale *= @width / prevWidth


  _center: =>
    @left = (1 - @width) / 2
    @top  = (1 - @height) / 2
    # (use toFixed to prevent scientific notation on the strings)
    @canvas.style.left = (@left * 100).toFixed(2) + '%'
    @canvas.style.top = (@top * 100).toFixed(2) + '%'
    @data.x = Math.round -@left * @op.width
    @data.y = Math.round -@top * @op.height


  _rotate: (angle) =>
    return unless canTransform() and angle % 90 is 0

    # Smallest positive equivalent angle (total rotation)
    @angle = (@angle + angle) % 360
    @angle = 360 + @angle if @angle < 0

    # Different dimensions?
    if (angle % 180 isnt 0)
      # Switch canvas dimensions (as percentages)
      #
      # canvasWidth = @width * glltWidth; canvasHeight = @height * glltHeigth
      # To make canvasWidth = canvasHeight (to switch dimensions):
      # => newWidth * glltWidth = @height * glltHeight
      # => newWidth = @height * glltHeight / glltWidth
      # => newWidth = @height * glltRatio
      #
      glltRatio = @op.height / @op.width
      [@width, @height] = [@height * glltRatio, @width / glltRatio]
      if @width >= 1 and @height >= 1
        @canvas.style.width = @width * 100 + '%'
        @canvas.style.height = @height * 100 + '%'
      else
        @_fit()

    # Adjast element's (image) dimensions inside the canvas
    [w, h] = [1, 1]
    if (@angle % 180 isnt 0)
      canvasRatio = @height / @width * glltRatio
      [w, h] = [canvasRatio, 1 / canvasRatio]
    @el.style.width = w * 100 + '%'
    @el.style.height = h * 100 + '%'
    @el.style.left = (1 - w) / 2 * 100 + '%'
    @el.style.top = (1 - h) / 2 * 100 + '%'

    # Rotate
    @$el.css transform: "rotate(#{@angle}deg)"
    @_center()
    @data.angle = @angle


  # _____ Public (The API) _____
  #

  # Actions
  rotateLeft:  => @enabled and (@_rotate(-90);          @_trigger('rotateLeft'))
  rotateRight: => @enabled and (@_rotate(90);           @_trigger('rotateRight'))
  center:      => @enabled and (@_center();             @_trigger('center'))
  fit:         => @enabled and (@_fit(); @_center();    @_trigger('fit'))
  zoomIn:      => @enabled and (@_zoom(@zoomInFactor);  @_trigger('zoomIn'))
  zoomOut:     => @enabled and (@_zoom(@zoomOutFactor); @_trigger('zoomOut'))

  # Utilities
  getData: => @data
  enable:  => @enabled = true
  disable: => @enabled = false



# ______________________________
#
#           The Plugin
# ______________________________
#
$.fn[pluginName] = (options) ->

  # Plug it! Lightweight plugin wrapper around the constructor.
  if typeof options isnt 'string'
    @each ->
      # Prevent multiple instantiation
      unless $.data(@, pluginName + 'Instance')
        # Guillotine's instance
        guillotine = new Guillotine(@, options)
        $.data(@, pluginName + 'Instance', guillotine)


  # Plugin's API
  else
    switch method = options
      # Return guillotine's instance for the first element
      when 'instance'
        $.data(@[0], pluginName + 'Instance')

      # Remove plugin for each element
      when 'remove'
        @each ->
          guillotine = $.data(@, pluginName + 'Instance')
          return unless guillotine?
          guillotine._unbind()
          guillotine._unwrap()
          guillotine.disable()
          guillotine.$el.off events.start, guillotine._start
          guillotine.$el.removeData(pluginName + 'Instance')

      # Return data (coords, angle, scale) for the first element
      when 'getData'
        $.data(@[0], pluginName + 'Instance')?['getData'].call()

      # Use Guillotine's API through the plugin
      # E.g. element.guillotine('rotateLeft')
      when 'rotateLeft','rotateRight','center','fit', \
           'zoomIn','zoomOut', 'enable', 'disable'
        @each ->
          guillotine = $.data(@, pluginName + 'Instance')
          return unless guillotine?
          guillotine[method].call()
