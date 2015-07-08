###
 * jQuery Guillotine Plugin v1.3.1
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
  start: "touchstart.#{scope} mousedown.#{scope}"
  move:  "touchmove.#{scope} mousemove.#{scope}"
  stop:  "touchend.#{scope} mouseup.#{scope}"

defaults =
  width: 400
  height: 300
  zoomStep: 0.1
  init: null
    # Initial state and position
    # E.g. {x: 0, y: 0, angle: 0, scale: 1}
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

# isTouch(event)
#   Is the event a touch event?
touchRegExp = /touch/i
isTouch = (e) -> touchRegExp.test(e.type)


# validEvent(event)
#   Whether the event is a valid action to start dragging or not.
validEvent = (e) ->
  if isTouch(e)
    e.originalEvent.changedTouches.length is 1   # Single touch only
  else
    e.which is 1                                 # Left click only


# getPointerPosition(event)
#   Get the position of the pointer (cursor, etc.) when the event is triggered.
getPointerPosition = (e) ->
  e = e.originalEvent.touches[0] if isTouch(e)
  { x: e.pageX, y: e.pageY }


# canTransform()
#   Whether CSS3 'transform' is supported or not.
#   Override the function so it checks support just once.
canTransform = ->
  hasTransform = false
  prefixes = ['webkit', 'Moz', 'O', 'ms', 'Khtml']
  tests = { transform: 'transform' }
  for prefix in prefixes
    tests[prefix + 'Transform'] = '-' + prefix.toLowerCase() + '-transform'

  # Create a helper element and add it to the body to get the computed style.
  helper = document.createElement('img')
  document.body.insertBefore(helper, null)

  for test,prop of tests
    continue if helper.style[test] is undefined
    helper.style[test] = 'rotate(90deg)'
    value = window.getComputedStyle(helper).getPropertyValue(prop)
    if value? and value.length and value isnt 'none'
      hasTransform = true
      break

  document.body.removeChild(helper)
  canTransform = if hasTransform then (-> true) else (-> false)
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
    # The data attribute overrides options, and options override defaults.
    # ( data-guillotine='{"width": 640, "height": 480}' )
    @op = $.extend true, {}, defaults, options, $(element).data(pluginName)

    # Cache
    @enabled = true
    @zoomInFactor = 1 + @op.zoomStep
    @zoomOutFactor = 1 / @zoomInFactor
    @glltRatio = @op.height / @op.width
    @width = @height = @left = @top = @angle = 0

    # Transformation instructions
    @data = { scale: 1, angle: 0, x: 0, y: 0, w: @op.width, h: @op.height }

    # Markup
    @_wrap(element)
    @_init() if @op.init?
    @_fit() and @_center() if @width < 1 or @height < 1  # 1 means 100%
    hardwareAccelerate(@$el)

    # Events
    @$el.on events.start, @_start


  # _____ Private _____
  #

  # Wrap element with the necesary markup
  _wrap: (element) ->
    el = $(element)

    # Get image's real dimensions
    if element.tagName is 'IMG'
      if element.naturalWidth
        width  = element.naturalWidth
        height = element.naturalHeight
      else
        el.addClass('guillotine-sample')
        width = el.width(); height = el.height()
        el.removeClass('guillotine-sample')
    else
      # In case of mad experiments (SVGs, canvas, etc.).
      width = el.width(); height = el.height()

    # Canvas
    ## Fullsize image dimensions relative to the restrictions.
    @width = width/@op.width
    @height= height/@op.height
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
    @$body = $('body', @$document)


  # Back to original state
  _unwrap: ->
    @$el.removeAttr 'style'
    @$el.insertBefore @gllt
    @$gllt.remove()


  # Initial state and position
  _init: ->
    o = @op.init
    @_zoom   scale  if ( scale = parseFloat(o.scale) )
    @_rotate angle  if ( angle = parseInt(o.angle) )
    @_offset parseInt(o.x)/@op.width || 0, parseInt(o.y)/@op.height || 0


  # On starting event (events.start)
  # Bind event handlers to self using '=>', prevents jQuery from setting 'this'.
  _start: (e) =>
    return unless @enabled and validEvent(e)
    e.preventDefault()
    e.stopImmediatePropagation()
    @p = getPointerPosition(e)        # Cursor position before moving (dragging)
    @_bind()


  _bind: ->
    @$body.addClass('guillotine-dragging')
    @$document.on events.move, @_drag
    @$document.on events.stop, @_unbind


  # Bind event handlers to self using '=>', prevents jQuery from setting 'this'.
  _unbind: (e) =>
    @$body.removeClass('guillotine-dragging')
    @$document.off events.move, @_drag
    @$document.off events.stop, @_unbind   # Unbind this very function (handler)
    @_trigger('drag') if e?


  # Trigger event and/or call callback function
  _trigger: (action) ->
    @$el.trigger @op.eventOnChange, [@data, action] if @op.eventOnChange?
    @op.onChange.call(@el, @data, action) if typeof @op.onChange is 'function'


  _drag: (e) =>
    e.preventDefault()
    e.stopImmediatePropagation()

    p = getPointerPosition(e)           # Cursor position after moving
    dx = p.x - @p.x                     # Difference (cursor movement) on X axes
    dy = p.y - @p.y                     # Difference (cursor movement) on Y axes
    @p = p                              # Update cursor position

    # dx > 0 if moving right
    # dx/clientWidth is the percentage of the window's width it moved over x
    left = if  dx == 0  then  null  else  @left - dx/@gllt.clientWidth

    # dy > 0 if moving down
    # dy/clientHeight is the percentage of the window's height it moved over y
    top  = if  dy == 0  then  null  else  @top - dy/@gllt.clientHeight

    # Move
    @_offset left, top


  _offset: (left, top) ->                # left and top are relative numbers!
    # Offset left
    if left || left == 0                 # 0 is falsy
      left = 0 if left < 0
      left = @width-1 if left > @width-1
      # (toFixed avoids scientific notation)
      @canvas.style.left = (-left * 100).toFixed(2) + '%'
      @left = left
      @data.x = Math.round left * @op.width

    # Offset top
    if top || top == 0
      top = 0 if top < 0
      top = @height-1 if top > @height-1
      # (toFixed avoids scientific notation)
      @canvas.style.top = (-top * 100).toFixed(2) + '%'
      @top = top
      @data.y = Math.round top * @op.height


  _zoom: (factor) ->
    return if factor <= 0 or factor == 1
    w = @width; h = @height

    # Zoom
    if w * factor > 1 and h * factor > 1
      @width  *= factor
      @height *= factor
      # (toFixed avoids scientific notation)
      @canvas.style.width  = (@width * 100).toFixed(2) + '%'
      @canvas.style.height = (@height * 100).toFixed(2) + '%'
      @data.scale *= factor
    else
      @_fit()
      factor = @width / w

    # Keep window center.
    #
    # The offsets are the distances between the image point in the center of
    # the window and each edge of the image, less half the size of the window.
    # Percentage offsets are relative to the container (the window), so half
    # the window is 50% (0.5) and when zooming the distance between any two
    # points in the image grows by 'factor', so the new offsets are:
    #
    # offset = (prev-center-to-edge) * factor - half-window
    #
    left = (@left + 0.5) * factor - 0.5
    top  = (@top + 0.5) * factor - 0.5
    @_offset left, top


  # Adjust the element (canvas) to the edges of the window keeping aspect ratio.
  _fit: ->
    prevWidth = @width
    relativeRatio = @height / @width
    if relativeRatio > 1                      # => canvasH/canvasW > glltH/glltW
      @width = 1
      @height = relativeRatio
    else
      @width = 1 / relativeRatio
      @height = 1
    # (toFixed avoids scientific notation)
    @canvas.style.width  = (@width * 100).toFixed(2) + '%'
    @canvas.style.height = (@height * 100).toFixed(2) + '%'
    @data.scale *= @width / prevWidth


  _center: -> @_offset (@width-1)/2, (@height-1)/2


  _rotate: (angle) ->
    return unless canTransform()
    return unless angle isnt 0 and angle % 90 is 0

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

    # Adjust element's (image) dimensions inside the canvas
    [w, h] = [1, 1]
    if (@angle % 180 isnt 0)
      canvasRatio = @height / @width * glltRatio
      [w, h] = [canvasRatio, 1 / canvasRatio]
    @el.style.width = w * 100 + '%'
    @el.style.height = h * 100 + '%'
    @el.style.left = (1 - w) / 2 * 100 + '%'
    @el.style.top = (1 - h) / 2 * 100 + '%'

    # Rotate
    # Since jQuery 1.8.0 '.css()' adds vendor prefixes
    @$el.css transform: "rotate(#{@angle}deg)"
    @_center()
    @data.angle = @angle


  # _____ Public (The API) _____
  #

  # Actions
  rotateLeft:  -> @enabled and (@_rotate(-90);          @_trigger('rotateLeft'))
  rotateRight: -> @enabled and (@_rotate(90);           @_trigger('rotateRight'))
  center:      -> @enabled and (@_center();             @_trigger('center'))
  fit:         -> @enabled and (@_fit(); @_center();    @_trigger('fit'))
  zoomIn:      -> @enabled and (@_zoom(@zoomInFactor);  @_trigger('zoomIn'))
  zoomOut:     -> @enabled and (@_zoom(@zoomOutFactor); @_trigger('zoomOut'))

  # Utilities
  getData: -> @data
  enable:  -> @enabled = true
  disable: -> @enabled = false
  remove: ->
    @_unbind(); @_unwrap(); @disable()
    @$el.off events.start, @_start
    @$el.removeData(pluginName + 'Instance')



# ______________________________
#
#           The Plugin
# ______________________________
#
whitelist = ['rotateLeft', 'rotateRight', 'center', 'fit', 'zoomIn', 'zoomOut', \
             'instance', 'getData', 'enable', 'disable', 'remove']

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
  # E.g. element.guillotine('rotateLeft')
  else if options in whitelist
    return $.data(@[0], pluginName+'Instance') if options is 'instance'
    return $.data(@[0], pluginName+'Instance')[options]() if options is 'getData'
    @each ->
      guillotine = $.data(@, pluginName + 'Instance')
      guillotine[options]() if guillotine
