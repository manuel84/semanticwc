@Semwc =
  getSelectionText: ->
    if window.getSelection
      window.getSelection().toString()
    else if document.selection and document.selection.type isnt "Control"
      document.selection.createRange().text
    else
      ""

  selectFilterType: (type) ->
    $(".select-value").hide()
    $("#select-filter-type option[value='#{type}']").attr("selected", true)
    $("#select-value-#{type}").show()
    return

  selectFilterValue: (value) ->
    window.location.getParameter('onlyforbuildobject')
    queryParams = jQuery.extend(true, {}, window.location.queryStringParams) #clone
    queryParams['filter_uri'] = value
    queryParamsArr = $.map(queryParams, (v, key) ->
      return "#{key}=#{v}"
    )
    newHref = window.location.origin + window.location.pathname + "?" + queryParamsArr.join("&")
    $("#close-button").click()
    $.mobile.loading('show', {
      text: '',
      textVisible: '',
      textonly: false,
      html: ''
    });
    window.location.href = newHref
    return

  goToAll: (value) ->
    if(value == 'none')
      $("#close-button").click()
      $.mobile.loading('show', {
        text: '',
        textVisible: '',
        textonly: false,
        html: ''
      });
      window.location.href = '/'
    return

  initPage: () ->
    if $('.matches').is(':visible')
      $("#filter-icon").fadeIn()
    else
      $("#filter-icon").fadeOut()
    setTimeout(Semwc.initPage, 2000)
    return