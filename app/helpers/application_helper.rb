require 'open-uri'

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

  def img_url(sol)
    if sol
      if sol.has_variables?(['wiki_uri'])
        page = page = Nokogiri::HTML(open(sol.wiki_uri))
        img = page.css('.infobox img').first
        img.present? ? img.attributes['src'].value : lorem_img
      else
        if sol.has_variables?(['image_url'])
          sol.image_url if RestClient.get sol.image_url rescue lorem_img
        elsif sol.has_variables?(['thumbnail_url'])
          sol.thumbnail_url
        end
      end
    else
      lorem_img
    end
  end

  def match_name(match)
    "#{match.homeCompetitor} - #{match.awayCompetitor}"
  end

  def capacity(stadium)
    if stadium.has_variables?(['capacity'])
      stadium.capacity
    elsif stadium.has_variables?(['seatingCapacity'])
      stadium.seatingCapacity
    else
      "n.A."
    end
  end

  def get_name(sol)
    return '' unless sol
    if sol.has_variables?(['fullname'])
      sol.fullname.to_s
    elsif sol.has_variables?(['surname', 'givenName'])
      "#{sol.surname} #{sol.givenName}"
    elsif sol.has_variables?(['name'])
      sol.name.to_s
    elsif sol.has_variables?(['label'])
      sol.label.to_s
    elsif sol.has_variables?(['clubname'])
      sol.clubname.to_s
    elsif sol.has_variables?(['altname'])
      sol.clubname.to_s
    else
      ''
    end
  end

  def get_result(match)
    if match.has_variables?(['homeCompetitorGoals', 'awayCompetitorGoals'])
      "#{match.homeCompetitorGoals}:#{match.awayCompetitorGoals}"
    else
      '-:-'
    end
  end

  def img_width
    280
  end

  def get_filter_name(filter_type, filter_value)
    case filter_type
      when 'stadium'
        "Spiele im #{get_name(get_stadium(filter_value))}"
      when 'day'
        "Spiele am #{Date.parse(filter_value).to_s(:short)}"
      when 'group'
        "Spiele aus der Gruppe #{get_name(get_group(filter_value))}"
      when 'team'
        "Spiele von #{get_name(get_team(filter_value))}"
      else
        'alle Spiele'
    end
  end

  def get_goal_infos(goals, matchday)
    home_player_uris = get_players_for_team(matchday.homeCompetitor_uri).map { |player| player.uri.to_s }
    #away_player_uris = get_players_for_team(matchday.awayCompetitor_uri).map { |player| player.uri.to_s }
    result= [0, 0]
    result = @goals.map do |goal|
      txt = "#{goal.time}' #{goal.player}"
      i = case goal.factor.to_s
            when 'goal'
              i = home_player_uris.include?(goal.player_uri.to_s) ? 0 : 1
              result[i]+=1
              "#{txt} (#{result[0]}:#{result[1]})"
            when 'goal-penalty'
              i = home_player_uris.include?(goal.player_uri.to_s) ? 0 : 1
              result[i]+=1
              "#{txt} [P] (#{result[0]}:#{result[1]})"
            when 'goal-own'
              i = home_player_uris.include?(goal.player_uri.to_s) ? 1 : 0
              result[i]+=1
              "#{txt} [OG] (#{result[0]}:#{result[1]})"
            else
              nil
          end
    end
    result.compact
  end

  def get_position_sortings
    [
        'Goalkeeper',
        'Defender',
        'Centre Back',
        'Full Back',
        'Left Back',
        'Left Back / Winger',
        'Left Back/Winger',
        'Left Wing Back',
        'Right Back',
        'Right Back / Winger',
        'Right Back/Winger',
        'Right Wing Back',
        'Wing Back',
        'Midfielder / Defender',
        'Midfielder/Defender',
        'Defender / Defensive Midfielder',
        'Defensive Midfielder',
        'Defensive Midfielder / Central Midfielder',
        'Defensive Midfielder/Central Midfielder',
        'Centre Back / Defensive Midfielder',
        'Centre Back/Defensive Midfielder',
        'Central Midfielder',
        'Central Midfielder / Winger',
        'Central Midfielder/Winger',
        'Midfielder',
        'Winger',
        'Attacking Midfielder / Winger',
        'Attacking Midfielder/Winger',
        'Attacking Midfielder',
        'Forward',
        'Forward / Right Winger',
        'Forward/Right Winger',
        'Forward / Left Winger',
        'Forward/Left Winger',
        'Striker / Winger',
        'Winger / Striker',
        'Striker',
        'Winger, Second Striker',
        'Second Striker',
        'N.A.',
        ''
    ]
  end

  def sort_players!(players, player_infos)
    sorting_list = get_position_sortings
    players.sort! do |a, b|
      i1 = if sorting_list.include?(player_infos[a.uri.to_s][:position].to_s.titlecase)
             sorting_list.index(player_infos[a.uri.to_s][:position].to_s.titlecase).to_i
           else
             sorting_list.count+2
           end
      i2 = if sorting_list.include?(player_infos[b.uri.to_s][:position].to_s.titlecase)
             sorting_list.index(player_infos[b.uri.to_s][:position].to_s.titlecase).to_i
           else
             sorting_list.count+2
           end
      i1 <=> i2
    end
  end

end
