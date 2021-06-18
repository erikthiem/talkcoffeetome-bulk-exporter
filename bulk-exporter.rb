require "uri"
require "net/http"
require "nokogiri"

def talkcoffee_boards_html(talkcoffee_cookie)
  url = URI("https://talkcoffeeto.me/discussion/boards")

  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["Cookie"] = "_leancoffee_key=#{talkcoffee_cookie};"

  response = https.request(request)
  response.body
end

def get_board_ids(raw_html)
  board_ids = []

  html_doc = Nokogiri::HTML(raw_html)
  board_links = html_doc.css(".board-listing")

  board_links.each do |board_link|
    link = board_link.search("a").first["href"]
    board_id = link.split("\/d\/")[1]
    board_ids.push board_id
  end

  board_ids
end

def get_board_markdowns(board_ids, talkcoffee_cookie)
  board_markdowns = []
  board_ids.each do |board_id|
    url = URI("https://talkcoffeeto.me/discussion/boards/#{board_id}/export")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["Cookie"] = "_leancoffee_key=#{talkcoffee_cookie};"

    response = https.request(request)
    board_markdowns.push response.body
  end

  board_markdowns
end

def write_output_file(board_markdowns, output_file)
  file = File.open(output_file, "w")

  board_markdowns.each do |board_markdown|
    file.write("#{board_markdown}\n\n~~~\n\n")
  end

  file.close
end

puts "Paste your TalkCoffeeToMe '_leancoffee_key' cookie below:"
talkcoffee_cookie = gets.chomp

puts "Output file:"
output_file = gets.chomp

raw_html = talkcoffee_boards_html(talkcoffee_cookie)
puts "Successfully authenticated with TalkCoffeeToMe!"

board_ids = get_board_ids(raw_html)
puts "Successfully found #{board_ids.count} TalkCoffeeToMe boards!"

board_markdowns = get_board_markdowns(board_ids, talkcoffee_cookie)
puts "Successfully downloaded #{board_markdowns.count} TalkCoffeeToMe boards!"

write_output_file(board_markdowns, output_file)
puts "Successfully exported boards to #{output_file}!"
