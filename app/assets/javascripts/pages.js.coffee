# Pagecreate will fire for each of the pages in this demo
# but we only need to bind once so we use "one()"
$(document).one "pagecreate", ".matchday-page", ->

  # Initialize the external persistent header and footer
  #$("#header").toolbar({ theme: "b" });
  #$("#footer").toolbar({ theme: "b" });
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

$(document).on "pageshow", ".demo-page", ->
  thePage = $(this)
  title = thePage.jqmData("title")
  next = thePage.jqmData("next")
  prev = thePage.jqmData("prev")

  # Point the "Trivia" button to the popup for the current page.
  #$("#trivia-button").attr("href", "#" + thePage.find(".trivia").attr("id"));
  # We use the same header on each page
  # so we have to update the title
  #$("#header h1").text(title);
  # Prefetch the next page
  # We added data-dom-cache="true" to the page so it won't be deleted
  # so there is no need to prefetch it
  $(":mobile-pagecontainer").pagecontainer "load", next  if next

  # We disable the next or previous buttons in the footer
  # if there is no next or previous page
  # We use the same footer on each page
  # so first we remove the disabled class if it is there
  $(".next.ui-state-disabled, .prev.ui-state-disabled").removeClass "ui-state-disabled"
  $(".next").addClass "ui-state-disabled"  unless next
  $(".prev").addClass "ui-state-disabled"  unless prev
  return
