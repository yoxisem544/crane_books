require 'rest_client'
require 'nokogiri'
require 'json'
require 'iconv'
require 'uri'
require 'capybara'
require_relative 'course.rb'
# 難得寫註解，總該碎碎念。
class Spider
  attr_reader :semester_list, :courses_list, :query_url, :result_url
  include Capybara::DSL

  def initialize
  	@category_url = "http://www.crane.com.tw/ec99/crane/ShowCategory.asp?category_id="
    @lists = [1, 41, 82, 106, 125, 145, 150, 156, 177, 258]
    @front_url = "http://www.crane.com.tw/ec99/crane/"
    Capybara.default_driver = :selenium
  end

  def prepare_post_data
    # visit @category_url+1.to_s
    # puts page.html
    nil
  end

  def get_books
  	# 初始 courses 陣列
    @books = []
    puts "getting books...\n"
    # 一一點進去YO

    9.times do |i|
      puts @category_url + @lists[i].to_s, ""
      r = RestClient.get @category_url + @lists[i].to_s
      ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
      cate_page = Nokogiri::HTML(ic.iconv(r.to_s))

      # 取得每個大分類的小分類連結
      cate_page.css('a.lef').each_with_index do |bigpage, index|
        # puts "index = " + index.to_s
        # puts bigpage['href']

        # 進去小分類GET資料
        r = RestClient.get @front_url + bigpage['href'].to_s
        ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
        detail_page = Nokogiri::HTML(ic.iconv(r.to_s))

        # 這邊開始抓書
        # puts detail_page.css('a.lef')

        # 判斷有沒有更下一層
        if detail_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd').text == ""
          puts "有更下一層。"
          puts detail_page.css('a.lef')
          detail_page.css('a.lef').each_with_index do |detail, index|
            r = RestClient.get @front_url + detail['href']
            puts "🌀 " + @front_url + detail['href']
            ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
            hi = Nokogiri::HTML(ic.iconv(r.to_s))
            # 這個是美的小累的頁數
            # 判斷有沒有真的有東西
            if hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.nil?
              puts "此業無內容"
            else
              puts hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text
              pages = hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text.to_i
              visit @front_url + detail['href']
              pages.times do |hellopage|
                unless hellopage == 0
                  # 不事第一頁就點下一頁
                  page.find(:xpath, '/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr/td/center/table[1]/tbody/tr/td[1]/input[2]').click
                end
                hey = Nokogiri::HTML(ic.iconv(page.html))
                # 每一頁的所有書的連節
                hey.css('center a').each do |i|
                  puts i['href']
                  begin
                    r = RestClient.get @front_url + i['href']
                  rescue
                    next
                  end
                  ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
                  fuckulittlebitch = Nokogiri::HTML(ic.iconv(r.to_s))
                  if fuckulittlebitch.css('.goodstext').text == ""
                    puts "this page is not want i am finding..."
                  else
                    book_name = fuckulittlebitch.css('.goodstext').text
                    query_text = fuckulittlebitch.css('.defcxt').to_s
                    query_text = query_text.split("<br>")

                    author = ""
                    publisher = ""
                    publish_date = ""
                    isbn = ""
                    agent = ""
                    # puts query_text
                    5.times do |i|
                      if !query_text[i+1].nil?
                        if query_text[i+1].split('：').first == "作者"
                          author = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "出版社"
                          publisher = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "出版日期"
                          publish_date = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "ISBN"
                          isbn = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "代理商"
                          agent = query_text[i+1].split('：').last
                          agent = agent.split('<').first
                        end
                      end
                    end

                    price = fuckulittlebitch.css('.goodsDescrcost').text
                    puts "book: #{book_name} isbn: #{isbn}"

                    @books << Course.new({
                      :book_name => book_name,
                      :author => author,
                      :publisher => publisher,
                      :publish_date => publish_date,
                      :isbn => isbn,
                      :agent => agent,
                      :price => price,
                      :url => @front_url + i['href']
                      }).to_hash
                    puts "saved"
                  end
                end
              end
            end
            # 美的小小的業面，幹
            puts "😨 "
          end
        else
          puts "此為最下一層。"
          puts "book of this page: ", detail_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd')

          # 這邊複製
          puts detail_page.css('a.lef')
          detail_page.css('a.lef').each_with_index do |detail, index|
            r = RestClient.get @front_url + detail['href']
            puts "🌀 " + @front_url + detail['href']
            ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
            hi = Nokogiri::HTML(ic.iconv(r.to_s))
            # 這個是美的小累的頁數
            # 判斷有沒有真的有東西
            if hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.nil?
              puts "此業無內容"
            else
              # puts 頁數
              puts hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text
              pages = hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text.to_i
              visit @front_url + detail['href']
              pages.times do |hellopage|
                unless hellopage == 0
                  # 不事第一頁就點下一頁
                  page.find(:xpath, '/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr/td/center/table[1]/tbody/tr/td[1]/input[2]').click
                end
                hey = Nokogiri::HTML(ic.iconv(page.html))
                # 每一頁的所有書的連節
                # 有錯誤要跳過
                hey.css('center a').each do |i|
                  puts i['href']
                  begin
                    r = RestClient.get @front_url + i['href']
                  rescue
                    next
                  end
                  ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
                  fuckulittlebitch = Nokogiri::HTML(ic.iconv(r.to_s))
                  if fuckulittlebitch.css('.goodstext').text == ""
                    puts "this page is not want i am finding..."
                  else
                    book_name = fuckulittlebitch.css('.goodstext').text
                    query_text = fuckulittlebitch.css('.defcxt').to_s
                    query_text = query_text.split("<br>")

                    author = ""
                    publisher = ""
                    publish_date = ""
                    isbn = ""
                    agent = ""
                    puts query_text
                    5.times do |i|
                      if !query_text[i+1].nil?
                        if query_text[i+1].split('：').first == "作者"
                          author = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "出版社"
                          publisher = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "出版日期"
                          publish_date = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "ISBN"
                          isbn = query_text[i+1].split('：').last
                        elsif query_text[i+1].split('：').first == "代理商"
                          agent = query_text[i+1].split('：').last
                          agent = agent.split('<').first
                        end
                      end
                    end

                    price = fuckulittlebitch.css('.goodsDescrcost').text
                    puts "book: #{book_name} isbn: #{isbn}"

                    @books << Course.new({
                      :book_name => book_name,
                      :author => author,
                      :publisher => publisher,
                      :publish_date => publish_date,
                      :isbn => isbn,
                      :agent => agent,
                      :price => price,
                      :url => @front_url + i['href']
                      }).to_hash
                    puts "saved"
                  end
                end
                # 錯誤到這邊
              end
            end
            # 美的小小的業面，幹
            puts "😨 "
          end
          # 這邊複製
        end
      end
      # puts cate_page.css('a.lef')
    end

  end
  

  def save_to(filename='crane_books.json') #now on page 2 part 3
    File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(@books))}
  end
    
end






spider = Spider.new
spider.prepare_post_data
spider.get_books
spider.save_to