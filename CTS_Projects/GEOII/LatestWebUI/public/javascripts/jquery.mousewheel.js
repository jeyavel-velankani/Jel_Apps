/**
 * jQuery WheelEvent Plugin
 * Add cross-browser support mouse wheel event
 *
 * Copyright 2013, Vladimir Shelmuk
 * Licensed under the MIT license
 *
 * Based on: https://developer.mozilla.org/en-US/docs/Mozilla_event_reference/wheel
 *
 * */

!function($) {
    var eventProps = ["deltaX", "deltaY", "deltaZ", "deltaMode"],
        wheelEvents,
        onEvents;

    // Add W3C-property to jQuery object
    $.event.fixHooks.wheel = {
        props: eventProps
    };

    // End if browser support wheel event
    if ('onwheel' in document) return;

    // Alternative events
    wheelEvents = ['mousewheel', 'MozMousePixelScroll'];

    $.event.special.wheel = {
        // jQuery call this hook when .on('wheel) adding
        add: function(handleObj) {

            onEvents = wheelEvents.concat(' ').join('.wheel ');

            $(this).on(onEvents, function(event){
                event = normalizeEvent(event);
                return handleObj.handler.call(this, event);
            });

            // Normalize property and add to jQuery object
            function normalizeEvent(event) {
                var originalEvent = event.originalEvent;

                $.each(eventProps, function(index, prop) {
                    event[prop] = 0;
                });

                if (originalEvent.wheelDelta) {
                    event.deltaY = - 1/40 * originalEvent.wheelDelta;

                    // Webkit also support wheelDeltaX
                    originalEvent.wheelDeltaX && ( event.deltaX = - 1/40 * originalEvent.wheelDeltaX );

                    // All browser return delta in line (only event 'MozMousePixelScroll' return pixel value)
                    event.deltaMode = 1;
                } else if (originalEvent.detail) {
                    event.deltaY = originalEvent.detail;
                }

                return event;
            }
        },
        remove: function() {
            $(this).off('.wheel');
        }
    };

    $.fn.wheel = function(fn) {
        return this.on('wheel', fn);
    }
}(jQuery);