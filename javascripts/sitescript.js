$(document).ready( function(){
    var platform;

// A cookie is used to make sure each page uses the same setting.  Whenever the setting changes,
// the cookie is updated. The setting can change through the commandline, radiobutton choice, 
// or dropdown list choice. 


// if commandline has a value, set the cookie 
// note the name of the var is ignored, only the value specified after the "=" is important
if ( window.location.search.split('=')[1]) {
    platform = window.location.search.split('=')[1];
    console.log (" Argument is " + platform )
    // make sure the argument is a valid value  
    if ($.inArray( platform, [ "cig","onp", "hdi" ] ) > -1 ) {
        Cookies.set('platform', platform ); 
    }
}

// Get the cookie.  If no cookie, default to CIG and set the cookie.
    if (Cookies.get('platform')) {
        platform = (Cookies.get('platform'));
        console.log('got the cookie '+ platform )
    } else {
        platform = 'cig';
        Cookies.set('platform', platform );       
    }
    if (Cookies.get('platform') != platform) {
        // if cookies don't work, show the dropdown instead on pages which need it.
        $('.choose').css("display","inline");
    }
 
    // initialize page - sets both radiobutton and dropdown whichever the page uses (or both!)
    setRb ( platform )
    setDl ( platform )
    changeVis( platform )

    //changing the dropdown changes visibility, cookie, and rb
    $('.ch-platform').change(function () {
        var newval = $('.ch-platform option:selected').val();
        changeVis ( newval );
        Cookies.set ('platform', newval )
        setRb ( newval );
    });

    //changing the radiobutton changes visibility, cookie, and dl
    $('input[type=radio][name=optradio]').change(function(){
        changeVis( this.value );
        Cookies.set('platform', this.value );
        setDl ( this.value );
    });

// change visibility of all the appropriate divs on the page 
// note that both cig and onp show the ".sql" div 
    function changeVis (value) {
        switch (value) {
            case 'cig':
                $('.cig').show();
                $('.sql').show();
                $('.onp').hide();
                $('.hdi').hide();
            break;

            case 'onp':
                $('.cig').hide();
                $('.sql').show();
                $('.onp').show();
                $('.hdi').hide();
            break;

            case 'hdi':
                $('.cig').hide();
                $('.sql').hide();
                $('.onp').hide();
                $('.hdi').show();
            break;
        }
    };

// set the rb
    function setRb (value) {
        switch (value) {
            case 'cig':
                $("input[name=optradio][value=cig]").prop("checked",true);
            break;

            case 'onp':
                $("input[name=optradio][value=onp]").prop("checked",true);
            break;

            case 'hdi':
                $("input[name=optradio][value=hdi]").prop("checked",true);
            break;
        }
    };

// set the dl
    function setDl ( value ) {
        $(".ch-platform").val( value ).change();
    };


})

