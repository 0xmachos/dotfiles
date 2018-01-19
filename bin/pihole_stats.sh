#!/bin/bash
# dotfiles/bin/pihole_stats.sh

# pihole_stats.sh
	# Display some stats from local pi-hole server
	# Format: dns_queries_today | ads_blocked_today (ads_percentage_today)
	# Symlink to /usr/local/pihole_stats.sh
	# Alias = phs

set -euo pipefail


function get_pihole_ip {
	
	pihole_ip="$(dig +time=3 +tries=1 +short pi.hole)"
	# +time=2 	Timout after 2 seconds
	# +tries=1 	Attempt to connect to the server once
	# +short 	Retun only the ip address
}


function get_dns_queries_today {

	dns_queries_today="$(curl -s http://pi.hole/admin/api.php \
							| awk -F ',' '{print $2}' \
							| perl -nle "print $& if m{(?<=:).*}" \
							| awk '{printf(fmt,$1)}' fmt="%'5.0f\\n")"
}


function get_ads_blocked_today {

	ads_blocked_today="$(curl -s http://pi.hole/admin/api.php \
						| awk -F ',' '{print $3}' \
						| perl -nle "print $& if m{(?<=:).*}" \
						| awk '{printf(fmt,$1)}' fmt="%'5.0f\\n")"
}


function get_ads_percentage_today {

	ads_percentage_today="$(curl -s http://pi.hole/admin/api.php \
					| awk -F ',' '{print $4}' \
					| perl -nle "print $& if m{(?<=:).*}" \
					| awk '{printf("%.1f\n", $1)}')"
}


# function get_status {

# 	status="$(curl -s http://pi.hole/admin/api.php \
# 					| awk -F ',' '{print $10}' \
# 					| tr -d '}' \
# 					| perl -nle "print $& if m{(?<=:).*}" \
# 					| tr -d '"')"
# }


function main {

	get_pihole_ip

	if [[ "${pihole_ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		# Check if pi.hole resolves to a valid IP address

		get_dns_queries_today
		get_ads_blocked_today
		get_ads_percentage_today
		
		echo -e "Queries: \\033[1;32m${dns_queries_today}\\033[0m | Ads Blocked: \\033[1;31m${ads_blocked_today}\\033[0m (\\033[1;34m${ads_percentage_today}%\\033[0m)"
		exit 0

	else
		echo -e "No Pi-hole on this network 😢"
		exit 1
		
	fi
}

main "$@"
