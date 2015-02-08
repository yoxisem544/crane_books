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
    @urls = []
    puts "getting books...\n"
    # 一一點進去YO

    9.times do |cate|
      visit @category_url + @lists[cate].to_s
      page.html
      ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
      cate_page = Nokogiri::HTML(ic.iconv(page.html))

      cate_page.css('a.lef').each do |small_cate|
        puts small_cate['href']
        visit @front_url+small_cate['href']
        small_cate_page = Nokogiri::HTML(ic.iconv(page.html))

        if small_cate_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd').text == ""
          puts "有更下一層。"
          small_cate_page.css('a.lef').each do |a|
            puts a['href']

            begin
              visit @front_url+a['href']
            rescue
              puts "hi"
            end
            hi = Nokogiri::HTML(ic.iconv(page.html))
            if hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.nil?
              puts "此業無內容"
            else
              puts hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text
              pages = hi.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text.to_i
              visit @front_url + a['href']
              pages.times do |hellopage|
                puts "page: #{hellopage+1}"
                unless hellopage == 0
                  # 不事第一頁就點下一頁
                  page.find(:xpath, '/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr/td/center/table[1]/tbody/tr/td[1]/input[2]').click
                end
                # 解析，取得每個連結
                hey = Nokogiri::HTML(ic.iconv(page.html))
                hey.css('center a').each do |url|
                  # puts url['href']
                  @urls << @front_url+url['href'].to_s
                end

              end
            end
          end
        else # small cate page
          puts "沒有更下"
          if small_cate_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.nil?
            "此業無內容"
          else
            puts small_cate_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text
            pages = small_cate_page.css('table.PageNavTable:nth-of-type(1) td.PageNavTd span').first.text.to_i
            pages.times do |hellopage|
              puts "page: #{hellopage+1}"
              unless hellopage == 0
                # 不事第一頁就點下一頁
                page.find(:xpath, '/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr/td/center/table[1]/tbody/tr/td[1]/input[2]').click
              end
              # 解析取得連結
              hey = Nokogiri::HTML(ic.iconv(page.html))
              hey.css('center a').each do |url|
                # puts url['href']
                @urls << @front_url+url['href'].to_s
              end
            end
          end
        end
      end
    end

  end
  

  def save_to(filename='bookstest.json') #now on page 2 part 3
    File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(@books))}
    File.open('ursl.json', 'w') {|f| f.write(JSON.pretty_generate(@urls))}
  end
    
end






spider = Spider.new
spider.prepare_post_data
spider.get_books
spider.save_to