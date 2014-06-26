namespace :semanticwc do
  desc "scrape all"
  task build: :environment do
    puts "do some fancy stuff"
    SfgCrawler.crawl
  end
end