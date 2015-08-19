require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'pry'
require 'data_mapper'

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/firms.db")

class Firm
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :website, String
  property :phone, String
  property :address1, String
  property :address2, String

end

DataMapper.finalize
DataMapper.auto_upgrade!

def fill_vars(res,vars={})
  res.css('.column')[1].css('h1').each do |h|
    vars[:name] = res.search('meta')[2].attributes['content'].content[/: (.{1,})/].gsub!(': ','')

    parent = h.parent
    case parent.css('h1').first.content
    when 'Location'
      vars[:address1] = parent.css('a')[0].content
      vars[:address2] = parent.css('a')[1].content if parent.children.include? parent.css('a')[1]# next a actually location child anchor
    when 'Phone'
      vars[:phone] = parent.css('p').first.content
    when 'Website'
      vars[:website] = parent.css('p').first.content
    end
  end

  return vars
end

redirect_run = 0
current_id   = 1

uri_base     = "http://www.designfirms.org/company/"

while current_id < 23700 || redirect_run <= 100 do

  company_uri = "#{uri_base}#{current_id.to_s}"
  res         = Nokogiri::HTML.parse(open(company_uri).read)

  if res.search('meta')[3].nil?# we were redirected to /companies
    puts "Record does not exist."
    redirect_run += 1
  else
    vars      = fill_vars res
    vars[:id] = current_id

    puts "Name: " + vars[:name]
    puts "ID: " + vars[:id].to_s
    puts "#{vars[:address1]} #{vars[:address2]}"
    puts "Phone:" + vars[:phone]
    puts "Website:" + vars[:website]

    if Firm.new(vars).save
      puts "Successfully saved to db."
    else
      puts "Couldn't save record."
    end

  end

  puts ""

  # iterator
  current_id += 1

end
