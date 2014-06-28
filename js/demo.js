jQuery(function() {
  var picture = $('#sample_picture');
  picture.on('load', function(){
    // Initialize plugin (with custom event)
    picture.guillotine({eventOnChange: 'guillotinechange'});


    // Display inital data
    var data = picture.guillotine('getData');
    for(var k in data) { $('#'+k).html(data[k]); }


    // Bind actions
    $('#rotate_left').click(function(e){
      e.preventDefault();
      picture.guillotine('rotateLeft');
    });

    $('#rotate_right').click(function(e){
      e.preventDefault();
      picture.guillotine('rotateRight');
    });

    $('#fit').click(function(e){
      e.preventDefault();
      picture.guillotine('fit');
    });

    $('#zoom_in').click(function(e){
      e.preventDefault();
      picture.guillotine('zoomIn');
    });

    $('#zoom_out').click(function(e){
      e.preventDefault();
      picture.guillotine('zoomOut');
    });


    // Update data on change
    picture.on('guillotinechange', function(ev, data, action) {
      data.scale = parseFloat(data.scale.toFixed(4));
      for(var k in data) { $('#'+k).html(data[k]); }
    });
  });
});
