module ApplicationHelper
  def ui_list(collection, options={}, &block)
    content_tag(:ul, {
        'data-role' => 'listview',
        'data-inset' => 'true'
    }) do
      header = if options[:header]
                 content_tag(:li, {
                     'data-role' => 'list-divider',
                     'data-theme' => 'a',
                     'data-form' => 'ui-bar-a',
                     'role' => 'heading'
                 }) { content_tag :div, options[:header], class: %w(big center) }
               else
                 ''
               end
      spacer = if options[:spacer]
               else
                 ''
               end
      footer = if options[:footer]
               else
                 ''
               end

      header + spacer + collection.collect { |item| content_tag(:li, {
          'data-theme' => 'a'
      }) { yield(item) } }.join.html_safe + footer
    end
  end

  def ui_list_link_to(name = nil, options = nil, html_options = {}, &block)
    link_to name, options, {'class' => %w(ui-btn-a ui-btn ui-btn-icon-right ui-icon-carat-r),
                            'data-form' => 'ui-btn-up-a'}.merge(html_options), &block
  end

  def lorem_img
    'http://lorempixel.com/400/200/cats/'
  end
end
