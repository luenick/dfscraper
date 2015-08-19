require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'data_mapper'

#Proxy
PROXIES = []
File.open(ARGV[0], "r") do |f|
  f.each_line do |line|
    PROXIES << line.strip
  end
end

#DB
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/firms.db")

class Firm
  include DataMapper::Resource

  property :id, Serial
  property :pageid, Integer
  property :company, String
  property :website, String
  property :phone, String
  property :location, String

end

DataMapper.finalize
DataMapper.auto_upgrade!

USER_AGENTS = ["Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:32.0) Gecko/20100101 Firefox/32.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.78.2 (KHTML, like Gecko) Version/7.0.6 Safari/537.78.2",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Version/7.1 Safari/537.85.10",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:32.0) Gecko/20100101 Firefox/32.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.103 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
  "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:32.0) Gecko/20100101 Firefox/32.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36",
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:32.0) Gecko/20100101 Firefox/32.0",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.1; rv:32.0) Gecko/20100101 Firefox/32.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.122 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.78.2 (KHTML, like Gecko) Version/7.0.6 Safari/537.78.2",
  "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.122 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.103 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko",
  "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.22 (KHTML, like Gecko) Version/8.0 Safari/600.1.22",
  "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)"]

  #Thread queue
  sites = Queue.new
  nums = (129..23794).to_a

  nums.each do |num|
    sites << num
  end

  pagenum = 2
  maxpage = 23794
  failures = 0

  #thread
  def processpage(pagenum)
    binding.pry

    page = open("http://www.designfirms.org/company/#{pagenum}", "User-Agent" => USER_AGENTS.sample, :proxy => URI.parse("http://"+PROXIES.sample))

    if page.base_uri.to_s == "http://www.designfirms.org/directory/"
      puts "Redirected, inserting \"Not Found\""
      Firm.new(pageid: pagenum, company: "Not found").save
      return
    end
    if page.status.first != "200"
      puts "Possible block or failure, inserting \"Failed\""
      Firm.new(pageid: pagenum, company: "Failed").save
      return
    end
    doc = Nokogiri::HTML(page)
    id = pagenum
    company = doc.xpath('//div[@class="nav"]/following-sibling::h1').text
    location = doc.xpath('//h1[contains(.,"Location")]/following-sibling::p').text
    phone = doc.xpath('//h1[contains(.,"Phone")]/following-sibling::p').text
    website = doc.xpath('//h1[contains(.,"Website")]/following-sibling::p').text
    Firm.new(pageid: id, company: company, location: location, phone: phone, website: website).save
    pagenum += 1
  end

  processpage(129)
