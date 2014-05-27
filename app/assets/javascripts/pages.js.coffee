$(document).one "pagecreate", ".matchday-page", ->

  # Handler for navigating to the next page
  navnext = (next) ->
    $(":mobile-pagecontainer").pagecontainer "change", next,
      transition: "slide"
    return

  # Handler for navigating to the previous page
  navprev = (prev) ->
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
    navnext next  if next and (event.target is $(this)[0])
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
    navprev prev  if prev and (event.target is $(this)[0])
    return

  $(document).on "click", ".prev", ->
    prev = $(".ui-page-active").jqmData("prev")
    navprev prev  if prev
    return

  return