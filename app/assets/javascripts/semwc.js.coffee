@Semwc =
  selectFilterType: (type) ->
    $(".select-value").hide()
    $("#select-value-#{type}").show()

  selectFilterValue: (value) ->
    console.log(value)
    return