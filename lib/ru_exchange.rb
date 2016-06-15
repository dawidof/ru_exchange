class RuExchange
	require 'logger'
	require 'nokogiri'
	require 'open-uri'

	def self.update_currencies
	  	RuExchange.log "Updating currency. Time: " + Time.now.strftime('%d.%m.%Y %H:%M')

	  	cur = Dashboard::Currency.find_or_create_by(id: 1)
	  	begin
	  		cur_new = Dashboard::Currency.where('created_at >= ?', 24.hours.ago).first || Dashboard::Currency.new
	  	rescue ActiveRecord::RecordNotUnique
	  		retry
	  	end

	  	cur_new = Dashboard::Currency.new if (0..3).include?(Time.now.strftime('%H').to_i)
	  	RuExchange.log 'Currency is new record: ' + cur_new.new_record?.to_s
	  	RuExchange.log ''

	  	# update_rur = false
	  	# update_uah = false
	  	# if cur_new.uah.nil?
	  	# 	update_uah = true
	  	# end
	  	# if cur_new.rur.nil?
	  	# 	update_rur = true
	  	# end

	  	if true
	  		update_uah = true
	  		update_rur = true
	  	end

	  	begin

	  		if update_rur && result_rur = RuExchange.get_rur
	  			cur.rur = result_rur
	  			cur.rur_changed_at = Time.now

	  			pack_rur = Dashboard::Package.where(rur_auto: true)
	  			RuExchange.log 'Preparing to update package prices in rur'
	  			pack_rur.each do |pack|
	  				unless pack.usd.nil?
	  					pack.rur = Dashboard::Currency.auto_price(pack.usd.to_f * result_rur.to_f)
	  					pack.rur_changed_at = Time.now
	  					pack.rur_changed_by = -1
	  					puts pack.errors.inspect unless pack.save

	  					RuExchange.log 'Package: ' + pack.name
	  					RuExchange.log 'Package USD: ' + pack.usd.to_s
	  					RuExchange.log "Math RUR: #{pack.usd.to_s} * #{result_rur.to_s} = #{pack.usd.to_f * result_rur.to_f}" 
	  					RuExchange.log 'Package RUR AutoPrice: ' + pack.rur.to_s
	  					RuExchange.log '------'

	  					r_c = Dashboard::ReportCurrency.new
	  					r_c.package_id = pack.id
	  					r_c.currency = 'RUR'
	  					r_c.ex_rate = result_rur.to_f
	  					r_c.price_in_usd = pack.usd
	  					r_c.price_in_curr = pack.usd.to_f * result_rur.to_f
	  					r_c.auto_price = Dashboard::Currency.auto_price(pack.usd.to_f * result_rur.to_f)
	  					r_c.error = nil
	  					r_c.status = 1
	  					r_c.save
	  				else 
	  					RuExchange.log 'No USD set for package'
	  					r_c = Dashboard::ReportCurrency.new
	  					r_c.error = ['custom' => 'Не задана цена в долларах'].to_json
	  					r_c.status = 3
	  					r_c.currency = 'RUR'
	  					r_c.package_id = pack.id
	  					r_c.ex_rate = result_rur.to_f
	  					r_c.save
	  				end
	  			end
	  		else
	  			RuExchange.log 'Not new record. Nothing to save'
	  		end
	  		if cur_new.rur_changed_at.nil?
	  			cur_new.rur = result_rur
	  			cur_new.rur_changed_at = Time.now
	  		end


	  	rescue => exception
	  		RuExchange.log exception.class.to_s
	  		RuExchange.log exception.to_s
	  		RuExchange.log exception.backtrace.join("\n")

	  		r_c = Dashboard::ReportCurrency.new
	  		r_c.error = [exception.to_s => exception.backtrace.join("\n")].to_json
	  		r_c.status = 2
	  		puts r_c.errors.inspect unless r_c.save

	  	end

	  	RuExchange.log ''

	  	begin 
	  		# puts m
	  		# if cur.uah_changed_at < 24.hours.ago
	  		if update_uah && result_uah = RuExchange.get_uah
	  			cur.uah = result_uah
	  			cur.uah_changed_at = Time.now

	  			pack_uah = Dashboard::Package.where(uah_auto: true)
	  			RuExchange.log 'Preparing to update package prices in uah'
	  			pack_uah.each do |pack|
	  				unless pack.usd.nil?
	  					pack.uah = Dashboard::Currency.auto_price(pack.usd.to_f * result_uah.to_f)
	  					pack.uah_changed_at = Time.now
	  					pack.uah_changed_by = -1
	  					pack.save
	  					RuExchange.log 'Package: ' + pack.name
	  					RuExchange.log 'Package USD: ' + pack.usd.to_s
	  					RuExchange.log "Math UAH: #{pack.usd.to_s} * #{result_uah.to_s} = #{pack.usd.to_f * result_uah.to_f}" 
	  					RuExchange.log 'Package UAH AutoPrice: ' + pack.uah.to_s
	  					RuExchange.log '------'

	  					r_c = Dashboard::ReportCurrency.new
	  					r_c.package_id = pack.id
	  					r_c.currency = 'UAH'
	  					r_c.ex_rate = result_uah.to_f
	  					r_c.price_in_usd = pack.usd
	  					r_c.price_in_curr = pack.usd.to_f * result_uah.to_f
	  					r_c.auto_price = Dashboard::Currency.auto_price(pack.usd.to_f * result_uah.to_f)
	  					r_c.error = nil
	  					r_c.status = 1
	  					r_c.save
	  				else 
	  					RuExchange.log 'No USD set for package'
	  					r_c = Dashboard::ReportCurrency.new
	  					r_c.error = ['custom' => 'Не задана цена в долларах'].to_json
	  					r_c.status = 3
	  					r_c.currency = 'UAH'
	  					r_c.package_id = pack.id
	  					r_c.ex_rate = result_uah.to_f
	  					r_c.save
	  				end
	  			end
	  		end
	  		if  cur_new.uah_changed_at.nil?
	  			cur_new.uah = result_uah
	  			cur_new.uah_changed_at = Time.now
	  		end
	  	rescue => exception
	  		RuExchange.log exception.class.to_s
	  		RuExchange.log exception.to_s
	  		RuExchange.log exception.backtrace.join("\n")
	  	end

	  	begin
	  		if cur.save
	  			RuExchange.log 'First currency updated!'
	  		else
	  			RuExchange.log '--- ERROR First currency not updated!'
	  		end
	  		if cur_new.save
	  			RuExchange.log 'Current currency updated!'
	  			RuExchange.log 'RUR: ' + result_rur.to_s
	  			RuExchange.log 'UAH: ' + result_uah.to_s
	  		else
	  			RuExchange.log '--- ERROR Current currency not updated!'
	  		end

	  	rescue => exception
	  		RuExchange.log exception.class.to_s
	  		RuExchange.log exception.to_s
	  		RuExchange.log exception.backtrace.join("\n")
	  		r_c = Dashboard::ReportCurrency.new
	  		r_c.error = [exception.to_s => exception.backtrace.join("\n")].to_json
	  		r_c.status = 2
	  		r_c.save
	  	end

	  	RuExchange.log 'FINISHED'
	  	RuExchange.log ''
	end


  def self.auto_price(price = 999)
  	# Auto generating price example
  	price = price.to_f
  	if price < 1000
  		result = ( (price / 100).round(1) * 100 - 1 ).round.to_i
  	else
  		result = ( (price / 1000).round(1) * 1000 - 10 ).round.to_i
  	end
  	return result
  end


  def self.get_rur
  	begin
  		url = "http://quote.rbc.ru/cash/averagerates.html"
  		RuExchange.log 'Trying to parce site in rur'
  		doc = Nokogiri::HTML(open(url))
  		result = doc.search('div.stats__td').last.text
  	rescue => e
  		RuExchange.log("Couldn't get current rur exchange rate. Error in parcing site.")
  		RuExchange.log(e)
  	end
  	return result
  end

  def self.get_uah
  	begin
  		url = "http://finance.i.ua/usd/"
  		doc = Nokogiri::HTML(open(url))
  		z = doc.at_css('div.Right div.block_gamma_dark table.local_table')
  		k = z.css('tr')[1]
  		result = k.css('td')[2].css('big').text
  		RuExchange.log 'Trying to parce site in uah'
  	rescue => e
  		RuExchange.log("Couldn't get current uah exchange rate. Error in parcing site.")
  		RuExchange.log(e)
  	end
  	return result
  end

  def self.logger_file=(file)
  	@logger_file = file
  end


  private
  def self.log(text)
	if @logger_file
		@logger ||= Logger.new(@logger_file)
  		@logger.datetime_format ||= '%d.%m %H:%M:%S'
  		@logger.info text
  		puts text
  	end
  end


end