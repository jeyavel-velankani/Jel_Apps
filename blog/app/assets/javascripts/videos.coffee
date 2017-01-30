# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery(document).on 'turbolinks:load', ->
  ZiggeoApi.Events.on "upload_progress", ( uploaded, total, data ) ->
    $('progress').removeClass('hidden-xs-up').attr 'value', (uploaded / total) * 100