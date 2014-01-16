# coding: utf-8

require 'bundler'
Bundler.require

# メール送信
def send_mail(*str)
  mailstr = Time.now.strftime("%Y年%m月%d日 %H時%M分").to_s + " : エゴサーチ完了しました。\n\n\n"
  
  mailstr += str.join

  puts "mailstr:\n#{mailstr}"

  mail = Mail.new do
    from    $settings["mail_from"]
    to      $settings["mail_to"]
    subject $settings["mail_subject"]
    body    mailstr
  end

  mail.delivery_method :smtp, { address: $settings["mail_address"],
                                port: $settings["mail_port"],
                                domain: $settings["mail_domain"],
                                user_name: $settings["mail_user_name"],
                                password: $settings["mail_password"] }
  
  mail.charset = 'utf-8'
  mail.deliver!
  mailstr.clear
end

path = File.expand_path(File.dirname(__FILE__))

begin
  $settings = YAML::load(open(path+"/egose.conf"))
rescue
  puts "config file load failed."
  exit
end

Twitter.configure do |config|
 config.consumer_key = $settings["consumer_key"]
 config.consumer_secret = $settings["consumer_secret"]
end

str = []
since_list = []
last_id =""

# 前回の検索の続きから
if File.exist? path+"/since_ids.txt" then
  File.open(path+"/since_ids.txt","r") do |f|
    since_list = f.readlines
  end

  FileUtils.rm(path+"/since_ids.txt")
end

File.open(path+"/search_words.txt") do |f|
  f.each_with_index do |search_word, i|
    str = str | Twitter.search(search_word, :result_type => "recent", :since_id => since_list[i]).results.reverse.map do |status|
      last_id = status.id
      "#{status.created_at} #{status.from_user}:\n#{status.text}\nhttps://twitter.com/#{status.from_user}/status/#{status.id} \n\n\n" 
    end
    
    unless last_id.blank? then
      since_list[i] = last_id
    end

    last_id = nil
  end
end

File.open(path+"/since_ids.txt", "w") do |f|
  since_list.each do |since_id|
    f.puts "#{since_id}"
  end
end

send_mail(*str)

