require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'mechanize'
require './Scraping'
require 'open-uri'
require 'nokogiri'
require 'kconv'

get '/' do
@age_hash = {}
@dose_hash = {}
@time_hash = {}
erb :index
end


post '/search' do
    @name = params[:sideeffect]
    page_number = 0
    parsed_html = []
    
    while page_number < 11 do
        # アクセス回数増えすぎると制限かけられそうなので、作る時はページの表示も1までにする。
        url = "http://www.info.pmda.go.jp/fsearchnew/fukusayouMainServlet?scrid=SCR_LIST&evt=SHOREI&type=1&pID=3969010%20&name=%A5%B8%A5%E3%A5%CC%A5%D3%A5%A2&fuku=&root=1&srtnendo=2&page_max=100&page_no=#{page_number}"
        html = open(url).read
        parsed_html << Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
        page_number = page_number + 1
    end
        i = 0
        # iは有害事象の報告件数
        m = 0
        # mは総報告件数
        
        men = 0
        # 男性の数
        women = 0
        # 女性の数
        other = 0
        @age = Array.new
        @dose = Array.new
        @time = Array.new
        @start_time = Array.new
        @end_time = Array.new
        @dosing_period = Array.new
        # @end_day = Array.new
        # @start_day = Array.new
        
        # 不明者の数
    parsed_html.each do |parsed_html1|
        parsed_html1.css('table').each do |node|
            node2 = node.css('tr[7] td[2]').inner_text
            # puts "---------------------------------------------------"
                if node2.include?(params[:sideeffect])
                    # 性別の分類わけ
                    if node.css('tr[2] td[2]').inner_text.include?('男')
                        men = men + 1
                        # puts node.css('tr[2] td[2]').inner_text
                    elsif node.css('tr[2] td[2]').inner_text.include?('女')
                        women = women + 1
                    else
                        other = other + 1
                    end
                    
                    # 年齢分け
                    @age << node.css('tr[2] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    
                    # 投与量
                    @dose <<  node.css('tr[5] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    
                    # 報告時期
                    @time << node.css('tr[1] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    
                    # 投与開始 日数の算出
                    start_time = node.css('tr[5] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    start_time = start_time.split(//)
                    if start_time.length == 8
                        start_day =  (start_time[0].to_i*1000+start_time[1].to_i*100+start_time[2].to_i*10+start_time[3].to_i)*365+(start_time[4].to_i*10+start_time[5].to_i)*30+start_time[6].to_i*10+start_time[7].to_i
                    elsif start_time.length == 6
                        start_day =  (start_time[0].to_i*1000+start_time[1].to_i*100+start_time[2].to_i*10+start_time[3].to_i)*365+(start_time[4].to_i*10+start_time[5].to_i)*30
                    else
                        start_day = 0
                    end
                    # @start_time << node.css('tr[5] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    
                    # 投与終了 日数の算出
                    end_time = node.css('tr[5] td[6]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    end_time = end_time.split(//)
                    if end_time.length == 8
                        end_day =  (end_time[0].to_i*1000+end_time[1].to_i*100+end_time[2].to_i*10+end_time[3].to_i)*365+(end_time[4].to_i*10+end_time[5].to_i)*30+end_time[6].to_i*10+end_time[7].to_i
                    elsif end_time.length == 6
                        end_day =  (end_time[0].to_i*1000+end_time[1].to_i*100+end_time[2].to_i*10+end_time[3].to_i)*365+(end_time[4].to_i*10+end_time[5].to_i)*30
                    else
                        end_day = 0
                    end
                    # @end_time << node.css('tr[5] td[6]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "") 
                    # puts @end_day - @start_day
                    puts end_day
                    puts start_day
                    dosing_period = end_day - start_day
                    if dosing_period < 1
                        dosing_period = "不明"
                    elsif dosing_period > 730000
                        dosing_period = "開始時期不明"
                    end
                    @dosing_period << dosing_period
                    # puts "投与期間　：　#{@end_day - @start_day}"
                    # 投与期間の算出
                    # @dosing_period << start_day - end_day
                    
                    i = i + 1
                else
                    puts "nothing in tihs table"
                end
            m = m + 1
        end
    end
    
        # 年齢ハッシュの作成
        ages = @age.uniq
        number_of_age = Array.new
        ages.each do |age|
            number_of_age << @age.count(age)
        end
        age_ary = [ages,number_of_age].transpose
        @age_hash = Hash[*age_ary.flatten].sort
        
        # 投与量のハッシュ
        doses = @dose.uniq
        number_of_dose = Array.new
        doses.each do |dose|
            number_of_dose << @dose.count(dose)
        end
        dose_ary = [doses,number_of_dose].transpose
        @dose_hash =Hash[*dose_ary.flatten].sort
        
        # 報告時期のハッシュ
        times = @time.uniq
        number_of_time = Array.new
        times.each do |time|
            number_of_time << @time.count(time)
        end
        time_ary = [times,number_of_time].transpose
        @time_hash =Hash[*time_ary.flatten].sort
        
        puts "総報告数　#{i}"
        puts "総数　#{m}"
        @number_of_report = i
        @total_report = m - 4
        @men = men
        @women = women
        @other = other 
        # 総数は１０４件出てくる。ページ数×4が余分な量となっている。
        puts "検索終了"
        erb :index
    end
    # htmlをパース(解析)してオブジェクトを作成

#     doc.xpath('//td[@class="lef"]').each do |node|
#       # タイトルの取得
#         puts node
#         a = node.css('td').inner_text
#         if a.match(/シタグリプチン/) then
#           puts a
#         else
#           puts 'なかった'
#         end
#     end



# get '/pmda' do
#     puts 'clickしたぜ！！！'
#     Scraping.get_pmda()
#     redirect '/'
# end

