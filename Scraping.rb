require 'mechanize'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'kconv' 

class Scraping
    # codeを入れてurlからそれぞれの株価を獲得した。
    # sideeffect = Array.new(0)
    def self.get_pmda()
        puts "start"
        agent=Mechanize.new
        pmda=agent.get("http://www.info.pmda.go.jp/fsearchnew/fukusayouMainServlet?scrid=SCR_LIST&evt=SHOREI&type=1&pID=3969010%20%20%20%20%20&name=%A5%B8%A5%E3%A5%CC%A5%D3%A5%A2&fuku=&root=1&srtnendo=2&page_max=100&page_no=0")
        table=Array.new
        pmda.body = pmda.body.toutf8
        # pmda_utf8 = pmda.kconv(Kconv::UTF8, Kconv::EUC)
        table=pmda.search('table')
        
        # puts table.encoding 
        puts "スクレイピングしたぜ"
        # puts table[1]
            table.each do |e|
                te=e.at('td .lef')
                puts '有害事象データ'
                p te
                p e.at('tr .lef')
                # テキストのみを取り出す
                if e.include?("高血圧")
                    puts te
                else
                    puts "nothing"
                end
            end
        puts "スクレイピングしたぜ２"
    end
end
