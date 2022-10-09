require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(phonenumber)
  phonenumber = phonenumber.to_s
  clean_phonenumber = phonenumber.gsub(/\D/, "")

  if clean_phonenumber.length < 10
    "INVALID NUMBER"
  elsif clean_phonenumber.length == 10
    clean_phonenumber
  elsif clean_phonenumber.length == 11 && clean_phonenumber[0] == '1'
    clean_phonenumber[1..]
  elsif clean_phonenumber.length == 11 && clean_phonenumber[0] != '1'
    "INVALID NUMBER"
  else
    "INVALID NUMBER"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  zipcode = clean_zipcode(row[:zipcode])
  phonenumber = clean_phonenumber(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

def most_common_day
  contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
  )

  reg_day_array = []

  contents.each do |row|
    regdate = row[:regdate]

    formatted_date = Time.strptime(regdate, "%m/%d/%y %H:%M")
    days = formatted_date.day

    reg_day_array.push(days)
  end

  day_tally = reg_day_array.tally
  
  max_v = 0
  max_k = 0

  day_tally.each do |k, v|
    if v > max_v
      max_v = v
      max_k = k
    end
  end

  max_k
end

def most_common_hour
  contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
  )

  reg_hour_array = []

  contents.each do |row|
    regdate = row[:regdate]

    formatted_time = Time.strptime(regdate, "%m/%d/%y %H:%M")
    hours = formatted_time.hour

    reg_hour_array.push(hours)
  end

  hour_tally = reg_hour_array.tally
  
  max_v = 0
  max_k = 0

  hour_tally.each do |k, v|
    if v > max_v
      max_v = v
      max_k = k
    end
  end

  max_k
end

puts "The most common registration hour is: #{most_common_hour}:00"
puts "The most common registration day is: #{most_common_day}"

