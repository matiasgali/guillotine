jQuery(function() {
  var picture = $('#sample_picture')

  // Convert string to camel case
  var camelize = function() {
    var regex = /[\W_]+(.)/g
    var replacer = function (match, submatch) { return submatch.toUpperCase() }
    return function (str) { return str.replace(regex, replacer) }
  }()

  // Init Guillotine after the image is loaded
  picture.on('load', function() {
    picture.guillotine({ eventOnChange: 'guillotinechange' })
    picture.guillotine('fit')
    for (var i=0; i<5; i++) { picture.guillotine('zoomIn') }

    // Display inital data
    var data = picture.guillotine('getData')
    for (var k in data) { $('#'+k).html(data[k]) }

    // Bind actions
    $('#controls a').click(function(e) {
      e.preventDefault()
      action = camelize(this.id)
      picture.guillotine(action)
    })

    // Update data on change
    picture.on('guillotinechange', function(ev, data, action) {
      data.scale = parseFloat(data.scale.toFixed(4))
      for(var k in data) { $('#'+k).html(data[k]) }
    })
  })

  // Display random picture
  picture.attr('src', 'img/unsplash.com_' + Math.ceil(Math.random() * 25) + '.jpg')
})
