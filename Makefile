SHELL=/bin/bash

LISTS_ROOT := lists

ABP_FORMATTED_LIST_URLS := raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/EnglishFilter/sections/adservers.txt \
	raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/EnglishFilter/sections/adservers_firstparty.txt \
	raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/tracking_servers.txt \
	raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/tracking_servers_firstparty.txt \
	pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/legacy.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt \
	raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resources.txt \
	raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_15_DnsFilter/filter.txt \
	raw.githubusercontent.com/ryanbr/fanboy-adblock/master/fanboy-tracking/fanboy-tracking-firstparty.txt \
	raw.githubusercontent.com/ryanbr/fanboy-adblock/master/fanboy-tracking/fanboy-tracking-general.txt \
	raw.githubusercontent.com/ryanbr/fanboy-adblock/master/fanboy-tracking/fanboy-tracking-thirdparty.txt \
	easylist.to/easylist/easyprivacy.txt \
	easylist.to/easylist/easylist.txt \
	raw.githubusercontent.com/StevenBlack/hosts/master/hosts \
	mirror1.malwaredomains.com/files/justdomains \
	zeustracker.abuse.ch/blocklist.php?download=domainblocklist \
	s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt \
	s3.amazonaws.com/lists.disconnect.me/simple_ad.txt \
	hosts-file.net/ad_servers.txt

LOCAL_ABP_FORMATTED_LIST :=  $(addprefix $(LISTS_ROOT)/abp/srcs/, $(ABP_FORMATTED_LIST_URLS))

WHITELIST_FILES := $(wildcard $(LISTS_ROOT)/whitelist/*)

default: blocked_domains.txt

.PHONY: install
install:
	pipenv --three --python=`which python3`
	pipenv install

whitelist_domains.txt: $(WHITELIST_FILES)
	echo 'whitelist files: $(WHITELIST_FILES)'
	cat $< \
		| LC_COLLATE=C sort \
		| uniq > $@


$(LISTS_ROOT)/abp/srcs/%:
	mkdir -p $(dir $@)
	wget -O '$@' https://$*


blocked_domains.txt: $(LOCAL_ABP_FORMATTED_LIST) whitelist_domains.txt
	cat $(addsuffix ', $(addprefix ', $(LOCAL_ABP_FORMATTED_LIST))) \
	    | egrep  '^\|\|[^/]+\^$$' \
	    | sed 's/^||//' \
	    | sed 's/\^//' \
	    | LC_COLLATE=C sort \
	    | uniq \
	    | fgrep -v -x -f whitelist_domains.txt > $@
	wc -l $@


blocked_3p_domains.txt: $(LOCAL_ABP_FORMATTED_LIST) whitelist_domains.txt
	cat $(addsuffix ', $(addprefix ', $(LOCAL_ABP_FORMATTED_LIST))) \
	    | egrep  '^\|\|[^/]+\^\$$third-party$$' \
	    | sed 's/^||//' \
	    | sed 's/\^\$$third-party$$//' \
	    | LC_COLLATE=C sort \
	    | uniq \
	    | fgrep -v -x -f whitelist_domains.txt > $@
	wc -l $@

blocked_domains_little_snitch_rule.json: blocked_domains.txt
	cat $< | ./domain_list_to_ls_rules.py > $@

blocked_3p_domains_little_snitch_rule.json: blocked_3p_domains.txt
	cat $< | ./domain_list_to_ls_rules.py > $@	

.PHONY: all
all: blocked_domains_little_snitch_rule.json blocked_3p_domains_little_snitch_rule.json

.PHONY: stats
stats:
	@echo '$(shell wc -l blocked_domains.txt) blocked domains'

.PHONY: clean-lists
clean-lists:
	rm -rf $(LISTS_ROOT)/abp/srcs/*
	rm -f whitelist_domains blocked_domains.txt blocked_3p_domains.txt blocked_3p_domains_little_snitch_rule.json blocked_domains_little_snitch_rule.json
