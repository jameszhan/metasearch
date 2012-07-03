require "metasearch/version"
require "anemone"


module Metasearch

	lambda{
		tasks = {}
		current_filename = 'global'
		self.send :define_method, :with_name do |filename, &block|
			temp = current_filename
			current_filename = filename if filename
			block.call
			current_filename = temp
		end
				
		self.send :define_method, :crawl do |links, &block|
			tasks[current_filename] ||= []
			tasks[current_filename] << Builder.new(links, &block)
		end
		
		self.send :define_method, :search_tasks do
			tasks
		end
	
	}.call
	

	class Builder
		
		OPTIONS = {
			:threads => 1, 
			:verbose => true, 
			:discard_page_bodies => false, 
			:user_agent => "Metasearch/Robots", 
			:delay => 0, 
			:obey_robots_txt => true, 
			:depth_limit => 2, 
			:redirect_limit => 5, 
			:storage => nil, 
			:cookies => nil, 
			:accept_cookies => false, 
			:skip_query_strings => false, 
			:proxy_host => nil, 
			:proxy_port => false, 
			:read_timeout => nil
		}
		
		attr_reader :pattern_runners, :options, :links
		
    def initialize(links, &block)
			@pattern_runners, @options, @links = [], {}, links
      instance_eval(&block) if block_given?
    end

		def accept(block_css, &block)
			@filter ||= lambda{|page|
				links = []
				if block_css && page.doc
					els = page.doc.css(block_css)
					els.each do|el|
						get_links(el, page.url).each do|link|
							links << link if block.call(link) 
						end
					end
				end
				links = links.empty? ? page.links : links
			}
		end
		
		
		def match(*links_patterns, &block)
			strategy = Strategy.new
			links_patterns.each do|pattern|
				pattern = Regexp.new(pattern, true) unless pattern.is_a? Regexp
				pattern_runners << lambda{|core|
					core.on_pages_like(pattern){|page|
						strategy.run page						
					}
				}
			end
		ensure
			strategy.instance_eval(&block)		
		end
		
		def use(options)
			@options = options
		end
		
		def run
			opts = OPTIONS.merge(options)
			Anemone.crawl(links, opts) do |core|
				core.skip_links_like(skip_links).focus_crawl{|page|
					@filter.call(page)
				}.after_crawl{|pagestore|
					finish pagestore
				}			
				pattern_runners.each {|runner|
					runner.call(core)
				}
			end
		end
		
		private 		
		def skip_links
			/^$/
		end
		
		def get_links(node, base)
			return [] if !node
			links = []
			node.css("a[href]").each do |a|
				u = a['href']
				next if u.nil? or u.empty?
				u = base.scheme + "://" + base.host + u if u.start_with?("/")
				link = URI(URI.escape(u)) rescue next     
				links << link if link.host == base.host
			end
			links.uniq
		end
		
		def finish pagestore
			puts "Finish crawl @ #{Time.now}."
		end
		
	end
	

	class Strategy
		extend Forwardable
		attr_reader :fields, :save_block
		attr_accessor :on_page_ready, :model_class
		
#		def_delegators :@fields, :[], :[]=, :empty?, :each
		
		def initialize
			@fields = {}
		end
		
		def use key, value
			if key == :model
				model_class = constantize(value.to_s.capitalize)
			end
		end
		
		def on_page_ready(&block)
			on_page_ready = block
		end		
		
		def field(name, &block)
			fields[name] = block
		end
			
		def save(&block)
			@save_block = block
		end
			
		def run(page)
			if fields.empty?
				on_page_ready page
			else
				data, fail_count = {}, 0
				fields.each{|field_name, block|
					begin
						val = block.call(page.doc, page.url.to_s)									
						data[field_name] = val if val
					rescue Exception => e
						fail_count += 1
						puts "failed to get #{field_name} for #{page.url} #{e}"
					end	
				}
				if fail_count < (fields.length / 2)
					store data
				else
					puts "Invalid page: #{page.url}"
				end
			end	
		end
		
		
		private
		def store(data)
			begin
				if save_block
					save_block.call(data)
				elsif model_class
					model_class.new(data).save! unless data.empty?
				end
			rescue Exception => e
				puts "store in database error: #{e.message} with url: #{page.url}"
			end
		end
		
		def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?
      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
	end
	
	
end


