# meetup-emails
Get emails of users part of a meetup group

## How to use : 
For some meetup groups that require you to fillup a form before you can be added as member, this script allows you to fetch the information provided by the members of that group.

The script is particularly useful, when some groups require email id as part of that form.

## Running the script

To run this script, you will need your meetup id, your membership timestamp, and another string from meetup.

You can get these quite easily.
* Go to the meetup groups members page (Example : This is [an example link]( http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/)
* Click on any member [Example link](http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/30428102/)
* Copy that request as curl (using browser debugger tools)
* In the above curl look for a cookie name MEETUP_MEMBER
  this cookie's value will contain parameters like : `id=<your meetup id>` and 
  `timestamp=<your group register timestamp>`
  and the string `s=<some string>`
