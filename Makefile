PACKAGE ?=	HandyNotes_Achievements
TOC ?=		HandyNotes_Achievements.toc
ARCHIVE ?=	HandyNotes-Achievements.zip
BUILD ?=	.build
CURSEFORGE_PROJECT_ID ?= 99064
CURSEFORGE_API_TOKEN ?= sekrit

VERSION ?=	$(shell sed -ne "s/^\#\# Version: //p" $(TOC) | tr -d "\r\n")

GAME_VERSION ?=	$(shell sed -ne "/^\#\# Interface/{s/^\#\# Interface: \([0-9]*\)\([0-9][0-9]\)\([0-9][0-9]\)/\1.\2.\3/;s/\.0/./gp;q;}" $(TOC) | tr -d "\r\n")

GAME_VERSION_ID ?= $(shell curl -s -H "x-api-token: $(CURSEFORGE_API_TOKEN)" https://wow.curseforge.com/api/game/versions | jq "map(select(.name==\"$(GAME_VERSION)\")) | .[0] | .id" | tr -d "\n\r")

DISPLAY_NAME ?=	v$(VERSION)
RELEASE_TYPE ?=	alpha
CHANGELOG ?= CHANGELOG.txt
CHANGELOG_TYPE ?= markdown

all:
	(cd Libs/AchievementLocations-1.0 && make)

update:
	git submodule update --remote --merge

SOURCES ?= $(TOC) $(CHANGELOG) $(shell sed -e '/^\#/d' $(TOC))

archive: $(BUILD)/$(ARCHIVE)

$(BUILD)/$(ARCHIVE): $(SOURCES)
	echo $(SOURCES) | tr " \n\r" "\0" | cpio -0pdvl --quiet $(BUILD)/$(PACKAGE)
	( cd $(BUILD) && zip -r $(ARCHIVE) $(PACKAGE) )

upload_curseforge: $(BUILD)/$(ARCHIVE) $(CHANGELOG)
	jq -n --arg dn $(DISPLAY_NAME) \
	      --arg gvi $(GAME_VERSION_ID) \
	      --arg rt $(RELEASE_TYPE) \
	      --arg clt $(CHANGELOG_TYPE) \
	      --rawfile cl $(CHANGELOG) \
	'{displayName:$$dn, gameVersions:[$$gvi], releaseType:$$rt, changelogType:$$clt, changelog:$$cl}' \
	| curl -s -H "x-api-token: $(CURSEFORGE_API_TOKEN)" \
	       -F "metadata=<-" \
	       -F file=@$(BUILD)/$(ARCHIVE) \
	       https://wow.curseforge.com/api/projects/$(CURSEFORGE_PROJECT_ID)/upload-file

clean:
	-rm -rf $(BUILD)

.PHONY: all collect archive upload_curseforge clean
