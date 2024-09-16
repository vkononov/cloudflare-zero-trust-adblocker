require 'dotenv'
Dotenv.load

CLOUDFLARE_ACCOUNT_ID = ENV.fetch('CLOUDFLARE_ACCOUNT_ID', nil)
CLOUDFLARE_API_KEY = ENV.fetch('CLOUDFLARE_API_KEY', nil)
CLOUDFLARE_EMAIL = ENV.fetch('CLOUDFLARE_EMAIL', nil)
CLOUDFLARE_LIST_ITEM_LIMIT = ENV.fetch('CLOUDFLARE_LIST_ITEM_LIMIT', 1000).to_i

EXCLUSIONS_FILE = ENV.fetch('EXCLUSIONS_FILE', 'exclusions.txt')

AD_LIST_URL = ENV.fetch('AD_LIST_URL', 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts')
AD_LIST_NAME = ENV.fetch('AD_LIST_NAME', 'Pi-hole Hostname Ad List')
