jQuery(function() {
  var picture = $('#sample_picture')

  var camelize = function() {
    var regex = /[\W_]+(.)/g
    var replacer = function (match, submatch) { return submatch.toUpperCase() }
    return function (str) { return str.replace(regex, replacer) }
  }()

  var showData = function (data) {
    data.scale = parseFloat(data.scale.toFixed(4))
    for(var k in data) { $('#'+k).html(data[k]) }
  }

  picture.on('load', function() {
    picture.guillotine({ eventOnChange: 'guillotinechange' })
    picture.guillotine('fit')
    for (var i=0; i<5; i++) { picture.guillotine('zoomIn') }

    // Show controls and data
    $('.loading').remove()
    $('.notice, #controls, #data').removeClass('hidden')
    showData( picture.guillotine('getData') )

    // Bind actions
    $('#controls a').click(function(e) {
      e.preventDefault()
      action = camelize(this.id)
      picture.guillotine(action)
    })

    // Update data on change
    picture.on('guillotinechange', function(e, data, action) { showData(data) })
  })

  // Display random picture
  picture.attr('src', 'img/unsplash.com_' + Math.ceil(Math.random() * 25) + '.jpg')
})
