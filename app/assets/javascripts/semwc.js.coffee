@Semwc =
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
    window.location.href = newHref
    return