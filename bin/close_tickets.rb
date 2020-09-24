require "bundler/setup"
require 'asu'

user_id = ENV['USERNAME'] # or other user as applicable

# max_results = 3
# max_results = 10
# max_results = 20
max_results = 100 # API seems to limit to max of 100
# max_results = 40
# max_results = 400 # still returns at most 100

verbose = ['t', 'true', '1'].include?(ENV['RUN_VERBOSE'].to_s)
ingore_prev_skips = ['t', 'true', '1'].include?(ENV['INGORE_PREV_SKIPS'].to_s)


am = Asu::MyIssues.new(user_id, ingore_prev_skips: ingore_prev_skips)
am.run(max_results: max_results)
