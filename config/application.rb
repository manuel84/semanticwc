require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Semanticwc
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :de
    config.autoload_paths += %W(#{Rails.root.join 'lib', 'data_wrapper'})
  end
end

I18n.config.enforce_available_locales = false

module PREFIX
  WC = 'http://cs.hs-rm.de/mdudd001/wc/'
  BBCEVENT = 'http://www.bbc.co.uk/ontologies/event/'
  BBCSPORT = 'http://www.bbc.co.uk/ontologies/sport/'
  DB = 'http://de.dbpedia.org/'
  RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  RDFS ='http://www.w3.org/2000/01/rdf-schema#'
  XML = 'http://www.w3.org/XML/1998/namespace'
  XSD = 'http://www.w3.org/2001/XMLSchema#'
  WIKI = 'http://de.wikipedia.org/wiki/'
end