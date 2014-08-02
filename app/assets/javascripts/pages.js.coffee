$(document).one "pagecreate", ".main-page", ->
  $("#header").toolbar({ theme: "a" })
  $("#footer").toolbar({ theme: "a" })

  # Handler for navigating to the next page
  navnext = (next) ->
    $('#filter-panel').remove()
    $(":mobile-pagecontainer").pagecontainer "change", next,
      transition: "slide"
    return

  # Handler for navigating to the previous page
  navprev = (prev) ->
    $('#filter-panel').remove()
    $(":mobile-pagecontainer").pagecontainer "change", prev,
      transition: "slide"
      reverse: true
    return

  # Navigate to the next page on swipeleft
  $(document).on "swipeleft", ".ui-page", (event) ->

    # Get the filename of the next page. We stored that in the data-next
    # attribute in the original markup.
    next = $(this).jqmData("next")

    # Check if there is a next page and
    # swipes may also happen when the user highlights text, so ignore those.
    # We're only interested in swipes on the page.
    navnext next  if next and Semwc.getSelectionText() == ""
    return


  # Navigate to the next page when the "next" button in the footer is clicked
  $(document).on "click", ".next", ->
    next = $(".ui-page-active").jqmData("next")

    # Check if there is a next page
    navnext next  if next
    return


  # The same for the navigating to the previous page
  $(document).on "swiperight", ".ui-page", (event) ->
    prev = $(this).jqmData("prev")
    if prev == 'back'
      window.history.back()
      return
    navprev prev  if prev and Semwc.getSelectionText() == ""
    return

  $(document).on "click", ".prev", ->
    prev = $(".ui-page-active").jqmData("prev")
    navprev prev  if prev
    return

  return