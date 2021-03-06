#encoding:utf-8

require 'metasearch'


include Metasearch



describe "Metasearch::Builder" do


	it 'load sample dsl' do
		with_name("sample"){
			load "sample.dsl"
		}		
		puts search_tasks
	end

	it "test builder common" do

		Metasearch::Builder.new("http://sz.meituan.com/category/entertainment/all") do
			
			accept '#content' do |link|
				link.to_s =~ /food|deal/		
			end
			
			match /deal\/.+.html$/ do
				use :model, :string
				field :url do |doc, url|
					url
				end
				field :intro do |doc|
					doc.at('#deal-intro h1').text if doc.at('#deal-intro h1')
				end
				field :price do |doc|
					doc.at('#deal-intro .deal-price-tag-open > strong').text.gsub(/[^\d.]/, '').to_f if doc.at('#deal-intro .deal-price-tag-open > strong')
				end
				field :image do |doc|
					doc.at('#deal-intro .deal-buy-cover-img > img')[:src] if doc.at('#deal-intro .deal-buy-cover-img > img')
				end
				field :sale_count do |doc|
					doc.at('#deal-intro .deal-status-count').text if doc.at('#deal-intro .deal-status-count')
				end
				field :catalog do 
					'Play'
				end
				field :provider do
					'美团网'
				end
				save do|data|
				
				end
			end			
		end
	end
	
end