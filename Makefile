APP =		HandyNotes-Achievements
TOC =		HandyNotes_Achievements
VERSION =	$(shell sed -ne 's/^\#\# Version: //p' $(TOC))
FILES = 	HandyNotes_Achievements/HandyNotes_Achievements* \
		HandyNotes_Achievements/Libs/* \
		HandyNotes_Achievements/Locales/*


all:
	(cd Libs/AchievementLocations-1.0 && make)

release: chmod
	-rm ../$(APP)-$(VERSION).zip
	find . -name .DS_Store -exec rm {} \;
	(cd .. && zip -r $(APP)-$(VERSION).zip $(FILES))

chmod:
	find . -type f -exec chmod a-x {} \;
	find Libs/AchievementLocations-1.0/node_modules/.bin \! -type d -exec chmod a+x {} \;
	find . -exec chmod og-w,a+r {} \;

#tag:
#	git tag -a v$(VERSION) -m "tag"
#	git push --tags

wowace_clone:
	git remote add wowace git@git.curseforge.net:wow/handynotes_achievements/mainline.git

push:
	git push wowace master
