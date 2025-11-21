# MUTT-Mail-Client-Open-HTML-In-Google-Chrome
Use this macro to open HTML emails from the mutt mail client in Google Chrome browser

Install the script in $HOME/scripts directory and add the following entry in your muttrc file

macro index,pager \ch "<pipe-message>~/scripts/view_muttt_html.sh<enter>" "View HTML message in browser"

Enjoy!
