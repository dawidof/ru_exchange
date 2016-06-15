# Exchange Rates (RUR, UAH)
Get current exchange rate of russian rubles and ukrainian chryvnas

# Getting started

You can add it to your Gemfile with:
> gem 'ru_exchange'

# How to use
if you want to log
> RuExchange.logger_file = "log/#{Rails.env.to_s}/curreny_update.log"

Get RUR
> RuExchange.get_rur
Get UAH
> RuExchange.get_uah
