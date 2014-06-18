@Semwc =
  selectFilterType: (type) ->
    $(".select-value").hide()
    $("#select-filter-type option[value='#{type}']").attr("selected", true)
    $("#select-value-#{type}").show()
    return

  selectFilterValue: (value) ->
    console.log(value)
    return