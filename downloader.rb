class Downloader

  require 'fileutils'
  require 'open-uri'
  require 'nokogiri'
  require 'uri'

  DAY_URL = "http://paper.people.com.cn/rmrb/html/%s/%s/nbs.D110000renmrb_01.htm"
  TITLE_REG = /document.write\(view\("(.*?)"\)\)/

  def initialize(path = 'output')
    @out_path = path
  end

  def download_article(url, path)
    puts "    正在下载 #{path}"

    doc = Nokogiri::HTML(open(url).read)

    text = doc.css('.c_c #ozoom p').map { |p| p.text.strip }.join("\n")

    File.write(path, text)
  end

  def download_page(url, path)
    puts "  正在下载 #{path}"

    begin
      page = Nokogiri::HTML(open(url).read)
    rescue OpenURI::HTTPError
      puts "    失败"
      return
    end

    FileUtils.mkdir_p(path)

    page.css('#titleList li a').each do |article|
      next if article.content.strip.empty?

      article_path = File.join(path, TITLE_REG.match(article.content)[1].strip.gsub('/', '-') + '.txt')
      article_url = URI::join(url, article['href'])

      download_article(article_url, article_path)
    end
  end

  def download_day(date = Date.today)
    date_str = date.strftime('%F')
    month_str = date_str.split('-')[0..1].join('-')
    day_str = date_str.split('-').last
    day_path = File.join(@out_path, date.strftime('%F'))

    puts "正在下载 #{day_path}"

    FileUtils.mkdir_p(day_path)

    url = DAY_URL % [month_str, day_str]
    index = Nokogiri::HTML(open(url).read)

    index.css('#pageLink').each do |page|
      page_path = File.join(day_path, page.text)
      url = URI::join(url, page['href'])

      download_page(url, page_path)
    end
  end

  def download_year(year)
    (Date.new(year, 1, 1)...Date.new(year + 1, 1, 1)).each do |d|
      download_day(d)
    end
  end

end

Downloader.new.download_year(2013)